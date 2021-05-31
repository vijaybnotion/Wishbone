-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the controlpath mostly covers the pipelining of control signals, but also includes some "glue"-logic
entity controlpath is
	port(
		-- clock signal
		clk       : in  std_logic;
		-- reset signal, active high, synchronous
		rst       : in  std_logic;
		-- stall signal, active high
		stall     : in  std_logic;

		-- signals from decoder
		in_dec    : in  dec_cp;
		-- signals to decoder
		out_dec   : out cp_dec;

		-- signals to datapath
		out_dp    : out cp_dp;

		-- signals to PC counter
		out_pc    : out cp_pc;

		-- signals to data memory
		out_dmem  : out cp_dmem;

		-- signals from datapath
		in_dp     : in  dp_cp;

		-- hardfault, active high
		hardfault : out std_logic
	);
end entity controlpath;

architecture RTL of controlpath is

	-- pipelined signals
	-- decoder information for dp-stage 2 in stage 2
	signal in_dec_2_s2 : dec_cp_s2;
	-- decoder information for dp-stage 3 in stage 2
	signal in_dec_3_s2 : dec_cp_s3;
	-- decoder information for dp-stage 3 in stage 3
	signal in_dec_3_s3 : dec_cp_s3;

begin
	-- forward internal signals to ports
	hardfault <= in_dec.hardfault;

	out_pc.instruction_width <= in_dec.s1.instruction_width;

	out_dp.s1.register_read_number_a <= in_dec.s1.register_read_number_a;
	out_dp.s1.register_read_number_b <= in_dec.s1.register_read_number_b;

	out_dp.s2.alu_input_data_select   <= in_dec_2_s2.alu_input_data_select;
	out_dp.s2.alu_mode                <= in_dec_2_s2.alu_mode;
	out_dp.s2.immediate               <= in_dec_2_s2.immediate;
	out_dp.s2.memory_read_addr_select <= in_dec_2_s2.dmem_read_addr_select;

	out_dmem.read_en   <= in_dec_2_s2.dmem_read_en;
	out_dmem.read_size <= in_dec_2_s2.dmem_read_size;

	out_dmem.write_en   <= in_dec_3_s3.dmem_write_en;
	out_dmem.write_size <= in_dec_3_s3.dmem_write_size;

	out_dp.s3.ovfflag_write_enable       <= in_dec_3_s3.ovfflag_write_enable;
	out_dp.s3.memory_write_data_select   <= in_dec_3_s3.dmem_write_data_select;
	out_dp.s3.register_write_data_select <= in_dec_3_s3.register_write_data_select;
	out_dp.s3.register_write_enable      <= in_dec_3_s3.register_write_enable;
	out_dp.s3.register_write_number      <= in_dec_3_s3.register_write_number;
	out_dp.s3.register_write_size        <= in_dec_3_s3.register_write_size;
	out_dp.s3.tflag_write_data_select    <= in_dec_3_s3.tflag_write_data_select;
	out_dp.s3.tflag_write_enable         <= in_dec_3_s3.tflag_write_enable;

	-- pipeline register stage 1 -> 2
	pipeline_s1_s2 : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				in_dec_2_s2 <= get_default_dec_cp_s2;
				in_dec_3_s2 <= get_default_dec_cp_s3;
			elsif (stall = '0') then
				in_dec_2_s2 <= in_dec.s2;
				in_dec_3_s2 <= in_dec.s3;
			end if;
		end if;
	end process pipeline_s1_s2;

	-- pipeline register stage 2 -> 3
	pipeline_s2_s3 : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				in_dec_3_s3 <= get_default_dec_cp_s3;
			elsif (stall = '0') then
				in_dec_3_s3 <= in_dec_3_s2;
			end if;
		end if;
	end process pipeline_s2_s3;

	-- PC signal combinatorics and condition holds flag for decoder
	pc_comb : process(in_dec_2_s2.pc_summand_select, in_dec_2_s2.pc_mode_select, in_dec_2_s2.pc_condition, in_dp.s2.tflag) is
	begin
		case in_dec_2_s2.pc_condition is
			when sel_unconditional =>
				-- without condition, always use proposed pc options
				out_pc.summand_select   <= in_dec_2_s2.pc_summand_select;
				out_pc.mode_select      <= in_dec_2_s2.pc_mode_select;
				out_dec.condition_holds <= '1';
			when sel_true =>
				-- with condition = true
				if (in_dp.s2.tflag = '1') then
					-- if condition is true (as needed), use proposed pc options
					out_pc.summand_select   <= in_dec_2_s2.pc_summand_select;
					out_pc.mode_select      <= in_dec_2_s2.pc_mode_select;
					out_dec.condition_holds <= '1';
				else
					-- if condition is false (opposed to what is needed) resume normal pc operation
					out_pc.summand_select   <= sel_run;
					out_pc.mode_select      <= sel_relative;
					out_dec.condition_holds <= '0';
				end if;
		end case;
	end process pc_comb;

end architecture RTL;
