-- See the file "LICENSE" for the full license governing this code. --
library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

library  std;
use      std.standard.all;
use      std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.lt16soc_memories.all;

ENTITY memwrap_tb IS
END memwrap_tb;
 
ARCHITECTURE behavior OF memwrap_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
    
	-- Clock period definitions
   constant clk_period : time := 10 ns;
   
   
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal in_imem : core_imem;
   signal wslvi : wb_slv_in_type := wbs_in_none;

 	--Outputs
   signal out_imem 	: imem_core;
   signal fault 	: std_logic;
   signal out_byte : std_logic_vector(7 downto 0);
   signal wslvo 	: wb_slv_out_type;


	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	memwrap_inst: memwrapper
	generic map(
		memaddr		=> CFG_BADR_MEM, 
		addrmask	=> CFG_MADR_MEM,
		wbidx 		=> CFG_MEM,
		filename	=> "sample-programs\dummy.ram",
		size		=> IMEMSZ
	)
	port map(
		clk 		=> clk,
        rst 		=> rst,
		in_imem		=> in_imem, 
		out_imem	=> out_imem,
		
		fault		=> fault, --irq_lines(2),
		
		wslvi		=> wslvi,
		wslvo		=> wslvo
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	reset : process is
	begin
		rst <= '1';
		wait for 3.5 * clk_period;
		rst <= '0';
		wait;
	end process reset;
	
   -- Stimulus process
   stim_proc: process
		variable tmpadr	: std_logic_vector(memory_width - 1 downto 0)  := (others=>'0');
   begin		
      --init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1'; -- always read
	  wslvi				<= wbs_in_none;
	  --end init
	  
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;
	--------------------------------------
	-- Test_case 00:
	--------------------------------------
	-- No request
	-- Expected output	all control signal should be inactive
	-- Expected error:	None
	--------------------------------------
	--report ">> TC0 starts <<";
	--------------------------------------
	assert wslvo.ack = '1'
	report"E-00: No request, but slvo.ack for dmem should always be active"
	severity error;
	
	assert out_imem.ready = '1'
	report"E-01: No request, but out_imem.ready should always be active"
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
	-- Single ins read
	-- Expected output	ins is read correctly
	-- Expected error:	None
	-- 32b_adr = x"00000052", 30b_adr = x"00000014"
	-- data at the adr = x49303230 (ascii, I020)
	--------------------------------------
	--report ">> TC1 starts <<";
	--------------------------------------
		--data
		assert wslvo.ack = '1'
		report"E-10: No request, but slvo.ack for dmem should always be active"
		severity error;
		--ins
		in_imem.read_en		<= '1'; in_imem.read_addr	<= x"00000052"; wait for clk_period;
		assert out_imem.read_data = x"49303230" and out_imem.ready = '1'--value in ascii =  I020
		report "E-11: ins_RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
		severity error;
		--
	--------------------------------------
	--report ">> TC1 ends <<";
	--------------------------------------
	--
	--E N D Test_case 01
	--
	--------------------------------------
	  --init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	  --end init
	--------------------------------------
	-- Test_case 02:
	--------------------------------------
	-- Single data read
	-- Expected output	ins is read correctly
	-- Expected error:	None
	-- 32b_adr = x"00000210", 30b_adr = x"00000084"
	-- data at the adr = x44303034 (ascii, D004)
	--------------------------------------
	--report ">> TC2 starts <<";
	--------------------------------------
		--data
		-- Handshake-1 (in):
		tmpadr		:= x"00000210"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= (others=>'0');
		wslvi.we 	<= '0';			-- read
		wslvi.sel	<= "1000";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x30 
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period; 
		
		-- Handshake-2 (out):
		assert wslvo.dat = x"44000000" and wslvo.ack = '1'
		report"E-20: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"44000000")
		severity error;
		
		--ins
		assert out_imem.ready = '1'
		report"E-21: No request, but out_imem should always be active"
		severity error;	
	----------------
		
	--------------------------------------
	--report ">> TC2 ends <<";
	--------------------------------------
	--
	--E N D Test_case 02
	--
	--------------------------------------
	  --init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	  --end init
	--------------------------------------
	-- Test_case 03:
	--------------------------------------
	-- Single data write, non overlap addr
	-- write in address range of data
	-- given data at addr[0000_00215] = x"44303035";  (ascii = D005)
	-- B0 = x49, B2 = x30, B1 = x30, B0 = x35
	-- Expected output	Return ack, written data is converted correctly
	-- Expected error:			None
	--------------------------------------
	--report ">> TC3 starts <<";
	--------------------------------------
		--data
		-- Handshake-1 (in):
		tmpadr		:= x"00000215"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= x"AA35AAAA"; -- feed full data but take written only B2 (feed junk for the rest portion, making sure only sel part is taken)
		wslvi.we 	<= '1';			-- write
		wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected writted data portion = x35
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period; 
		
		-- Handshake-2 (out):
		assert wslvo.ack = '1'
		report"E-30: WR request, No ack "
		severity error;

		--Read value for checking written value
		-- Handshake-3 (in):
		--tmpadr		:= x"0000000B"; 
	  	--wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= (others=>'0');
		wslvi.we 	<= '0';			-- read
		wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x35
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period;

		-- Handshake-4 (out):
		assert wslvo.dat = x"00350000" and wslvo.ack = '1'
		report"E-31: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"00350000")
		severity error;

		--ins
		assert out_imem.ready = '1'
		report"E-32: No request, but out_imem should always be active"
		severity error;	
	--------------------------------------
	--report ">> TC3 ends <<";
	--------------------------------------
	--
	--E N D Test_case 03
	--
	--------------------------------------
	--init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	--end init
	--------------------------------------
	-- Test_case 04:
	--------------------------------------
	-- Single data write, overlap addr
	-- write in address range of data
	-- given data at addr[0000_00015] = x"49303035";  (ascii = I005)
	-- B0 = x49, B2 = x30, B1 = x30, B0 = x35
	-- Expected output	Return ack, written data is converted correctly
	-- Expected error:			None
	--------------------------------------
	--report ">> TC4 starts <<";
	--------------------------------------
		--data
		-- Handshake-1 (in):
		tmpadr		:= x"00000015"; 
	  	wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= x"AA35AAAA"; -- feed full data but take written only B2 (feed junk for the rest portion, making sure only sel part is taken)
		wslvi.we 	<= '1';			-- write
		wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected writted data portion = x35
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period; 
		
		-- Handshake-2 (out):
		assert wslvo.ack = '1'
		report"E-40: WR request, No ack "
		severity error;

		--Read value for checking written value
		-- Handshake-3 (in):
		--tmpadr		:= x"0000000B"; 
	  	--wslvi.adr	<= tmpadr(31 downto 2);
		wslvi.dat	<= (others=>'0');
		wslvi.we 	<= '0';			-- read
		wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x35
		wslvi.stb	<= '1';
		wslvi.cyc	<= '1';
		wait for clk_period;

		-- Handshake-4 (out):
		assert wslvo.dat = x"00350000" and wslvo.ack = '1'
		report"E-41: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"00350000")
		severity error;

		--ins
		assert out_imem.ready = '0'
		report"E-42: Read data address is in ins address range, thus imem.ready should be hold to grant to the slv"
		severity error;	
	--------------------------------------
	--report ">> TC4 ends <<";
	--------------------------------------
	--
	--E N D Test_case 04
	--
	--------------------------------------
	--init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	  --end init
	--------------------------------------
	-- Test_case 05:
	--------------------------------------
	-- Sim ins/data read, non overlap address
	-- Expected output	ins/data is read correctly
	-- Expected error:	None
	--
	-- >> data_info
	-- 32b_adr = x"00000210", 30b_adr = x"00000084"
	-- data at the adr = x44303034 (ascii, D004)
	--
	-- >> ins_info
	-- 32b_adr = x"00000052", 30b_adr = x"00000014"
	-- data at the adr = x49303230 (ascii, I020)
	--------------------------------------
	--------------------------------------
	--report ">> TC5 starts <<";
	--------------------------------------
	
		-- Handshake-1 (in):
			-- data
			tmpadr		:= x"00000210"; 
			wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= (others=>'0');
			wslvi.we 	<= '0';			-- read
			wslvi.sel	<= "1000";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x30 
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			-- ins
			in_imem.read_en		<= '1'; in_imem.read_addr	<= x"00000052"; 
			wait for clk_period;
		
		-- Handshake-2 (out):
			-- data
			assert wslvo.dat = x"44000000" and wslvo.ack = '1'
			report"E-50: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"44000000")
			severity error;
			-- ins
			assert out_imem.read_data = x"49303230" and out_imem.ready = '1'--value in ascii =  I020
			report "E-51: ins_RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
			severity error;
		
	--------------------------------------
	--report ">> TC5 ends <<";
	--------------------------------------
	--
	--E N D Test_case 05
	--
	--------------------------------------
	--init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	--end init
	--------------------------------------
	-- Test_case 06:
	--------------------------------------
	-- Sim ins/data read, overlap address range
	-- Expected output	ins/data is read correctly
	-- Expected error:	None
	--
	-- >> data_info
	-- 32b_adr = x"00000056", 30b_adr = x"00000015"
	-- data at the adr = x49303231 (ascii, I021)
	--
	-- >> ins_info
	-- 32b_adr = x"00000052", 30b_adr = x"00000014"
	-- data at the adr = x49303230 (ascii, I020)
	--------------------------------------
	--------------------------------------
	--report ">> TC6 starts <<";
	--------------------------------------
	
		-- Handshake-1 (in):
			-- data
			tmpadr		:= x"00000056"; 
			wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= (others=>'0');
			wslvi.we 	<= '0';			-- read
			wslvi.sel	<= "0010";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x30 
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			-- ins
			in_imem.read_en		<= '1'; in_imem.read_addr	<= x"00000052"; 
			wait for clk_period;
		
		-- Handshake-2 (out):
			-- data
			assert wslvo.dat = x"00003200" and wslvo.ack = '1'
			report"E-60: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"00003200")
			severity error;
			-- ins
			assert out_imem.read_data = x"49303230" and out_imem.ready = '0' -- overlap address range, ready must be inactive
			report "E-61: ins_RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
			severity error;
		
	--------------------------------------
	--report ">> TC6 ends <<";
	--------------------------------------
	--
	--E N D Test_case 06
	--
	--------------------------------------	
	--init
	  in_imem.read_addr	<= (others=>'0');
	  in_imem.read_en	<= '1';
	  wslvi				<= wbs_in_none;
	  wait for clk_period;
	--end init
	-------------------------------------
	-- Test_case 07:
	--------------------------------------
	-- Sim ins read and data write, non overlap address range
	-- Expected output	ins/data is read correctly
	-- Expected error:	None
	--
	-- >> data_info
	-- 32b_adr = x"00000215", 30b_adr = x"00000085"
	-- data at the adr = x44303035 (ascii, D005)
	--
	-- >> ins_info
	-- 32b_adr = x"00000052", 30b_adr = x"00000014"
	-- data at the adr = x49303230 (ascii, I020)
	--------------------------------------
	--------------------------------------
	--report ">> TC7 starts <<";
	--------------------------------------
		-- Handshake-1 (in):
			-- data
			tmpadr		:= x"00000215"; 
			wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= x"AA35AAAA"; -- feed full data but take written only B2 (feed junk for the rest portion, making sure only sel part is taken)
			wslvi.we 	<= '1';			-- write
			wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected writted data portion = x35
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			-- ins
			in_imem.read_en		<= '1'; in_imem.read_addr	<= x"00000052"; 
			wait for clk_period;
		
		-- Handshake-2 (out):
			-- data
			assert wslvo.ack = '1'
			report"E-70: WR request, ack should be active "
			severity error;
			-- ins
			assert out_imem.read_data = x"49303230" and out_imem.ready = '1' -- overlap address range, ready must be inactive
			report "E-71: imem.ready is inactive or Non-match ins val" &
					" ins_RD req addr: " & hstr(in_imem.read_addr) & 
					", Return rd ins val: " & hstr(out_imem.read_data) 
			severity error;
			
		--Read value for checking written value
		-- Handshake-3 (in):
		--	tmpadr		:= x"00000215"; 
	  	--	wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= (others=>'0');
			wslvi.we 	<= '0';			-- read
			wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x35
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			wait for clk_period;

		-- Handshake-4 (out):
			assert wslvo.dat = x"00350000" and wslvo.ack = '1'
			report"E-72: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"00350000")
			severity error;	
	--------------------------------------
	--report ">> TC7 ends <<";
	--------------------------------------
	--
	--E N D Test_case 07
	--
	--------------------------------------	
	--------------------------------------
	-- Test_case 08:
	--------------------------------------
	-- Sim ins read and data write, overlap address range
	-- Expected output	ins/data is read correctly
	-- Expected error:	None
	--
	-- >> data_info
	-- 32b_adr = x"00000015", 30b_adr = x"00000005"
	-- data at the adr = x49303035 (ascii, I005)
	--
	-- >> ins_info
	-- 32b_adr = x"00000052", 30b_adr = x"00000014"
	-- data at the adr = x49303230 (ascii, I020)
	--------------------------------------
	--------------------------------------
	--report ">> TC8 starts <<";
	--------------------------------------
	
		-- Handshake-1 (in):
			-- data
			tmpadr		:= x"00000015"; 
		  	wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= x"AA35AAAA"; -- feed full data but take written only B2 (feed junk for the rest portion, making sure only sel part is taken)
			wslvi.we 	<= '1';			-- write
			wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected writted data portion = x35
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			-- ins
			in_imem.read_en		<= '1'; in_imem.read_addr	<= x"00000052"; 
			wait for clk_period;
		
		-- Handshake-2 (out):
			-- data
			assert wslvo.ack = '1'
			report"E-80: WR request, No ack "
			severity error;
			-- ins
			assert out_imem.read_data = x"49303230" and out_imem.ready = '0' -- overlap address range, ready must be inactive
			report "E-81: ins_RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
			severity error;
			
			--Read value for checking written value
			-- Handshake-3 (in):
			--tmpadr		:= x"0000000B"; 
		  	--wslvi.adr	<= tmpadr(31 downto 2);
			wslvi.dat	<= (others=>'0');
			wslvi.we 	<= '0';			-- read
			wslvi.sel	<= "0100";		-- sel_byte = B1 -> expected value return = 0 (ascii) or x35
			wslvi.stb	<= '1';
			wslvi.cyc	<= '1';
			wait for clk_period;

			-- Handshake-4 (out):
			assert wslvo.dat = x"00350000" and wslvo.ack = '1'
			report"E-82: wrong data, Return data: " & hstr(wslvo.dat) & " Expected data: " & hstr(x"00350000")
			severity error;
	--------------------------------------
	--report ">> TC8 ends <<";
	--------------------------------------
	--
	--E N D Test_case 08
	--
	--------------------------------------	
	  --/////////////////////////////////////////
	  assert false
	  report ">>>> Simulation beendet!"
      severity failure;
      --wait;
   end process;

END;
