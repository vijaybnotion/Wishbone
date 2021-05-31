-- See the file "LICENSE" for the full license governing this code. --
--------------------------------------------------------------------------------
-- Notes: 
-- Test case description: 
-- 1. Test template is provided at bottommost of this module
-- 2. Test case number descripion:
--		read request:	start with test case number 0x
-- 		write request:	start with test case number 5x
-- 3. Error format description: E-xy: (wbicn, fn.<CALLED FUNCTION NAME>)
--		x = main case number
--		y = subcase number
-- 4. The 4-signal handshake sequences of wb_intercon are following
--		Handshake 1 
--			> master request(s) = msto
--			> master module(s) to wb_intercon
--		Handshake 2
--			> slave obtains the granted master request = slvi
--			> wb_intercon to slave module(s)
--		Handshake 3
--			> slave responses to the granted master request = slvo
--			> slave module(s) to wb_intercon
--		Handshake 4
--			> granted master obtains slave response = msti
--			> wb_intercon to master module
-- 5. This test module mainly checks outputs of wb_intercon i.e. msti and slvi
--			> slvi_chk_all function is used for slvi validation
--			> msti_chk_all function is used for msti validation
-- 6. In order to fulfill the request loop as mentioned in (4), 
--	  This module requires to call test_slave modules for both read and write request
-- 	  a) wb_stestrd
--			> test_slave module for read
--			> This module simply provides read data based on the request address
--	  b) wb_stestwr
--			> test_slave module for write
--			> write to LED
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_textio.all;

library  std;
use      std.standard.all;
use      std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.wb_tp.all;
use work.txt_util.all;

ENTITY wb_intercon_tb IS
END wb_intercon_tb;
 
ARCHITECTURE behavior OF wb_intercon_tb IS 
 
    -- component Declaration for the Unit Under Test (UUT)
 
    component wb_intercon
	 	generic(
		slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"0000_0000_0000_0000"; 
		mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000"
	);
    port(
         clk  : in	std_logic;
         rst  : in	std_logic;
         msti : out	wb_mst_in_vector;
         msto : in	wb_mst_out_vector;
         slvi : out	wb_slv_in_vector;
         slvo : in	wb_slv_out_vector
        );
    end component;
	 
	component wb_stestrd
		generic(
			memaddr  : generic_addr_type :=0;
			addrmask : generic_mask_type :=16#3fffff#;
			wbidx: integer := 0
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    			: in  wb_slv_in_type;
		slvo    			: out wb_slv_out_type;
		test_rddat			: in	std_logic_vector(31 downto 0)
		);
	end component;
	
	component wb_stestwr
	generic(
		memaddr  : generic_addr_type :=0;
		addrmask : generic_mask_type :=16#3fffff#;
		wbidx: integer := 0
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    			: in  wb_slv_in_type;
		slvo    			: out wb_slv_out_type;
		led					: out std_logic_vector (7 downto 0)
	);
	end component;
	
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal msto : wb_mst_out_vector;
   signal slvo : wb_slv_out_vector;

 	--Outputs
   signal msti : wb_mst_in_vector;
   signal slvi : wb_slv_in_vector;
   signal led, led1, led2	: std_logic_vector(7 downto 0);
   
   --temp
   -- read
   signal testslave0_o, testslave1_o, testslave3_o, testslave5_o, testslave15_o: wb_slv_out_type := wbs_out_none;
   -- write
   signal testslave2_o, testslave4_o, testslave14_o: wb_slv_out_type := wbs_out_none;
