-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the decoder_shadow decodes instructions which are needed but not part of user-available instruction set (e.g. push).
-- it is fully combinatoric.
entity decoder_shadow is
	port(
		-- input signals from decoder finite state machine
		input  : in  fsm_decshd;
		-- output signals to control path (or decoder mux)
		output : out dec_cp
	);
end entity decoder_shadow;

architecture RTL of decoder_shadow is
begin

	-- decode instruction
	decode : process(input.instruction) is
	begin
		-- set defaults to prevent taking values from previous operations
		output.s1        <= get_default_dec_cp_s1;
		output.s2        <= get_default_dec_cp_s2;
		output.s3        <= get_default_dec_cp_s3;
		output.hardfault <= '0';

		-- set instruction specific signals
		case input.instruction(31 downto 28) is
			when op_shd_push =>         -- push instruction
				-- write to mem
				output.s1.register_read_number_b <= reg_number(input.instruction(3 downto 0));
				output.s3.dmem_write_en          <= '1';
				output.s3.dmem_write_size        <= size_word;
				output.s3.dmem_write_data_select <= sel_register_value;
				-- decrement SP
				output.s1.register_read_number_a <= sp_num;
				output.s2.alu_mode               <= alu_sub;
				output.s2.alu_input_data_select  <= sel_imm;
				output.s2.immediate              <= to_signed(4, 8);
				output.s3.register_write_number  <= sp_num;
				output.s3.register_write_enable  <= '1';
			when op_shd_setsr =>        -- set SR instruction
				output.s3.register_write_data_select <= sel_immediate;
				output.s3.register_write_number      <= sr_num;
				output.s3.register_write_size        <= size_byte;
				output.s3.register_write_enable      <= '1';
				output.s2.immediate                  <= signed(input.instruction(7 downto 0));
			when op_shd_reset =>        -- reset instruction
				-- PC = zero
				output.s2.pc_summand_select <= sel_immediate;
				output.s2.pc_mode_select    <= sel_absolute;
				output.s2.pc_condition      <= sel_unconditional;
				output.s2.immediate         <= (others => '0');

			-- synthesis translate_off
			when "UUUU" =>
				null;                   -- ignore startup
			-- synthesis translate_on

			when others =>
				-- unknown operation, throw hardfault
				output.hardfault <= '1';
				
				-- synthesis translate_off
				assert false report "unknown shadow operation not implemented" severity error;
				-- synthesis translate_on
		end case;
	end process decode;

end architecture RTL;
