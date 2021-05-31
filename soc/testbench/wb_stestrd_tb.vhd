-- See the file "LICENSE" for the full license governing this code. --
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

library work;
use work.wishbone.all;
use work.config.all;
--use work.wb_tp.all;
use std.textio.all;

 
ENTITY wb_stestrd_tb IS
END wb_stestrd_tb;
 
ARCHITECTURE behavior OF wb_stestrd_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT wb_stestrd
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         slvi : IN  wb_slv_in_type;
         slvo : OUT  wb_slv_out_type
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal slvi : wb_slv_in_type := wbs_in_none;

 	--Outputs
   signal slvo : wb_slv_out_type;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: wb_stestrd 
		PORT MAP (
          clk => clk,
          rst => rst,
          slvi => slvi,
          slvo => slvo
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
 	reset_process : process
	begin
		report  ">>>> R e s e t";
		rst <= '1';
		wait for clk_period*3.5;
		rst <= '0';
		wait;
	end process;

 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 
--test 1: no request
		slvi <= wbs_in_none ;
		
		wait for clk_period;
		assert (slvo.ack='0') report "err: no mst req, NO slv ack!!" 
		severity error;
--test 2		
		wait for clk_period;
		slvi.adr <= b"1010_0001_0000_0000_0000_0000_0000_00"; 
		slvi.dat <= (others=>'0');--x"B0B0B0B0"; -- wr_data
		slvi.we  <= '0';
		slvi.sel <= "1000"; -- sel byte 0 (big endian)
		slvi.stb <= '1';
		slvi.cyc <= '1';
		
		wait for clk_period;
		assert (slvo.ack='1') report "err: no Ack to master!!!" 
		severity error;
		
--test 3: no request
		wait for 5*clk_period;
		slvi <= wbs_in_none;
		
		wait for clk_period;
		assert (slvo.ack='0') report "err: no mst req, NO slv ack!!" 
		severity error;
		
-------/// repeat test
--test 4		
		wait for clk_period;
		slvi.adr <= b"1010_0001_0000_0000_0000_0000_0000_00"; 
		slvi.dat <= (others=>'0');--x"B0B0B0B0"; -- wr_data
		slvi.we  <= '0';
		slvi.sel <= "1111"; -- sel byte 0 (big endian)
		slvi.stb <= '1';
		slvi.cyc <= '1';
		
		wait for clk_period;
		assert (slvo.ack='1') report "err: no Ack to master!!!" 
		severity error;

--test 5: no request
		wait for 5*clk_period;
		slvi <= wbs_in_none;
		
		wait for clk_period;
		assert (slvo.ack='0') report "err: no mst req, NO slv ack!!" 
		severity error;
				
		
		report ">> F e r t i g: wb_stestrd <<";
      wait;
   end process;

END;