---------------------
-- constant
---------------------
	constant clk_period : time := 10 ns;
	signal req_mst_idx :integer range 0 to NWBMST-1;
	signal test_rddat: std_logic_vector(31 downto 0) := (others=>'0');
	
	constant slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"1110_0100_0000_0011";
	constant mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"1011";
	--base adr
	constant CFG_BADR_TSTS0		: generic_addr_type := 16#2A000000#; -- 30bits (32b = A8000000)
	constant CFG_BADR_TSTS1		: generic_addr_type := 16#28400000#; -- 30bits (32b = A1000000) 
	constant CFG_BADR_TSTS2		: generic_addr_type := 16#28800000#; -- 30bits (32b = A2000000)
	constant CFG_BADR_TSTS3		: generic_addr_type := 16#28C00000#; -- 30bits (32b = A3000000)
	constant CFG_BADR_TSTS4		: generic_addr_type := 16#29000000#; -- 30bits (32b = A4000000) 
	constant CFG_BADR_TSTS14	: generic_addr_type := 16#2B800000#; -- 30bits (32b = A2000000)
	constant CFG_BADR_TSTS15	: generic_addr_type := 16#2BC44000#; -- 30bits (32b = AF110000)
	--mask adr
	constant CFG_MADR_TSTS14	: generic_mask_type := 16#3FC000#; 
	constant CFG_MADR_TSTS15	: generic_mask_type := 16#3FC000#;
	constant CFG_MADR_ZERO		: generic_mask_type := 0;
	constant CFG_MADR_FULL		: generic_mask_type := 16#3FFFFF#;

