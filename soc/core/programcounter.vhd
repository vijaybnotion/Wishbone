-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the pc counter counts the current programm address up, but also offers
-- various different run- and set-modes
entity programcounter is
	port(
		-- clock signal
		clk      : in  std_logic;
		-- reset signal, active high, synchronous
		rst      : in  std_logic;
		-- stall signal, active high
		stall    : in  std_logic;

		-- signals from control path
		in_cp    : in  cp_pc;
		-- signals from data path
		in_dp    : in  dp_pc;
		-- signals from decoder
		in_dec   : in  dec_pc;

		-- signals to datapath
		out_dp   : out pc_dp;
		-- signals to instruction memory
		out_imem : out pc_imem
	);

	-- internal width of calculation, last pc bit is always zero and is hence not needed in the calculations here
	constant internal_width : natural := pc_width - 1;
end entity programcounter;

architecture RTL of programcounter is
	-- increment for normal operation (16 / 32 bits)
	signal run_increment : signed(internal_width - 1 downto 0);
	-- second input of the internal adder
	signal adder_input_b : signed(internal_width - 1 downto 0);
	-- result of the internal adder
	signal adder_result  : unsigned(internal_width - 1 downto 0);

	-- new pc value (used in two ports)
	signal pc_value     : unsigned(internal_width - 1 downto 0);
	-- old pc value
	signal pc_value_old : unsigned(internal_width - 1 downto 0);
begin

	-- simple forwarding
	out_dp.value   <= pc_value & '0';   -- always half-word aligned
	out_imem.value <= pc_value & '0';   -- always half-word aligned

	-- multiplexer for the run increment
	run_inc : with in_cp.instruction_width select run_increment <=
		to_signed(1, internal_width) when sel_16bit,
		to_signed(2, internal_width) when sel_32bit;

	-- multiplexer for the secondary input of the internal adder
	adder_input : with in_cp.summand_select select adder_input_b <=
		run_increment when sel_run,
		signed(in_dp.immediate_value(adder_input_b'range)) when sel_immediate,
		signed(in_dp.register_value(adder_input_b'range)) when sel_register_a;

	-- pc value output combinatoric process
	pc_output : process(in_dec.stall, stall, in_cp.mode_select, pc_value_old, adder_result, adder_input_b) is
	begin
		if ((in_dec.stall = '1') or (stall = '1')) then
			-- if stalling, do not update output
			pc_value <= pc_value_old;

		else
			-- not stalling
			case in_cp.mode_select is
				when sel_relative =>
					-- if in relative mode use the result of the internal adder
					pc_value <= unsigned(adder_result);
				when sel_absolute =>
					-- if in absolute mode use the secondary input of the internal adder directly
					pc_value <= unsigned(adder_input_b);
			end case;
		end if;
	end process pc_output;

	-- adder
	adder_result <= unsigned(signed(pc_value_old) + adder_input_b);

	-- storage element
	pc_register : process(clk) is
	begin
		if rising_edge(clk) then
			if rst = '1' then
				pc_value_old <= to_unsigned(0, internal_width);
			else -- stall is done in combinatoric part already, not needed here additionally
				pc_value_old <= pc_value;
			end if;
		end if;
	end process pc_register;

end architecture RTL;
