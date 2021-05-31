-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;

-- the decoder_fsm is the finite state machine handling multi-cycle operation and interrupt acknowledgement
entity decoder_fsm is
	port(
		-- clock signal
		clk      : in  std_logic;
		-- reset signal, active high, synchronous
		rst      : in  std_logic;
		-- stall signal, active high
		stall    : in  std_logic;

		-- signals from pre-decoder
		in_pre   : in  pre_fsm;
		-- signals from control path
		in_cp    : in  cp_dec;
		-- signals from datapath
		in_dp    : in  dp_dec;

		-- signals to 16bit decoder
		out_16   : out fsm_dec16;
		-- signals to 32bit decoder
		out_32   : out fsm_dec32;
		-- signals to shadow decoder
		out_shd  : out fsm_decshd;
		-- signals to decoder mux
		out_mux  : out fsm_decmux;

		-- signals to pc counter
		out_pc   : out dec_pc;
		-- signals to instruction memory
		out_imem : out dec_imem;

		-- signals from interrupt controller
		in_irq   : in  irq_dec;
		-- signals to interrupt controller
		out_irq  : out dec_irq
	);
end entity decoder_fsm;

architecture RTL of decoder_fsm is
	-- possible states of fsm
	type state_type is (normal, reset, reset2, copyPCtoLR, branchdelay, irq_decSP1, irq_pushSR, irq_pushLR, irq_setSR, irq_setPC, reti_popLR, reti_incSP1, reti_popSR, reti_incSP2); --add  irq_decSP2 for 4 instruction irq stack solution 
	-- current state
	signal state : state_type := normal;

	-- temporary storage for multicycle operations
	signal multicycleinstruction : std_logic_vector(31 downto 0);