begin
	-- Instantiate the Unit Under Test (UUT)
   uut: wb_intercon 
	generic map(
		slv_mask_vector => slv_mask_vector,
		mst_mask_vector => mst_mask_vector
	)
	port map(
          clk => clk,
          rst => rst,
          msti => msti,
          msto => msto,
          slvi => slvi,
          slvo => slvo
    );
	--------------------------------------	
	---- slv- (rd)
	--------------------------------------	
	srd00: wb_stestrd
	generic map(
		memaddr	=> CFG_BADR_TSTS0,
		addrmask => CFG_MADR_ZERO,
		wbidx => 0
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave0_o,
		slvi.adr => slvi(0).adr,
		slvi.dat => slvi(0).dat,
		slvi.we  => slvi(0).we,
		slvi.sel => slvi(0).sel,
		slvi.stb => slvi(0).stb,
		slvi.cyc => slvi(0).cyc,
		test_rddat => test_rddat
	);	
	
	srd01: wb_stestrd
	generic map(
		memaddr => CFG_BADR_TSTS1,
		addrmask => CFG_MADR_ZERO,
		wbidx => 1
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave1_o,
		slvi.adr => slvi(1).adr,
		slvi.dat => slvi(1).dat,
		slvi.we  => slvi(1).we,
		slvi.sel => slvi(1).sel,
		slvi.stb => slvi(1).stb,
		slvi.cyc => slvi(1).cyc,
		test_rddat => test_rddat
	);	
	
	srd03: wb_stestrd
	generic map(
		memaddr => CFG_BADR_TSTS3,
		addrmask => CFG_MADR_ZERO,
		wbidx => 3
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave3_o,
		slvi.adr => slvi(3).adr,
		slvi.dat => slvi(3).dat,
		slvi.we  => slvi(3).we,
		slvi.sel => slvi(3).sel,
		slvi.stb => slvi(3).stb,
		slvi.cyc => slvi(3).cyc,
		test_rddat => test_rddat
	);		

	srd05: wb_stestrd
	generic map(
		memaddr => 16#00000000#, --30bits (32b = 00000000) -- test ADDR_base = 0
		addrmask => CFG_MADR_FULL, 
		wbidx => 5
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave5_o,
		slvi.adr => slvi(5).adr,
		slvi.dat => slvi(5).dat,
		slvi.we  => slvi(5).we,
		slvi.sel => slvi(5).sel,
		slvi.stb => slvi(5).stb,
		slvi.cyc => slvi(5).cyc,
		test_rddat => test_rddat
	);	
	
	srd15: wb_stestrd
	generic map(
		memaddr => CFG_BADR_TSTS15,
		addrmask => CFG_MADR_TSTS15, 
		wbidx => 15
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave15_o,
		slvi.adr => slvi(15).adr,
		slvi.dat => slvi(15).dat,
		slvi.we  => slvi(15).we,
		slvi.sel => slvi(15).sel,
		slvi.stb => slvi(15).stb,
		slvi.cyc => slvi(15).cyc,
		test_rddat => test_rddat
	);			
	--------------------------------------	
	---- slv- (wr)
	--------------------------------------	
	swr02: wb_stestwr
	generic map(
		memaddr => CFG_BADR_TSTS2,
		addrmask => CFG_MADR_ZERO,
		wbidx => 2
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave2_o,
		slvi.adr => slvi(2).adr,
		slvi.dat => slvi(2).dat,
		slvi.we  => slvi(2).we,
		slvi.sel => slvi(2).sel,
		slvi.stb => slvi(2).stb,
		slvi.cyc => slvi(2).cyc,
		led => led
	);	  	

	swr04: wb_stestwr
	generic map(
		memaddr => 16#29000000#, --30bits (32b = A4000000)
		addrmask => CFG_MADR_ZERO,
		wbidx => 4
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave4_o,
		slvi.adr => slvi(4).adr,
		slvi.dat => slvi(4).dat,
		slvi.we  => slvi(4).we,
		slvi.sel => slvi(4).sel,
		slvi.stb => slvi(4).stb,
		slvi.cyc => slvi(4).cyc,
		led => led1
	);	  	

	swr14: wb_stestwr
	generic map(
		memaddr => CFG_BADR_TSTS14,
		addrmask => CFG_MADR_TSTS14,
		wbidx => 14
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave14_o,
		slvi.adr => slvi(14).adr,
		slvi.dat => slvi(14).dat,
		slvi.we  => slvi(14).we,
		slvi.sel => slvi(14).sel,
		slvi.stb => slvi(14).stb,
		slvi.cyc => slvi(14).cyc,
		led => led2
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

	--------------------------------------	
	-- Process: gen_slv
	--
	-- Directly copy output from testslv module e.g. wb_stestrd, wb_stestwr and input to the wb_intercon
	-- Remark: The process is made due to the error that occured 
	--         from outputting slvo directly from wb_stestrd and wb_stestwr 
	--------------------------------------
	gen_slv: process(
						testslave0_o, 
						testslave1_o, 
						testslave2_o, 
						testslave3_o, 
						testslave4_o, 
						testslave5_o, 
						testslave14_o, 
						testslave15_o
						) is
	begin
		slvo 		<= (others=> wbs_out_none);
		-- read
		slvo(0) 	<= testslave0_o; 
		slvo(1) 	<= testslave1_o; 
		slvo(3)		<= testslave3_o;
		slvo(5)		<= testslave5_o;
		slvo(15) 	<= testslave15_o; 
		-- write
		slvo(2) 	<= testslave2_o; 
		slvo(4) 	<= testslave4_o; 
		slvo(14) 	<= testslave14_o; 
	end process;

   -- Stimulus process
   stim_proc: process

   begin		
		--report ">> S t a r t <<";
		
	--------------------------------------
	-- Test case 00:
	--
	-- No request
	--------------------------------------
		--report ">> TC0 starts <<";
	--------------------------------------
		req_mst_idx <= 0; wait for clk_period;
		-- Handshake-1:
		msto <= (others=> wbm_out_none); 
		wait for clk_period;
		
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2:
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-02: (wbicn, fn.slvi_chk_all): No request, all slave input vector should be quiet"
		severity error;
		
		-- Handshake-3: 
		-- <slvo>

		-- Handshake-4:
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-04: (wbicn, fn.msti_chk_all): No request, all master should be quiet"
		severity error;

	--------------------------------------
	--report ">> TC0 ends <<";
	--------------------------------------
	--
	--E N D Test_case 00
	--
	--------------------------------------	

		wait for 10*clk_period;
		wait for clk_period/2;
	--------------------------------------
	-- Test_case 01:
	--------------------------------------
	-- single master read, valid address
	-- Expected output, slvi:	correct selected slave
	-- Expected output, msti:	correct response from selected slave
	-- Expected error:			None
	--------------------------------------
		--report ">> TC1 starts <<";
	--------------------------------------
		
	-- Handshake-1: master requests (input for intercon)
		req_mst_idx <= 3; test_rddat <= x"A00FF00A";
		wait for clk_period; 
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A1000003", (others=>'0'), "1000");
		wait for clk_period;
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector); 
		-- Handshake-2: 
		--wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-10: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-12: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC1 ends <<";
	--------------------------------------
	--
	--E N D Test_case 01
	--
	--------------------------------------	
	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	
	--------------------------------------
	-- Test_case 02:
	-- single master read, valid address, different master from Test_case 01
	-- Expected output, slvi:	correct selected slave
	-- Expected output, msti:	correct response from selected slave
	-- Expected error:	None
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC2 starts <<";
	--------------------------------------

		-- Handshake-1: master requests (input for intercon)
		req_mst_idx <= 2; test_rddat <= x"B00FF00B";
		wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A1000000", (others=>'0'), "1000");
		wait for clk_period;
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-20: slvi_chk function"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-22: (wbicn, fn.msti_chk)"
		severity error;
		
	--------------------------------------
	--report ">> TC2 ends <<";
	--------------------------------------
	--
	--E N D Test_case 02
	--
	--------------------------------------	
	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--//////////////////////////////////////////////
	--
	--------------------------------------
	-- Test_case 03:
	-- single master read, invalid address
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	no response for all msti
	-- Expected error:			invalid address map from slvi_chk
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC3 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		req_mst_idx <= 3; test_rddat <= x"FFFFFFFF";
		wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"FF000000", (others=>'0'), "1000");
		--! there is no slave at address x"FF000000"? --TF
		wait for clk_period; 

		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-30: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		--assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-32: (wbicn, fn.msti_chk_all) should return false"
		severity error;
	--------------------------------------
	--report ">> TC3 ends <<";
	--------------------------------------
	--
	--E N D Test_case 03
	--
	--------------------------------------	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	
	--------------------------------------
	-- Test_case 04:
	-- mult master, same address request
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	response to higher priority master
	-- Expected error:			no
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC4 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		test_rddat <= x"D00FF00D";
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A1000000", (others=>'0'), "0100");
		wait for clk_period; 

		req_mst_idx <= 2; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A1000000", (others=>'0'), "0100");
		wait for clk_period;
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-40: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>

		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-42: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC4 ends <<";
	--------------------------------------
	--
	--E N D Test_case 04
	--
	--------------------------------------	

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	
	--------------------------------------
	-- Test_case 05:
	-- mutl master (highest granted master w/ invalid address)
	-- Expected output, slvi:	input for valid address
	-- Expected output, msti:	input for valid request master
	-- Expected error:			Error, invalid address for higher priority and no grant to lower priority although it's valid
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC5 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		test_rddat <= x"D00FF00D";
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"FF000000", (others=>'0'), "0100");
		wait for clk_period; 

		req_mst_idx <= 0; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A1000000", (others=>'0'), "0100");
		wait for clk_period; 
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-50: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>

		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-52: (wbicn, fn.msti_chk_all): should return false"
		severity error;
	
	--------------------------------------
	--report ">> TC5 ends <<";
	--------------------------------------
	--
	--E N D Test_case 05
	--
	--------------------------------------	

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////

	--------------------------------------
	-- Test_case 06:
	--------------------------------------
	-- single master read, valid address, inactive slave
	-- Expected output, slvi: no request for all slvi
	-- Expected output, msti: no request for all msti	
	-- Expected error:	Error, no address map
	--------------------------------------
		--report ">> TC6 starts <<";
	--------------------------------------
		
		-- Handshake-1: master requests (input for intercon)
		req_mst_idx <= 3; test_rddat <= x"FFFFFFFF";
		wait for clk_period; 
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"A3000000", (others=>'0'), "1000");
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert not slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-60: (wbicn, fn.slvi_chk_all): no address map, it should return false"
		severity error;


		-- Handshake-3: 
		-- <slvo>
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-62: (wbicn, fn.msti_chk_all): no address map, it should return false"
		severity error;
	--------------------------------------
	--report ">> TC6 ends <<";
	--------------------------------------
	--
	--E N D Test_case 06
	--
	--------------------------------------	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--//////////////////////////////////////////////
	--------------------------------------
	-- Test_case 07:
	-- test masking by reusing test case 4
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	response to higher priority master
	-- Expected error:			no
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC7 starts <<";
	--------------------------------------
	-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		test_rddat <= x"A770077A"; -- for slave A100_0000
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"AF110710", (others=>'0'), "0100");-- map to same slv (in range)
		wait for clk_period; -- Need for msto assignment

		req_mst_idx <= 2; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"AF110720", (others=>'0'), "0100"); -- map to same slv (in range)
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector); 
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report "E-70: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>

		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-72: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC7 ends <<";
	--------------------------------------
	--
	--E N D Test_case 07
	--
	--------------------------------------	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--//////////////////////////////////////////////
	
	
	
	--------------------------------------
	-- Test_case 08: 
	--------------------------------------
	-- single master read, valid address
	-- *** Test read from slave w/ base address 0 (mockup memory)
	-- Expected output, slvi:	correct selected slave
	-- Expected output, msti:	correct response from selected slave
	-- Expected error:			None
	--------------------------------------
		--report ">> TC8 starts <<";
	--------------------------------------
		
	-- Handshake-1: master requests (input for intercon)
		req_mst_idx <= 3; test_rddat <= x"A008800A";
		wait for clk_period; 
		genmst_req(msto(req_mst_idx), req_mst_idx, '0', x"00000000", (others=>'0'), "1000");
		wait for clk_period;
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector); 
		-- Handshake-2: 
		--wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-80: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-82: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC8 ends <<";
	--------------------------------------
	--
	--E N D Test_case 08
	--
	--------------------------------------	
	
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	
	--------------------------------------
	-- Test_case 51: 
	-- single master write
	-- Expected output, slvi:	address, data from granted master
	-- Expected output, msti:	ack from written slv
	-- Expected error:			no error
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC51 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		--test_wrdat <= x"332211AA"; 
		req_mst_idx <= 3; wait for clk_period;

		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A2000000", x"332211AA", "0100");
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-511: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		-- check led (hardcode check)
		wait for clk_period;
		assert led = x"22"
		report"E-511a: (wbicn) no led out"
		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-512: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC51 ends <<";
	--------------------------------------
	--
	--E N D Test_case 51
	--
	------------------------------------
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	
	--------------------------------------
	-- Test_case 52:
	-- single master write, valid address, different master from Test_case 51
	-- Expected output, slvi:	correct selected slave
	-- Expected output, msti:	correct response from selected slave
	-- Expected error:	None
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC52 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 2; wait for clk_period;

		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A2000000", x"332211AA", "0010");
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-521: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		-- check led (hardcode check)
		wait for clk_period;
		assert led = x"11"
		report"E-521a: (wbicn) no led out"
		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-522: (wbicn, fn.msti_chk_all)"
		severity error;
		
	--------------------------------------
	--report ">> TC52 ends <<";
	--------------------------------------
	--
	--E N D Test_case 52
	--
	--------------------------------------	

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////


	--------------------------------------
	-- Test_case 53: 
	-- single master write
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	no response for all msti
	-- Expected error:			invalid address map from slvi_chk
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC53 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 3; wait for clk_period;

		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"FF000000", x"332211AA", "0010");
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-531: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		-- check led (hardcode check)
--		wait for clk_period;
--		assert led = (others=>'-') -- ERR: internal compiler error. It can't be checked for '-'
--		report"E-531a: (wbicn) led should not be assigned"
--		severity error;
--		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-532: (wbicn, fn.msti_chk_all): invalid address map, it should return false"
		severity error;
	--------------------------------------
	--report ">> TC53 ends <<";
	--------------------------------------
	--
	--E N D Test_case 53
	--
	------------------------------------

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////

	--------------------------------------
	-- Test_case 54: 
	-- mult master, same address request
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	response to higher priority master
	-- Expected error:			no
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC54 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A2000000", x"AA3333AA", "0100");
		wait for clk_period; -- Need for msto assignment


		req_mst_idx <= 2; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A2000000", x"AA2222AA", "0100");
		wait for clk_period; -- Need for msto assignment

		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-541: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		-- check led (hardcode check)
		wait for clk_period;
		assert led = x"33" -- grant to m3
		report"E-541a: (wbicn) no led out"
		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-542: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC54 ends <<";
	--------------------------------------
	--
	--E N D Test_case 54
	--
	------------------------------------

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////

	--------------------------------------
	-- Test_case 55: 
	-- mutl master (highest granted master w/ invalid address)
	-- Expected output, slvi:	input for valid address
	-- Expected output, msti:	input for valid request master
	-- Expected error:			error invalid address for higher priority and no grant to lower priority although it's valid
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC55 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"FF000000", x"AA3333AA", "0100");
		wait for clk_period; -- Need for msto assignment


		req_mst_idx <= 0; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A2000000", x"AA2222AA", "0100");
		wait for clk_period; -- Need for msto assignment

		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-551: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
