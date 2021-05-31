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

 
entity core2wb_tb is
end core2wb_tb;
 
architecture behavior of core2wb_tb is

    component core2wb
    port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_dmem   : out  dmem_core;
		out_dmem  : in core_dmem;
		
		-- wb master port
		wmsti	:	in	wb_mst_in_type;
		wmsto	:	out	wb_mst_out_type
        );
    end component;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal out_dmem : core_dmem;	
   signal wmsti : wb_mst_in_type := wbm_in_none;

 	--Outputs
   signal in_dmem : dmem_core;
   signal wmsto : wb_mst_out_type;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
begin
 
	-- Instantiate the Unit Under Test (UUT)
	uut: core2wb
	port map(
		clk		=> clk,
		rst    	=> rst,
		
		in_dmem		=> in_dmem,
		out_dmem 	=> out_dmem,
		
		wmsti		=> wmsti,
		wmsto		=> wmsto
		
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
		rst <= '1';
		wait for clk_period*3.5;
		rst <= '0';
		wait;
	end process;

   -- Stimulus process
   stim_proc: process
   begin		
		--gencore2mem_req(out_dmem, req_acc, req_rdadr, req_rdsz, req_wradr, req_wrsz, req_wrdat);
		gencore2mem_req(out_dmem, NO_ACC, 
						--rd
						zadr32, "00", 
						--wr
						zadr32, "00", dc32);
		--genwb2core(wmsti, req_acc, req_rdsz, wmsto.sel, resp_rddat, READY);
		genwb2core(wmsti, NO_ACC, 
					"00", wmsto.sel, dc32, READY);
		wait for clk_period*5;
	--////////////////////////////////////////////
	--------------------------------------
	-- Test_case 00:
	--------------------------------------
	-- No request i.e. quiet test
	-- Expected output wmsto	: no response
	-- Expected output in_dmem	: no response
	-- Expected error:	No error
	--------------------------------------
	--	report ">> TC0 starts <<";
	--------------------------------------
	-- Handshake-1 (in): 
		gencore2mem_req(out_dmem,  --generated input for core2wbmo_chk
						NO_ACC, 
						--rd
						zadr32, "00", 
						--wr
						zadr32, "00", dc32);
		wait for clk_period;
		
	-- Handshake-2 (out):
		--wait for clk_period; 
		assert core2wbmo_chk(out_dmem.read_addr, out_dmem.read_size, out_dmem.write_data, 
							 wmsto, NO_ACC) -- put any address and any size
		report"E-00: msto.stb or msto.cyc should be inactive as there is no request"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					NO_ACC, "00", wmsto.sel, dc32, NREADY);
		wait for clk_period;
	
	-- Handshake-4 (out):
		--wait for clk_period; 
		assert wbmi2core_chk(in_dmem, 
							NO_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report "E-01: in_dmem.ready not active!"
		severity error;	
	--------------------------------------
	--report ">> TC0 ends <<";
	--------------------------------------
	--
	--E N D Test_case 00
	--
	--------------------------------------	
	--
	--------------------------------------
	-- Test_case 01:
	--------------------------------------
	-- Single read request
	-- Expected output wmsto	: request info from core should be the same as wb request
	-- Expected output in_dmem	: resp read_data from wb should be the same as incoming resp data to core module
	-- Expected error:	No error
	--------------------------------------
	--	report ">> TC1 starts <<";
	--------------------------------------
	--
	-- test 1A: immediate ack in next clk cycle from request
	--
	-- Handshake-1 (in):
		gencore2mem_req(out_dmem, 
						RD_ACC, 
						--rd
						x"A1000003", "00", 
						--wr
						zadr32, "00", dc32);
		wait for clk_period;
		
		
	-- Handshake-2 (out): verify rd and wr addr, wr data, request(stb, cyc)
		assert core2wbmo_chk(out_dmem.read_addr, out_dmem.read_size, out_dmem.write_data, 
							 wmsto, RD_ACC)
		report"E-10: msto.stb, msto.cyc should be active as there is rd request, and msto.we should = 0 (rd)"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, 
					RD_ACC, "00", wmsto.sel, x"D1AABBCC", READY);
		wait for clk_period;
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, 
							RD_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report "E-11: in_dmem.ready not active or read_data is wrong"
		severity error;	
	--
	-- test 1B: Non-immediate ack in next clk cycle from request
	--
	-- Handshake-1 (in):
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						RD_ACC, 
						--rd
						x"A1000003", "00", 
						--wr
						zadr32, "00", dc32);
		wait for clk_period;
		
	-- Handshake-2 (out): verify rd and wr addr, wr data, request(stb, cyc)
		assert core2wbmo_chk(out_dmem.read_addr, out_dmem.read_size, out_dmem.write_data, 
							 wmsto, RD_ACC)
		report"E-12: msto.stb, msto.cyc should be active as there is rd request, and msto.we should = 0 (rd)"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					RD_ACC, "00", wmsto.sel, x"D1AABBCC", NREADY);
		wait for clk_period;
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, RD_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-13: in_dmem.ready always active or read_data is wrong"
		severity error;		
	--
	-- test 1C: Different read_size (32b)
	--
	-- Handshake-1 (in):
		--req_rdsz <= "10"; --32b, remark: can't test since read_size has to be the same all the time (fixed in wb_gran)
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						RD_ACC, 
						--rd
						x"A1000003", "10",  --test diff siz
						--wr
						zadr32, "00", dc32);
		wait for clk_period;
		
		
	-- Handshake-2 (out): verify rd and wr addr, wr data, request(stb, cyc)
		assert core2wbmo_chk(out_dmem.read_addr, out_dmem.read_size, out_dmem.write_data, 
							 wmsto, RD_ACC) 
		report"E-14: msto.stb, msto.cyc should be active as there is rd request, and msto.we should = 0 (rd)"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					RD_ACC, "10", wmsto.sel, x"D1AABBCC", NREADY);
		wait for clk_period;
		
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, 
							RD_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-15: in_dmem.ready always active or read_data is wrong"
		severity error;	
	--------------------------------------
	--report ">> TC1 ends <<";
	--------------------------------------
	--
	--E N D Test_case 01
	--
	--------------------------------------		
	--
	--------------------------------------
	-- Test_case 02:
	--------------------------------------
	-- Single write request
	-- Expected output wmsto	: request info from core should be the same as wb request
	-- Expected output in_dmem	: get ack
	-- Expected error:	No error
	--------------------------------------
	--	report ">> TC2 starts <<";
	--------------------------------------
	--
	-- test 2A: immediate ack in next clk cycle from request
	--
	-- Handshake-1 (in):
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						WR_ACC, 
						--rd
						x"A2000000", "00", 
						--wr
						x"B2000003", "00", x"DB2200AA");
		wait for clk_period;
		
	-- Handshake-2 (out):
		assert core2wbmo_chk(out_dmem.write_addr, out_dmem.write_size, out_dmem.write_data, 
							 wmsto, WR_ACC) 
		report"E-20: msto.stb, msto.cyc and msto.we should be active as there is wr request"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					WR_ACC, "00", wmsto.sel, x"D2AABBCC", READY);
		wait for clk_period;
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, 
							WR_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-21: in_dmem.ready should be active"
		severity error;	
	--
	-- test 2B: Non-immediate ack in next clk cycle from request
	--
	-- Handshake-1 (in):
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						WR_ACC, 
						--rd
						 x"A2000000", "00", 
						--wr
						x"B2000003", "00", x"DB2200AA");
		wait for clk_period;
		
		
	-- Handshake-2 (out): verify rd and wr addr, wr data, request(stb, cyc)
		assert core2wbmo_chk(out_dmem.write_addr, out_dmem.write_size, out_dmem.write_data, 
							 wmsto, WR_ACC) 
		report"E-22: msto.stb, msto.cyc and msto.we should be active as there is wr request"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					WR_ACC, "00", wmsto.sel, x"D2AABBCC", NREADY);
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, 
							WR_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-23: in_dmem.ready always active or read_data is wrong"
		severity error;		
	--
	-- test 2C: Different write_size (32b)
	--
	-- Handshake-1 (in):
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						WR_ACC, 
						--rd
						x"A1000003", "00", 
						--wr
						x"B2000003", "10", x"DB2200AA");
		wait for clk_period;
		
	-- Handshake-2 (out): verify rd and wr addr, wr data, request(stb, cyc)
		assert core2wbmo_chk(out_dmem.write_addr, out_dmem.write_size, out_dmem.write_data, 
							 wmsto, WR_ACC) 
		report"E-24: msto.stb, msto.cyc and msto.we should be active as there is wr request"
		severity error;
		
	-- Handshake-3 (in):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					WR_ACC, "00", wmsto.sel, x"D2AABBCC", NREADY);
		wait for clk_period;
	
	-- Handshake-4 (out):
		assert wbmi2core_chk(in_dmem, 
							WR_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-25: in_dmem.ready always active or read_data is wrong"
		severity error;	
	--
	--------------------------------------
	--report ">> TC2 ends <<";
	--------------------------------------
	--
	--E N D Test_case 02
	--
	--------------------------------------		
	--
	--------------------------------------
	-- Test_case 03:
	--------------------------------------
	-- Simultaneous request i.e. write and read
	-- Expected output wmsto	: request info from core should be the same as wb request
	-- Expected output in_dmem	: in_dmem.ready is asserted only when the reading is done but msti.ack should be asserted after both write and read.
	-- Expected error:	No error
	--------------------------------------
	--	report ">> TC3 starts <<";
	--------------------------------------
	-- Handshake-1 (in):sim(wr)
		gencore2mem_req(out_dmem, --generated input for core2wbmo_chk
						SIM_ACC, 
						--rd
						x"A3000003", "00", 
						--wr
						x"B3000001", "00", x"DB3300AA");
		wait for clk_period;
	-------------------------------------------
	-- Handshake-2 (out):wr_req
		assert core2wbmo_chk(out_dmem.write_addr, out_dmem.write_size, out_dmem.write_data, 
							 wmsto, WR_ACC)  -- For simacc, write first
		report"E-30: msto.stb, msto.cyc and msto.we should be active as there is wr request"
		severity error;
		
		--clear request as we want to test only one sim transaction so far
		out_dmem.write_en <= '0'; out_dmem.read_en <= '0'; wait for clk_period;
		--end tmp clear
		
		--clear request as we want to test only one sim transaction so far
		--out_dmem.write_en <= '0'; out_dmem.read_en <= '0';
		--end tmp clear		
		--wait for 3*clk_period;
		
	-- Handshake-3 (in):wr_req
		genwb2core(wmsti, --generated input for wbmi2core_chk
					WR_ACC, "00", wmsto.sel, dc32, READY); --READY = out_mem2core.ready (wr is done)
					
		wait for 0.5*clk_period;
		
		-- Handshake-4 (out):read req is sent once mem_write is done (mem.ready = 1)
		--wait until wmsti.ack = '1';
		assert wbmi2core_chk(in_dmem, 
							SIM_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-31: Sim request (wr)- Wrong ready/ack"
		severity error;	
		
		--//////////////////
		--once wr_ack is sent, wb_intercon should deassert ack = 0 for read request that is just recently sent after wr_req is done
		wmsti.ack <= '0'; 
		wait for 0.5*clk_period; -- wait for ack to deassert
		--//////////////////
		
		-- Handshake-5 (out):rd_req
		assert core2wbmo_chk(out_dmem.read_addr, out_dmem.read_size, out_dmem.write_data, 
							 wmsto, RD_ACC) -- read after write is done
		report"E-32: sim request (rd): msto.stb, msto.cyc and msto.we should be (1, 1, 0)"
		severity error;
				
	-- Handshake-6 (out):
		genwb2core(wmsti, --generated input for wbmi2core_chk
					RD_ACC, "00", wmsto.sel, x"D3AABBCC", READY);
		wait for clk_period;
		
	-- Handshake-7 (out):rd_req
		assert wbmi2core_chk(in_dmem, 
							RD_ACC, wmsto.sel, wmsti.ack, wmsti.dat)
		report"E-33: wbmi2core_chk function: Wrong read data"
		severity error;	
	--------------------------------------
	--report ">> TC3 ends <<";
	--------------------------------------
	--
	--E N D Test_case 03
	--
	--------------------------------------		
		
--//////////////////////////////////////////////////		
	  assert false
	  report ">>>> Simulation beendet!"
      severity failure;
   end process;

end;
