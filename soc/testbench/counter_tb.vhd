-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all; 
use work.wb_tp.all;

ENTITY wb_swbtnisr_tb IS
END ENTITY;

ARCHITECTURE sim OF wb_swbtnisr_tb IS

	constant CLK_PERIOD : time := 10 ns;

	signal clk 	: std_logic := '0';
	signal rst	: std_logic := '0';

	signal led	: std_logic_vector(7 downto 0);
	signal btn		:   std_logic_vector(4 downto 0);
	signal sw		:   std_logic_vector(15 downto 0);
	--signal slvi     :      wb_slv_in_type;
	--signal slvo    :      wb_slv_out_type;
	--signal wslvi	:	wb_mst_out_type;
	--signal wslvo	:	wb_slv_out_type;
	
	--signal wd1	:	std_logic_vector(WB_PORT_SIZE-1 downto 0);
	--signal wd2	:	std_logic_vector(WB_PORT_SIZE-1 downto 0);
	--signal wd3	:	std_logic_vector(WB_PORT_SIZE-1 downto 0);
	--signal wd4	:	std_logic_vector(WB_PORT_SIZE-1 downto 0);

	COMPONENT lt16soc_top is
			generic(
				programfilename : string := "../../programs/assignment2isr.ram"

		);
		port(
			clk		: in  std_logic;
			rst		: in std_logic;
			led		: out std_logic_vector(7 downto 0);
			button		: in  std_logic_vector(4 downto 0);
			switches		: in  std_logic_vector(15 downto 0)
			
		);
	END COMPONENT;

BEGIN

	top_inst: lt16soc_top port map(
		clk=>clk,
		rst=>rst,
		led=>led,
		button=>btn,
		switches=>sw
	       );
	       
	      

	clk_gen: process
	begin
		clk	<= not clk;
		wait for CLK_PERIOD/2;
	end process clk_gen;

	
	stimuli: process
	begin
		rst	<= '0';
		wait for 10*CLK_PERIOD;
		rst	<= '1';
		sw <= x"0008";
		--wd1 <= "00000000000000000000000000011111";			--Value for counter
		--generate_sync_wb_single_write(slvi,slvo,clk,wd1,"10",0);
		wait for 50*CLK_PERIOD;
		--wd2 <= "00000000000000000000000000000100";                    -- Enabling
		--generate_sync_wb_single_write(slvi,slvo,clk,wd2,"10",4);
		
		wait for 50*CLK_PERIOD;
		--wd3 <= "00000000000000000000000000000110";                    -- Repeating
		--generate_sync_wb_single_write(slvi,slvo,clk,wd3,"10",4);
		
		--wait for 22*CLK_PERIOD;
		--wd4 <= "00000000000000000000000000000101";                  -- Resetting
		--generate_sync_wb_single_write(slvi,slvo,clk,wd4,"10",4);
		wait for 20000*CLK_PERIOD;
		assert false report "Simulation terminated!" severity failure;
	end process stimuli;


END ARCHITECTURE;