begin

	-- the finite state machine is modelled as mealy-machine 

	-- generate output (combinatoric part)
	output : process(in_pre, state, multicycleinstruction, in_cp.condition_holds) is
		variable state_variable : state_type;
	begin
		-- standard output
		out_16.instruction                <= nop16;
		out_32.instruction                <= in_pre.instruction;
		out_shd.instruction(31 downto 28) <= op_shd_push;
		out_shd.instruction(27 downto 0)  <= (others => '0');

		out_mux.mode <= sel_ir16;
		out_pc.stall <= '0';

		out_imem.en <= '1';

		out_irq.ack      <= '0';
		out_irq.trap_req <= '0';
		out_irq.trap_num <= (others => '0');

		-- copy state to variable for further processing
		state_variable := state;

		-- don't insert nop in branch delay if no branch taken
		-- happens only, if execute_branch_delay_slot is false
		if ((state = branchdelay) and (in_cp.condition_holds = '0')) then
			state_variable := normal;
		end if;
		
		-- don't write LR if no call happens
		if ((state = copyPCtoLR) and (in_cp.condition_holds = '0')) then
			state_variable := normal;
		end if;

		-- generate state dependend output
		case state_variable is
			when reset =>               -- first cycle in reset
				out_pc.stall                      <= '1';
				out_shd.instruction(31 downto 28) <= op_shd_reset;
				out_mux.mode                      <= sel_irshadow;

			when reset2 =>              -- second cycle in reset
				out_pc.stall       <= '0';
				out_16.instruction <= nop16;
				out_mux.mode       <= sel_ir16;

			when normal =>              -- standard mode
				out_pc.stall <= '0';

				case in_pre.mode is     -- check decoder_pre mode output
					when sel_normal16 => -- normal 16 bit instruction
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= in_pre.instruction(15 downto 0);
					when sel_normal32 => -- normal 32 bit instruction
						out_mux.mode       <= sel_ir32;
						out_32.instruction <= in_pre.instruction;
					when sel_branch =>  -- branch instruction
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= in_pre.instruction(15 downto 0);
					when sel_call =>    -- call instruction
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= op_bct & "01" & in_pre.instruction(9 downto 0);
						--out_imem.en <= '0'; -- imem must be read in case that condition does not hold and next instruction should be executed
					when sel_trap =>    -- trap instruction
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= nop16;
						out_irq.trap_num   <= unsigned(in_pre.instruction(irq_num_width - 1 downto 0));
						out_irq.trap_req   <= '1';
					when sel_reti =>    -- reti instruction
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= op_bct & "0110" & std_logic_vector(lr_num) & "0000";
						out_imem.en        <= '0';
					when sel_stall =>   -- stall (i.e. imem not ready)
						out_mux.mode       <= sel_ir16;
						out_16.instruction <= in_pre.instruction(15 downto 0);
						out_pc.stall       <= '1';
				end case;

			when copyPCtoLR =>             -- LR = PC, used in call and irq
				-- only if condition true, else normal instruction (this check is done in state transition)
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_or & std_logic_vector(lr_num) & std_logic_vector(pc_num) & std_logic_vector(pc_num);
				out_imem.en        <= '1';

			when branchdelay =>         -- insert NOP to branch delay slot if enabled in configuration
				out_pc.stall <= '0';
				out_mux.mode <= sel_ir16;
				out_imem.en  <= '1';

			--when irq_pushLR =>              -- irq: push LR
			--	out_pc.stall                      <= '1';
			--	out_mux.mode                      <= sel_irshadow;
			--	out_shd.instruction(31 downto 28) <= op_shd_push;
			--	out_shd.instruction(3 downto 0)   <= std_logic_vector(lr_num);
			--	out_imem.en                       <= '0';
			when irq_pushLR =>  
                                out_pc.stall       <= '1';
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_mem & op_mem_st32 & std_logic_vector(sp_num) & std_logic_vector(lr_num);
				out_imem.en        <= '1';

			when irq_setSR =>              -- irq: push SR and set new SR value
				out_pc.stall                                       <= '1';
				out_mux.mode                                       <= sel_irshadow;
				out_shd.instruction(31 downto 28)                  <= op_shd_setsr;
				-- new runtime priority, other SR flags all zero
				out_shd.instruction(7 downto (8 - irq_prio_width)) <= multicycleinstruction(16 + irq_prio_width - 1 downto 16);
				out_imem.en                                        <= '0';

			when irq_setPC =>            -- irq: branch to irq address
				out_pc.stall       <= '1';
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_bct & "11" & multicycleinstruction(9 downto 0);
				out_imem.en        <= '0';

			when reti_popLR =>             -- reti: load LR from stack
				out_pc.stall       <= '0';  --former 1
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_mem & op_mem_ld32 & std_logic_vector(lr_num) & std_logic_vector(sp_num);
				out_imem.en        <= '0';

			when reti_popSR =>             -- reti: load SR from stack
				out_pc.stall       <= '1';
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_mem & op_mem_ld32 & std_logic_vector(sr_num) & std_logic_vector(sp_num);
				out_imem.en        <= '1';

			when reti_incSP1 =>          -- reti: increment SP
                                out_pc.stall       <= '1';
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_addi & std_logic_vector(sp_num) & std_logic_vector(to_signed(4, 8));
				out_imem.en        <= '0';

			when reti_incSP2 =>          -- reti increment SP
				out_pc.stall       <= '1';
				out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_addi & std_logic_vector(sp_num) & std_logic_vector(to_signed(4, 8));
				out_imem.en        <= '0';

			when irq_pushSR =>             -- irq: push SR (store and decrement SP afterwards)
				out_mux.mode                      <= sel_irshadow;
				out_shd.instruction(31 downto 28) <= op_shd_push;
				out_shd.instruction(3 downto 0)   <= std_logic_vector(sr_num);
				out_irq.ack                       <= '1';
				out_pc.stall                      <= '1';
			--when irq_pushSR =>
                        --      out_pc.stall       <= '1';
			--	out_mux.mode       <= sel_ir16;
			--	out_16.instruction <= op_mem & op_mem_st32 & std_logic_vector(sp_num) & std_logic_vector(sr_num);
			--	out_imem.en        <= '1';
			--	out_irq.ack         <= '1';
                        when irq_decSP1 =>
                                out_pc.stall       <= '1';
                                out_mux.mode       <= sel_ir16;
				out_16.instruction <= op_addi & std_logic_vector(sp_num) & std_logic_vector(to_signed(-4, 8));
				out_imem.en        <= '0';
                        --when irq_decSP2 =>
                         --       out_pc.stall       <= '1';
                           --     out_mux.mode       <= sel_ir16;
				--out_16.instruction <= op_addi & std_logic_vector(sp_num) & std_logic_vector(to_signed(-4, 8));
				--out_imem.en        <= '0';
                        
		end case;

	end process output;

	-- state transition (clocked part)
	state_transition : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				state <= reset;
			elsif (stall = '0') then
				state <= state;         -- in default: keep state

				-- check for interrupt request
				if (
					-- not near branch and not in multicycle operation
					(in_pre.mode /= sel_branch) and (state = normal)
					-- interrupt request
					and (in_irq.req = '1')
					-- priority higher than runtime priority or non maskable interrupt
					and ((unsigned(in_irq.priority) > in_dp.runtime_priority) or (in_irq.nmi = '1'))
				) then
					-- in normal mode and irq request
					--state <= irq_pushSR;
					state <= irq_decSP1;

					multicycleinstruction                                    <= (others => '0');
					multicycleinstruction(16 + irq_prio_width - 1 downto 16) <= std_logic_vector(in_irq.priority);
					multicycleinstruction(irq_num_width downto 0)            <= std_logic_vector(in_irq.num) & "0";

					-- synthesis translate_off
					assert false report "current runtime priority is " & integer'image(to_integer(in_dp.runtime_priority)) & ". IRQ priority is " & integer'image(to_integer(unsigned(in_irq.priority))) & "." severity note;
					assert false report "handle irq request #" & integer'image(to_integer(unsigned(in_irq.num))) severity note;
					-- synthesis translate_on

				else
					-- no irq request valid

					-- for state transition diagram see documentation
					case state is
						when normal =>
							case in_pre.mode is
								when sel_normal16 =>
									state <= normal;
								when sel_normal32 =>
									state <= normal;
								when sel_call =>
									state <= copyPCtoLR;
								when sel_branch =>
									if (execute_branch_delay_slot) then
										state <= normal;
									else
										state <= branchdelay;
									end if;
								when sel_trap =>
									state <= normal;
								when sel_reti =>
									--state <= reti_incSP1;
									state <= reti_popLR;
								when sel_stall =>
									state <= normal;
							end case;
						when copyPCtoLR =>
							state <= normal;
						when branchdelay =>
							state <= normal;
						--! group by multicycle opertation/pseudo-instruction -TF
						-- i.e. IRQ entry (multicycle)
						when irq_decSP1 =>
                                                        state <= irq_pushSR;
						when irq_pushSR =>
							--state <= irq_decSP2;
							state <= irq_pushLR;
                                                --when irq_decSP2 =>
                                                     --   state <= irq_pushLR;
						when irq_pushLR =>
							state <= irq_setSR;
						when irq_setSR =>
							state <= irq_setPC;
						when irq_setPC =>
							state <= copyPCtoLR;
						when reti_popLR =>
							state <= reti_incSP1;
						when reti_incSP1 =>
							state <= reti_popSR;
						when reti_popSR =>
							state <= reti_incSP2;
                                                when reti_incSP2 =>
                                                    state <= normal;
						when reset =>
							state <= reset2;
						when reset2 =>
							state <= normal;
					end case;
				end if;
			end if;
		end if;
	end process state_transition;

end architecture RTL;
