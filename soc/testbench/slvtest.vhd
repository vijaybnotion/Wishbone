-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.lt16soc_peripherals.ALL;
USE work.wishbone.ALL;
USE work.wb_tp.ALL;
USE work.config.ALL;

ENTITY slvtest IS
END ENTITY;

ARCHITECTURE sim OF slvtest IS

	constant CLK_PERIOD : time := 10 ns;

	signal clk 	: std_logic := '0';
	signal rst	: std_logic;
	signal led	: std_logic_vector(7 downto 0);
	signal data	: std_logic_vector(WB_PORT_SIZE-1 downto 0);

	signal slvi	: wb_slv_in_type;
	signal slvo	: wb_slv_out_type;

BEGIN

	SIM_SLV: wb_led
		generic map(
			memaddr		=> CFG_BADR_LED,
			addrmask	=> CFG_MADR_LED
		)
		port map(
			clk		=> clk,
			rst		=> rst,
			led		=> led,
			wslvi	=> slvi,
			wslvo	=> slvo
		);

	clk_gen: process
	begin
		clk	<= not clk;
		wait for CLK_PERIOD/2;
	end process clk_gen;

	stimuli: process
	begin
		rst	<= '1';
		wait for CLK_PERIOD;
		rst	<= '0';
		data	<= std_logic_vector(to_unsigned(431,32));
		wait for CLK_PERIOD;

		generate_sync_wb_single_write(slvi,slvo,clk,data);
		wait for 2 ns;
		data	<= (others => '0');
		generate_sync_wb_single_read(slvi,slvo,clk,data);

		wait;
	end process stimuli;

END ARCHITECTURE;
