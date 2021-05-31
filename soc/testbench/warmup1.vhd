-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY warmup1_tb IS
END ENTITY;

ARCHITECTURE sim OF warmup1_tb IS

	constant CLK_PERIOD : time := 10 ns;

	signal clk 	: std_logic := '0';
	signal rst	: std_logic;
    signal button   : std_logic_vector (4 downto 0) := (others =>'0');
    signal switches : std_logic_vector (15 downto 0) := (others =>'0');
	signal led	: std_logic_vector(7 downto 0);

	COMPONENT lt16soc_top IS
		generic(
			programfilename : string := "../../programs/assignment2code1.ram"
		);
		port(
			clk		: in  std_logic;
			rst		: in std_logic;
			button   : in std_logic_vector (4 downto 0);
            switches : in std_logic_vector (15 downto 0);
			led		: out std_logic_vector(7 downto 0)
		);
	END COMPONENT;

BEGIN

	dut: lt16soc_top port map(
		clk=>clk,
		rst=>rst,
		button => button,
		switches => switches,
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
		--switches <= x"CCCC";
		--generate_sync_wb_single_read(wslvi, wslvo, clk, data);
		wait for CLK_PERIOD;
		rst	<= '1';
		wait for 20000*CLK_PERIOD;
		assert false report "Simulation terminated!" severity failure;
	end process stimuli;


END ARCHITECTURE;
