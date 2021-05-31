-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY dmem_sw_tb IS
END ENTITY;

ARCHITECTURE sim OF dmem_sw_tb IS

	constant CLK_PERIOD : time := 10 ns;

	signal clk 	: std_logic := '0';
	signal rst	: std_logic;

	signal led	: std_logic_vector(7 downto 0);

	COMPONENT lt16soc_top IS
		generic(
			programfilename : string := "programs/blinky.ram" -- see "Synthesize XST" process properties for actual value ("-generics" in .xst file)!
		);
		port(
			clk		: in  std_logic;
			rst		: in std_logic;
			led		: out std_logic_vector(7 downto 0)
		);
	END COMPONENT;

BEGIN

	dut: lt16soc_top 
	generic map(
		programfilename=>"programs/dmem_test.ram"
	)
	port map(
		clk=>clk,
		rst=>rst,
		led=>led
	);

	clk_gen: process
	begin
		clk	<= not clk;
		wait for CLK_PERIOD/2;
	end process clk_gen;

	stimuli: process
	begin
		rst	<= '0';
		wait for CLK_PERIOD;
		rst	<= '1';
		wait for 2000*CLK_PERIOD;
		wait;
	end process stimuli;


END ARCHITECTURE;