--		-- check led (hardcode check), can't check as  led will output as '-'
--		wait for clk_period;
--		assert led = x"22" -- grant to m3
--		report"E-551a: (wbicn) no led out"
--		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-552: (wbicn, fn.msti_chk_all): invalid address, it should return false"
		severity error;
	--------------------------------------
	--report ">> TC55 ends <<";
	--------------------------------------
	--
	--E N D Test_case 55
	--
	------------------------------------
	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////
	--------------------------------------
	-- Test_case 56: 
	-- single master write, valid address, inactive slave
	-- Expected output, slvi: no request for all slvi
	-- Expected output, msti: no request for all msti	
	-- Expected error:	Error, no address map
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC56 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 3; wait for clk_period;

		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"A4000000", x"AA5656AA", "0100");
		wait for clk_period; -- Need for msto assignment
		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert not slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-560: (wbicn, fn.slvi_chk_all): inactive slave, it should return false"
		severity error;

		-- Handshake-3: 
		-- <slvo>
--		-- check led (hardcode check), can't check as  led will output as '-'
--		wait for clk_period;
--		assert led1 = x"22" -- grant to m3
--		report"E-561a: (wbicn) no led out"
--		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert not msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-562: (wbicn, fn.msti_chk_all): inactive slave, it should return false"
		severity error;
	--------------------------------------
	--report ">> TC56 ends <<";
	--------------------------------------
	--
	--E N D Test_case 56
	--
	------------------------------------

	--///////////////////////////////////////////////////
	-- Quiet all masters
	--///////////////////////////////////////////////////
		wait for 5*clk_period;	
		req_mst_idx <= 0; wait for clk_period;
		msto <= (others=> wbm_out_none);
		wait for clk_period;
	--///////////////////////////////////////////////////

	--------------------------------------
	-- Test_case 57: 
	-- mult master, same address request
	-- Expected output, slvi:	no request for all slvi
	-- Expected output, msti:	response to higher priority master
	-- Expected error:			no
	--------------------------------------
		wait for 5*clk_period;	
		--report ">> TC57 starts <<";
	--------------------------------------
		-- Handshake-1: master requests (input for intercon)
		wait for clk_period;
		req_mst_idx <= 3; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"AE005733", x"AA3333AA", "0100");
		wait for clk_period; -- Need for msto assignment


		req_mst_idx <= 2; wait for clk_period;
		genmst_req(msto(req_mst_idx), req_mst_idx, '1', x"AE005722", x"AA2222AA", "0100");
		wait for clk_period; -- Need for msto assignment

		---------------------
		-- check slave & master
		---------------------
		--list_all_mst_req(msto, mst_mask_vector);
		
		-- Handshake-2: 
		wait for clk_period;
		assert slvi_chk_all(slvo, msto, slvi, mst_mask_vector)
		report"E-571: (wbicn, fn.slvi_chk_all)"
		severity error;

		-- Handshake-3: 
		-- <slvo>
		-- check led (hardcode check)
		wait for clk_period;
		assert led2 = x"33" -- grant to m3
		report"E-571a: (wbicn) no led out"
		severity error;
		
		-- Handshake-4: Evaluate msti, granted master can get the read data from selected slave correctly
		wait for clk_period;
		assert msti_chk_all(msti, msto, slvo, mst_mask_vector)
		report "E-572: (wbicn, fn.msti_chk_all)"
		severity error;
	--------------------------------------
	--report ">> TC57 ends <<";
	--------------------------------------
	--
	--E N D Test_case 57
	--
	------------------------------------

	wait for 5*clk_period;	
    
    assert false report "Simulation End" severity failure;
   end process;

--**************************************
--///////////////////////////////////////////////////
-- Quiet all masters
--///////////////////////////////////////////////////
--		wait for 5*clk_period;	
--		req_mst_idx <= 0; wait for clk_period;
--		msto <= (others=> wbm_out_none);
--		wait for clk_period;
--///////////////////////////////////////////////////
--	--------------------------------------
--	-- Test_case xx: 
--	-- [test_case_template, desc]
--	-- Expected output, slvi:	
--	-- Expected output, msti:	
--	-- Expected error:		
--	--------------------------------------
--		wait for 5*clk_period;	
--		--report ">> TCx starts <<";
--	--------------------------------------
--	
--	[put test code here]
--	--------------------------------------
--	--report ">> TCx ends <<";
--	--------------------------------------
--	--
--	--E N D Test_case xx
--	--
--	--------------------------------------	

END;
