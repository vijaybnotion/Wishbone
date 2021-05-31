-- See the file "LICENSE" for the full license governing this code. --
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

library  std;
use      std.standard.all;
use      std.textio.all;

library work;

use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all;
use work.wb_tp.all;

ENTITY mem2wb_tb IS
END mem2wb_tb;
 
ARCHITECTURE behavior OF mem2wb_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
component mem2wb
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask	:	generic_mask_type := CFG_MADR_MEM;
		wbidx		:	integer := CFG_MEM
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_dmem   : out core_dmem;
		out_dmem  : in 	dmem_core;
		
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
end component;

    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal out_dmem : dmem_core;
   signal wslvi : wb_slv_in_type := wbs_in_none;

 	--Outputs
   signal in_dmem : core_dmem;
   signal wslvo : wb_slv_out_type;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
   
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: mem2wb
	generic map(
		memaddr		=>	CFG_BADR_MEM,
		addrmask	=>	CFG_MADR_MEM,
		wbidx		=>	CFG_MEM
	)
	port map(
		clk			=>	clk,
		rst			=>	rst,
		
		in_dmem   	=>	in_dmem,
		out_dmem  	=>	out_dmem,	
		
		wslvi		=>	wslvi,
		wslvo		=>	wslvo
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
		--report ">> R e s e t";
		rst <= '1';
		wait for clk_period*3.5;
		rst <= '0';
		wait;
	end process; 

   -- Stimulus process
   stim_proc: process
	variable tmpadr :std_logic_vector(memory_width - 1 downto 0) := (others=>'0');
   begin		
        --init
	  out_dmem.read_data	<= (others=>'0');
	  out_dmem.ready		<= '0';
	  
	  --end init
	  
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
	--------------------------------------
	-- Test_case 00:
	--------------------------------------
	-- No request
	-- Expected output	all control signal should be inactive
	-- Expected error:			None
	--------------------------------------
	--report ">> TC0 starts <<";
	--------------------------------------
		-- Handshake-1 (in):
		tmpadr		:= x"0000000B"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= x"49303035"; 
		wslvi.we 	<= '0';			
		wslvi.sel	<= "0001";		
		wslvi.stb	<= '0';
		wslvi.cyc	<= '0';
		wait for clk_period; 
		
	  	-- Handshake-2 (out):
		assert wb2mem_chk(in_dmem, wslvi, NO_ACC) 
		report"E-00: No request, control signal should be inactive"
		severity error;
		
		-- Handshake-3 (in):
		out_dmem.read_data <= x"00000000";   -- mem always returns data at right most
		out_dmem.ready	  <= '0';
		wait for clk_period;
		
		-- Handshake-4 (out):
		assert wslvo.ack = '0'
		report"E-01: No request, ack signal should be inactive"
		severity error;
	--------------------------------------
	--report ">> TC0 ends <<";
	--------------------------------------
	--
	--E N D Test_case 00
	--
	--------------------------------------	
	--------------------------------------
	-- Test_case 01:
	--------------------------------------
	-- single read request
	-- given data at addr[0000_00005] = x"49303031";  (ascii = I001)
	-- B0 = x49, B2 = x30, B1 = x30, B0 = x31
	-- Expected output	Return correct read data back to wb in correct format
	-- Expected error:	None
	--------------------------------------
	--report ">> TC1 starts <<";
	--------------------------------------
		-- Handshake-1 (in):
		tmpadr		:= x"00000005"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= (others=>'0');
		wslvi.we 	<= '0';			-- read
		wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x30 
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period; 
		
	  	-- Handshake-2 (out):
		assert wb2mem_chk(in_dmem, wslvi, RD_ACC) 
		report"E-10: wrong conversion from wb to memory"
		severity error;
		
		-- Handshake-3 (in):
		out_dmem.read_data <= x"00000030";   -- mem always returns data at right most
		out_dmem.ready	  <= '1';
		wait for clk_period;
		
		-- Handshake-4 (out):
		assert wslvo.ack = '1' and wslvo.dat = x"00300000" 
		report"E-11: wrong conversion from memory data : " & hstr(out_dmem.read_data) &
			  " slvo.data: " & hstr(wslvo.dat)
		severity error;
	--------------------------------------
	--report ">> TC1 ends <<";
	--------------------------------------
	--
	--E N D Test_case 01
	--
	--------------------------------------	
	--------------------------------------
	-- Test_case 02:
	--------------------------------------
	-- single write request
	-- given data at addr[0000_0000C] = x"49303035";  (ascii = I005)
	-- B0 = x49, B2 = x30, B1 = x30, B0 = x35
	-- Expected output	Return ack, written data is converted correctly
	-- Expected error:			None
	--------------------------------------
	--report ">> TC2 starts <<";
	--------------------------------------
		-- Handshake-1 (in):
		tmpadr		:= x"0000000B"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= x"49303035"; -- feed full data but take written only B2
		wslvi.we 	<= '1';			-- write
		wslvi.sel	<= "0001";		-- sel_byte = B3 -> expected writted data portion = x35
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period; 
		
	  	-- Handshake-2 (out):
		assert wb2mem_chk(in_dmem, wslvi, WR_ACC) 
		report"E-20: wrong conversion from wb to memory"
		severity error;
		
		-- Handshake-3 (in):
		out_dmem.read_data <= x"00000000";   -- mem always returns data at right most
		out_dmem.ready	  <= '1';
		wait for clk_period;
		
		-- Handshake-4 (out):
		assert wslvo.ack = '1'
		report"E-21: wrong conversion from memory data : " & hstr(out_dmem.read_data) &
			  " slvo.data: " & hstr(wslvo.dat)
		severity error;
	--------------------------------------
	--report ">> TC2 ends <<";
	--------------------------------------
	--
	--E N D Test_case 02
	--
	--------------------------------------	
	   --clear data 
	  out_dmem.read_data	<= (others=>'0');
	  out_dmem.ready		<= '0';
	  wslvi					<= wbs_in_none;
	  tmpadr				:= (others=>'0');
	  --end clear

	  --/////////////////////////////////////////
	  assert false
	  report ">>>> Simulation beendet!"
      severity failure;
      --wait;
   end process;

END;
