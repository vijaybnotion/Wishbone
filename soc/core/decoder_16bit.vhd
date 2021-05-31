-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the decoder_16bit decodes all 16bit instructions and is fully combinatoric
entity decoder_16bit is
	port(
		-- input signals from decoder_fsm
		input  : in  fsm_dec16;
		-- output signals to controlpath (or decoder mux)
		output : out dec_cp
	);
end entity decoder_16bit;

architecture RTL of decoder_16bit is
begin

	-- decode instruction	
	decode : process(input) is
	begin
		-- set defaults to prevent taking values from previous operations
		output.s1        <= get_default_dec_cp_s1;
		output.s2        <= get_default_dec_cp_s2;
		output.s3        <= get_default_dec_cp_s3;
		output.hardfault <= '0';

		-- directly forwarded instruction parts
		output.s1.register_read_number_a <= reg_number(input.instruction(7 downto 4));
		output.s1.register_read_number_b <= reg_number(input.instruction(3 downto 0));
		output.s3.register_write_number  <= reg_number(input.instruction(11 downto 8));

		-- set opcode specific signals
		case input.instruction(15 downto 12) is
			when op_add =>              -- add instruction
				output.s2.alu_mode              <= alu_add;
				output.s3.register_write_enable <= '1';
				output.s3.ovfflag_write_enable  <= '1';
			when op_sub =>              -- subtract instruction
				output.s2.alu_mode              <= alu_sub;
				output.s3.register_write_enable <= '1';
				output.s3.ovfflag_write_enable  <= '1';
			when op_or =>               -- bitwise or instruction
				output.s2.alu_mode              <= alu_or;
				output.s3.register_write_enable <= '1';
			when op_and =>              -- bitwise and instruction
				output.s2.alu_mode              <= alu_and;
				output.s3.register_write_enable <= '1';
			when op_xor =>              -- bitwise xor instruction
				output.s2.alu_mode              <= alu_xor;
				output.s3.register_write_enable <= '1';
			when op_lsh =>              -- logic left shift instruction
				output.s2.alu_mode              <= alu_lsh;
				output.s2.alu_input_data_select <= sel_imm;
				output.s2.immediate             <= signed("0000" & input.instruction(3 downto 0));
				output.s3.register_write_enable <= '1';
			when op_rsh =>              -- logic right shift instruction
				output.s2.alu_mode              <= alu_rsh;
				output.s2.alu_input_data_select <= sel_imm;
				output.s2.immediate             <= signed("0000" & input.instruction(3 downto 0));
				output.s3.register_write_enable <= '1';
			when op_addi =>             -- add immediate instruction
				output.s1.register_read_number_a <= reg_number(input.instruction(11 downto 8));
				output.s2.alu_mode               <= alu_add;
				output.s2.alu_input_data_select  <= sel_imm;
				output.s2.immediate              <= signed(input.instruction(7 downto 0));
				output.s3.register_write_enable  <= '1';
				output.s3.ovfflag_write_enable   <= '1';
			when op_cmp =>              -- compare instruction
				output.s3.tflag_write_enable <= '1';
				case input.instruction(11 downto 8) is
					when op_cmp_eq =>   -- compare for equal
						output.s2.alu_mode <= alu_cmp_eq;
					when op_cmp_neq =>  -- compare for not equal
						output.s2.alu_mode <= alu_cmp_neq;
					when op_cmp_ge =>   -- compare for greater than or equal
						output.s2.alu_mode <= alu_cmp_ge;
					when op_cmp_ll =>   -- compare for less than
						output.s2.alu_mode <= alu_cmp_ll;
					when op_cmp_gg =>   -- compare for greater than
						output.s2.alu_mode <= alu_cmp_gg;
					when op_cmp_le =>   -- compare for less than or equal
						output.s2.alu_mode <= alu_cmp_le;
					when op_cmp_true => -- set truth flag
						output.s2.alu_mode <= alu_cmp_true;
					when op_cmp_false => -- reset truth flag
						output.s2.alu_mode <= alu_cmp_false;
					when others =>
						-- unknown compare mode, throw hardfault
						output.hardfault <= '1';

						-- synthesis translate_off
						assert false report "cmp mode not supported" severity error;
						-- synthesis translate_on						
				end case;
			when op_bct =>              -- branch, call, trap, reti instruction
				if (input.instruction(11 downto 9) = op_bct_reti) then
					-- it's reti instruction, which is not allowed here (as it is handled earlier in decoder)
					output.hardfault <= '1';

					-- synthesis translate_off
					assert false report "reti operation not allowed in 16 bit decoder stage" severity error;
					-- synthesis translate_on

				else                    -- table / branch / (call) / trap					
					-- decode source bit
					if (input.instruction(9) = '0') then -- bct to immediate
						if (input.instruction(11 downto 10) = op_bct_trap) then
							-- trap is absolute to immediate
							output.s2.pc_mode_select <= sel_absolute;
						else
							-- all other branches to immediate are relative
							output.s2.pc_mode_select <= sel_relative;
						end if;
						-- immediate parameters
						output.s2.pc_summand_select <= sel_immediate;
						output.s2.immediate         <= signed(input.instruction(7 downto 0));
						
					else                -- bct to register
						if (input.instruction(11 downto 10) = op_bct_table) then
							-- branch to table is pc relative
							output.s2.pc_mode_select <= sel_relative;
						else
							-- all other branches to register are absolute
							output.s2.pc_mode_select <= sel_absolute;
						end if;
						-- register parameters
						output.s2.pc_summand_select <= sel_register_a;
					end if;

					-- decode conditional bit
					if (input.instruction(8) = '1') then
						output.s2.pc_condition <= sel_true;
					else
						output.s2.pc_condition <= sel_unconditional;
					end if;
				end if;

			when op_mem =>              -- memory instructions
				case input.instruction(11 downto 8) is
					when op_mem_ld08 => -- load byte
						output.s2.dmem_read_addr_select      <= sel_register_b;
						output.s2.dmem_read_en               <= '1';
						output.s2.dmem_read_size             <= size_byte;
						output.s3.register_write_data_select <= sel_memory;
						output.s3.register_write_enable      <= '1';
						output.s3.register_write_size        <= size_byte;
						output.s3.register_write_number      <= reg_number(input.instruction(7 downto 4));
					when op_mem_ld16 => -- load halfword
						output.s2.dmem_read_addr_select      <= sel_register_b;
						output.s2.dmem_read_en               <= '1';
						output.s2.dmem_read_size             <= size_halfword;
						output.s3.register_write_data_select <= sel_memory;
						output.s3.register_write_enable      <= '1';
						output.s3.register_write_size        <= size_halfword;
						output.s3.register_write_number      <= reg_number(input.instruction(7 downto 4));
					when op_mem_ld32 => -- load word
						output.s2.dmem_read_addr_select      <= sel_register_b;
						output.s2.dmem_read_en               <= '1';
						output.s2.dmem_read_size             <= size_word;
						output.s3.register_write_data_select <= sel_memory;
						output.s3.register_write_enable      <= '1';
						output.s3.register_write_size        <= size_word;
						output.s3.register_write_number      <= reg_number(input.instruction(7 downto 4));

					when op_mem_st08 => -- store byte
						output.s3.dmem_write_en          <= '1';
						output.s3.dmem_write_size        <= size_byte;
						output.s3.dmem_write_data_select <= sel_register_value;
					when op_mem_st16 => -- store halfword
						output.s3.dmem_write_en          <= '1';
						output.s3.dmem_write_size        <= size_halfword;
						output.s3.dmem_write_data_select <= sel_register_value;
					when op_mem_st32 => -- store word
						output.s3.dmem_write_en          <= '1';
						output.s3.dmem_write_size        <= size_word;
						output.s3.dmem_write_data_select <= sel_register_value;

					when others =>
						-- unknown memory mode, throw hardfault
						output.hardfault <= '1';

						-- synthesis translate_off
						assert false report "memory mode not supported" severity error;
						-- synthesis translate_on
				end case;

			when op_ldr =>              -- load pc relative (full register width)
				output.s2.immediate                  <= signed(input.instruction(7 downto 0));
				output.s2.dmem_read_addr_select      <= sel_ldr_address;
				output.s2.dmem_read_en               <= '1';
				output.s2.dmem_read_size             <= reg_size;
				output.s3.register_write_data_select <= sel_memory;
				output.s3.register_write_enable      <= '1';
				output.s3.register_write_size        <= reg_size;

			when op_tst =>              -- test and set
				output.s2.dmem_read_addr_select      <= sel_register_a;
				output.s2.dmem_read_en               <= '1';
				output.s2.dmem_read_size             <= size_byte;
				output.s3.register_write_data_select <= sel_memory;
				output.s3.register_write_enable      <= '1';
				output.s3.register_write_size        <= size_byte;
				output.s3.dmem_write_en              <= '1';
				output.s3.dmem_write_size            <= size_byte;
				output.s3.dmem_write_data_select     <= sel_dmemORx80;
				output.s3.tflag_write_data_select    <= sel_dmem7;
				output.s3.tflag_write_enable         <= '1';

			-- synthesis translate_off
			when "UUUU" =>
				null;                   -- ignore startup
			when "XXXX" =>
				null;					-- ignore IM delay
			-- synthesis translate_on

			when others =>
				-- unkwown operation, throw hardfault
				output.hardfault <= '1';
				-- synthesis translate_off
				assert false report "unknown operation not implemented" severity error;
		-- synthesis translate_on

		end case;
	end process decode;

end architecture RTL;
