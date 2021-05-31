-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all; 
use work.wb_tp.all;

ENTITY swbtn_tb IS
END ENTITY;

ARCHITECTURE sim OF swbtn_tb IS

	constant CLK_PERIOD : time := 10 ns;

	signal clk 	: std_logic := '0';
	signal rst	: std_logic := '0';

	signal led	: std_logic_vector(7 downto 0);
	signal btn	: std_logic_vector(4 downto 0) :=(others => '0');
	signal sw	: std_logic_vector(15 downto 0) :=(others => '0');
	--signal wslvi	:	wb_slv_in_type;
	--signal wslvo	:	wb_slv_out_type;
	--signal slvi     :      wb_slv_in_type;
	--signal slvo     :      wb_slv_out_type;
	--signal swbtn_data : std_logic_vector(31 downto 0) :=(others => '0');


COMPONENT lt16soc_top IS
generic(
programfilename : string := "../../programs/assignment2code.ram" 
);
port(
clk : in std_logic;
rst : in std_logic;
led : out std_logic_vector(7 downto 0);
button : in std_logic_vector(4 downto 0);
switches : in std_logic_vector(15 downto 0)
);
END COMPONENT;


BEGIN

top_inst : component lt16soc_top 
port map(
clk=>clk,
rst=>rst,
led=>led,
button=>btn,
switches=>sw
);

	btn <="00000";

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
		sw <= "0000000000001000";
		--generate_sync_wb_single_read(slvi,wslvo,clk,swbtn_data);
		wait for 10000*CLK_PERIOD;
		sw <= "0000000000000001";
		wait for 10000*CLK_PERIOD;
		sw <= "0000000000001111";
		--generate_sync_wb_single_read(slvi,wslvo,clk,swbtn_data);
		wait for 10000*CLK_PERIOD;
		--generate_sync_wb_single_read(slvi,wslvo,clk,swbtn_data);
		wait for 20000*CLK_PERIOD;
		assert false report "Simulation terminated!" severity failure;
	end process stimuli;


END ARCHITECTURE;


