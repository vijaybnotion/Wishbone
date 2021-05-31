-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use work.lt16x32_internal.all;

-- the decoder_pre checks the new instruction for basic data, which is needed in the finite state machine as input.
-- it is fully combinatoric
entity decoder_pre is
	port(
		-- signals from instruction memory
		input  : in  imem_dec;
		-- signals to decoder finite state machine
		output : out pre_fsm
	);
end entity decoder_pre;

architecture RTL of decoder_pre is
begin
	-- decodes instruction memory input and outputs signals to finite state machine
	decode : process(input) is
		-- fetched instruction, 16 bit instructions stored in (15 downto 0) bits
		variable instruction       : std_logic_vector(31 downto 0);
		-- width of fetched instruction
		variable instruction_width : instruction_width_type;
		-- instruction mode, temporary storage for clean logic/output seperation
		variable instruction_mode  : instruction_mode_type;

	begin
		-- needed to avoid latch generation for upper half word
		instruction := (others => '0');

		if (input.ready = '1') then
			-- instruction memory is ready

			-- get relevant instruction from instruction word and extract instruction width
			case input.instruction_halfword_select is
				when '0' =>             -- 32bit aligned, might be 32bit instruction 
					if (input.read_data(31 downto 28) = "1111") then
						-- is 32 bit instruction
						instruction_width        := sel_32bit;
						instruction(31 downto 0) := std_logic_vector(input.read_data(31 downto 0));
					else
						-- is 16 bit instruction
						instruction_width        := sel_16bit;
						instruction(15 downto 0) := std_logic_vector(input.read_data(31 downto 16));
					end if;

				when '1' =>             -- lower 16bit, always 16 bit instruction 
					instruction_width        := sel_16bit;
					instruction(15 downto 0) := std_logic_vector(input.read_data(15 downto 0));

				when others =>
					instruction_width        := sel_16bit;
					instruction(15 downto 0) := op_or & "0000" & "0000" & "0000";
					assert false report "instruction halfword select must be either 0 or 1" severity warning;
			end case;

			-- check for special, multicycle or normal instructions
			if (instruction_width = sel_16bit) then
				-- 16 bit instructions

				if (instruction(15 downto 10) = op_bct & op_bct_call) then
					-- instruction is call
					instruction_mode := sel_call;
					
				elsif (instruction(15 downto 10) = op_bct & op_bct_trap) then
					-- instruction is trap
					instruction_mode := sel_trap;
					
				elsif (instruction(15 downto 9) = op_bct & op_bct_reti) then
					-- instruction is reti
					instruction_mode := sel_reti;
					
				elsif (instruction(15 downto 10) = op_bct & op_bct_branch) then
					-- instruction is branch
					instruction_mode := sel_branch;
					
				elsif (instruction(15 downto 10) = op_bct & op_bct_table) then
					-- instruction is branch to table
					instruction_mode := sel_branch;
				else
					
					-- no special instruction
					instruction_mode := sel_normal16;
				end if;

			else
				-- 32bit instructions
				instruction_mode := sel_normal32;
			end if;
		else
			-- imem not ready
			instruction(15 downto 0) := nop16;
			instruction_mode         := sel_stall;
		end if;

		-- output
		output.instruction <= instruction;
		output.mode        <= instruction_mode;
	end process decode;

end architecture RTL;
