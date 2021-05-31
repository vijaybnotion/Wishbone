-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
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

-- Whishbone Testing Package
package wb_tp is
	constant READY: std_logic 	:= '1'; --ready signal from mem which will be converted to msti.ack
	constant NREADY: std_logic 	:= '0';
	type access_type is (NO_ACC, RD_ACC, WR_ACC, SIM_ACC);
---------------------------------------------------------------
--
-- Prototype: Function
--
---------------------------------------------------------------

	-- function slvi_chk_quiet(
	-- 	signal		slvi_vector :	wb_slv_in_vector;
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "slvi_chk_quiet "
	-- ) return boolean;
	--
	-- function msti_chk_quiet(
	-- 	signal 		msti_vector : 	wb_mst_in_vector;
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "msti_chk_quiet "
	-- ) return boolean;
	--
	-- function msto_chk_quiet(
	-- 	signal 		msto_vector : 	wb_mst_out_vector;
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "msto_chk_quiet "
	-- ) return boolean ;
	--
	-- function core2wbmo_chk(
	-- 	signal		wbadr	:	std_logic_vector(31 downto 0);
	-- 	signal		wbsz	:	std_logic_vector(1 downto 0);
	-- 	signal		wbwrdat	:	std_logic_vector(31 downto 0);
	-- 	signal		msto 	:	wb_mst_out_type;
	-- 	constant 	we	 	:	access_type := NO_ACC;
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "core2wbmo_chk "
	-- ) return boolean ;
	--
	-- function slvi_chk_all(
	-- 	signal 		slvo 			: wb_slv_out_vector;  -- for address map check
	-- 	signal 		msto			: wb_mst_out_vector;
	-- 	signal		slvi	 		: wb_slv_in_vector;
	-- 	constant	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
	-- 	constant 	ScrnOut			: boolean := false;
	-- 	constant 	InstancePath	: string  := "slvi_chk_all "
	--
	-- ) return boolean;
	--
	-- function msti_chk_all (
	-- 	signal 		msti			: wb_mst_in_vector;
	-- 	signal		msto			: wb_mst_out_vector;
	-- 	signal		slvo			: wb_slv_out_vector; -- response from selected slave (if no addr map, no slave never been selected !!)
	-- 	constant	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
	-- 	constant 	ScrnOut			: boolean := false;
	-- 	constant 	InstancePath	: string  := "msti_chk_all "
	-- ) return boolean;
	--
	-- function wbmi2core_chk(
	-- 	signal		wb2core 	:	dmem_core;
	-- 	constant 	we	 		:	access_type := NO_ACC;
	-- 	signal		mo_sel		:	std_logic_vector(WB_SEL_WIDTH-1 downto 0);
	-- 	signal		mi_ack		:	std_logic;
	-- 	signal 		resp_rddat	:	std_logic_vector(memory_width - 1 downto 0);
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "wbmi2core_chk "
	-- ) return boolean;
	--
	-- function wb2mem_chk(
	-- 	signal		wb2mem 	:	core_dmem;
	-- 	signal		slvi	: wb_slv_in_type;
	-- 	constant 	we	 		:	access_type := NO_ACC;
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "wb2mem_chk "
	-- ) return boolean;
	--
	-- function gmst_idx_fn (
	-- 	signal		msto			: wb_mst_out_vector;
	-- 	constant 	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
	-- 	constant 	ScrnOut			: boolean := false;
	-- 	constant 	InstancePath	: string  := "gmst_idx_fn "
	-- ) return integer ;
	--
	-- function wbszconv_chk(
	-- 	signal 		size : in std_logic_vector(1 downto 0);
	-- 	constant 	ScrnOut		:	boolean := false;
	-- 	constant 	InstancePath:	string  := "wbszconv_chk"
	-- ) return boolean;

---------------------------------------------------------------
--
-- Prototype: Procedure
--
---------------------------------------------------------------
	procedure gencore2mem_req (
		signal	core2dmem 		:out	core_dmem;
		--
		constant req_acc		:in access_type := NO_ACC;
		constant rd_adr			:in		std_logic_vector(memory_width - 1 downto 0) := (others=>'0');
		constant rd_sz 			:in		std_logic_vector(1 downto 0) := "00";
		--
		constant wr_adr			:in		std_logic_vector(memory_width - 1 downto 0):= (others=>'0');
		constant wr_sz 			:in		std_logic_vector(1 downto 0):= "00";
		constant wr_dat			:in		std_logic_vector(memory_width - 1 downto 0):= (others=>'-');
		--
		constant ScrnOut		:in		boolean := false;
		constant InstancePath	:in		string  := "gencore2mem_req "

	);
--
	procedure genwb2core (
		signal		msti		:out	wb_mst_in_type;
		--
		constant 	req_acc		:in 	access_type := NO_ACC;
		constant 	rd_sz		:in		std_logic_vector(1 downto 0) := "00";
		constant	wb_sel		:in		std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		--
		constant 	read_data 	:in 	std_logic_vector(memory_width - 1 downto 0);
		constant	ready     	:in 	std_logic := '0';
		constant 	ScrnOut		:in		boolean := false;
		constant 	InstancePath	:in		string  := "genwb2core"
	);
--
	procedure genmst_req (
		signal	mst_out 		:out	wb_mst_out_type;
		constant req_idx	 	:in		integer  := 0;
		constant we				:in		std_logic;
		constant adr			:in		std_logic_vector(WB_ADR_WIDTH-1 downto 0);
		constant dat			:in		std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant sel 			:in		std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		constant ScrnOut		:in		boolean := false;
		constant InstancePath	:in		string  := "genmst_req "
	);
--
	procedure list_all_mst_req (
		signal	msto				: in wb_mst_out_vector;
		constant mst_mask_vector	: std_logic_vector(0 to NWBMST-1) := b"0000";
		constant ScrnOut			: boolean := false;
		constant InstancePath		: string  := "list_all_mst_req "
	);

	procedure generate_sync_wb_single_write(
		signal msto			: out wb_mst_out_type;
		signal slvo			: in wb_slv_out_type;
		signal clk			: in std_logic;
		signal writedata	: std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10";
		constant ADR_OFFSET	: integer := 0 -- Offset added to the access address
	);

	procedure generate_sync_wb_burst_write(
		signal msto			: out wb_mst_out_type;
		signal slvo			: in wb_slv_out_type;
		signal clk			: in std_logic;
		signal writedata	: std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant NUMBURSTS	: positive := 4;
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10";
		constant ADR_OFFSET	: integer := 0 -- Offset added to the access address
	);

	procedure generate_sync_wb_single_read(
		signal msto			: out wb_mst_out_type;  -- Slave input
		signal slvo			: in wb_slv_out_type; -- Slave output
		signal clk			: in std_logic;
		signal readdata		: out std_logic_vector(WB_PORT_SIZE -1 downto 0);
		constant ADR_OFFSET	: integer := 0; -- Offset added to the access address
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10"
	);

	procedure generate_sync_wb_burst_read(
		signal msto			: out wb_mst_out_type;  -- Slave input
		signal slvo			: in wb_slv_out_type; -- Slave output
		signal clk			: in std_logic;
		signal readdata		: out std_logic_vector(WB_PORT_SIZE -1 downto 0);
		constant NUMBURSTS	: positive := 4;
		constant ADR_OFFSET	: integer := 0; -- Offset added to the access address
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10"
	);

end wb_tp;

package body wb_tp is

---------------------------------------------------------------
-- Function: slvi_chk_quiet(slvi_vector)
--
-- Check if there is any request (cyc) to any slave
---------------------------------------------------------------
-- 	function slvi_chk_quiet(
-- 		signal		slvi_vector :	wb_slv_in_vector;
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "slvi_chk_quiet "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 		for i in 0 to NWBSLV-1 loop
-- 			if slvi_vector(i).cyc /= '0' then
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E00: slv(" & integer'image(i) & ") should not get any request !!!"));
-- 					writeline(output, L);
-- 				end if;
-- 				return false;
-- 			end if;
-- 		end loop;
--
-- 		return true;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: msti_chk_quiet(msti_vector)
-- --
-- -- Check if there is any request (ack) to any master
-- ---------------------------------------------------------------
-- 	function msti_chk_quiet(
-- 		signal msti_vector : wb_mst_in_vector;
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "msti_chk_quiet "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 		for i in 0 to NWBMST-1 loop
-- 			if msti_vector(i).ack /= '0' then
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E00: mst(" & integer'image(i) & ") should not get any ack !!!"));
-- 					writeline(output, L);
-- 				end if;
-- 				return false;
-- 			end if;
-- 		end loop;
--
-- 		return true;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: msto_chk_quiet(mst_mask_vector)
-- --
-- -- check if there is any master request (no need to assert error as it will be handle in fn caller)
-- -- Any master that is disable, wb_intercon will not assert the request (cyc) for that master
-- -- true = wb_intercon will consider that master as quiet as it either is inactive or sends no request (cyc= 0)
-- ---------------------------------------------------------------
-- 	function msto_chk_quiet(
-- 		signal		msto_vector :	wb_mst_out_vector;
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "msto_chk_quiet "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 		for i in 0 to NWBMST-1 loop
-- 			if msto_vector(i).cyc = '1' then
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E00: mst(" & integer'image(i) & ") should not send any request!!!"));
-- 					writeline(output, L);
-- 				end if;
-- 				return false;
-- 			end if;
-- 		end loop;
--
-- 		return true;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: core2wbmo_chk(wbadr, wbsz, wb_wrdat, msto, ACC)
-- -- This function checks control signals (stb, cyc, we) of core-to-wb conversion for single master(core)
-- -- Esp made for module "core2wb.vhd"
-- --
-- -- SIM_ACC handles same as WR_ACC
-- ---------------------------------------------------------------
-- 	function core2wbmo_chk(
-- 		signal		wbadr	:	std_logic_vector(31 downto 0);
-- 		signal		wbsz	:	std_logic_vector(1 downto 0);
-- 		signal		wbwrdat	:	std_logic_vector(31 downto 0);
-- 		signal		msto 	:	wb_mst_out_type;
-- 		constant 	we	 	:	access_type := NO_ACC;
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "core2wbmo_chk "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 			if we = RD_ACC then -- read
-- 				if 	msto.stb = '1' and msto.cyc = '1' and msto.we = '0' and
-- 					msto.adr = wbadr(memory_width - 1 downto WB_ADR_BOUND) and
-- 					msto.sel = gen_select(wbadr(1 downto 0), wbsz)
-- 					then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E00: Read req - "));
-- 						if not(msto.stb = '1' and msto.cyc = '1' and msto.we = '0') then
-- 							write(L, String'("(msto.stb, msto.cyc, msto.we) should be (1, 1, 0) "));
-- 						end if;
-- 						if (msto.adr /= wbadr(memory_width - 1 downto WB_ADR_BOUND)) then
-- 							write(L, String'("Mismatch addr: (msto.adr, wbadr) = (" &
-- 											hstr(msto.adr) & ", " &
-- 											hstr(wbadr(memory_width - 1 downto WB_ADR_BOUND)) & ") "));
-- 						end if;
-- 						if (msto.sel /= gen_select(wbadr(1 downto 0), wbsz)) then
-- 							write(L, String'("Mismatch sel: (msto.sel, wbadr(1:0)) = (" &
-- 											str(msto.sel) & ", " &
-- 											str(gen_select(wbadr(1 downto 0), wbsz)) & ")"));
-- 						end if;
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			elsif we = WR_ACC or we = SIM_ACC then -- write/sim
-- 				if 	msto.stb = '1' and msto.cyc = '1' and msto.we = '1' and
-- 					msto.adr = wbadr(memory_width - 1 downto WB_ADR_BOUND) and
-- 					msto.sel = gen_select(wbadr(1 downto 0), wbsz) and
-- 					msto.dat = enc_wb_dat(wbadr(1 downto 0), wbsz, wbwrdat) -- optional since mainly check from sel signal
-- 					then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						if we = WR_ACC then
-- 							write(L, String'("E01: Write req - "));
-- 						else
-- 							write(L, String'("E02: Simultaneous req - "));
-- 						end if;
-- 						if not(msto.stb = '1' and msto.cyc = '1' and msto.we = '1') then
-- 							write(L, String'("(msto.stb, msto.cyc, msto.we) should be (1, 1, 1) "));
-- 						end if;
-- 						if (msto.adr /= wbadr(memory_width - 1 downto WB_ADR_BOUND)) then
-- 							write(L, String'("Mismatch addr: (msto.adr, wbadr) = (" &
-- 											hstr(msto.adr) & ", " &
-- 											hstr(wbadr(memory_width - 1 downto WB_ADR_BOUND)) & ") "));
-- 						end if;
-- 						if (msto.sel /= gen_select(wbadr(1 downto 0), wbsz)) then
-- 							write(L, String'("Mismatch sel: (msto.sel, wbadr(1:0)) = (" &
-- 											str(msto.sel) & ", " &
-- 											str(gen_select(wbadr(1 downto 0), wbsz)) & ") "));
-- 						end if;
-- 						if (msto.dat /= enc_wb_dat(wbadr(1 downto 0), wbsz, wbwrdat)) then
-- 							write(L, String'("Mismatch data: (msto.dat, wb_wrdat) = (" &
-- 											hstr(msto.dat) & ", " &
-- 											hstr(enc_wb_dat(wbadr(1 downto 0), wbsz, wbwrdat)) & ")"));
-- 						end if;
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			else
-- 				if msto.stb = '0' and msto.cyc = '0' and msto.we = '0' then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E03: No request - (msto.stb, msto.cyc, msto.we) should be (0, 0, 0)"));
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			end if;
--
-- 		return false;
-- 	end function;
--
--
-- ---------------------------------------------------------------
-- -- Function: slvi_chk_all(slvo_vector, msto_vector, slvi_vector, mst_mask_vector, opt:instancepath, opt:scrnout)
-- --
-- -- slv_in check (out from wb_intercon)
-- -- This function checks if there is only selected slave from granted master gets the request signal (adr map) (cyc = 1)
-- -- Other slaves whose address is not mapped then should receive nothing (cyc = 0)
-- -- slv exist check by slvo(i).wbcfg(31 downto 24) must be x"FF" which will be called by wb_membar in order to reformat the mask addr of the slave
-- ---------------------------------------------------------------
-- 	function slvi_chk_all(
-- 		signal 		slvo 			: wb_slv_out_vector;  -- for address map check
-- 		signal 		msto			: wb_mst_out_vector;
-- 		signal		slvi	 		: wb_slv_in_vector;
-- 		constant	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
-- 		constant 	ScrnOut			: boolean := false;
-- 		constant 	InstancePath	: string  := "slvi_chk_all "
-- 	) return boolean is
-- 		variable madr, sadr		: std_logic_vector(31 downto 0) := (others=>'0'); -- for display purpose only
-- 		variable gmst_idx 		: integer range 0 to NWBMST-1;
-- 		variable ssel_idx 		: integer range 0 to NWBSLV-1;
-- 		variable slv_found		: boolean := false;
-- 		variable L				: Line;
-- 	begin
--
-- 		if msto_chk_quiet(msto) = true then -- No request from all master, No need to continue check slvi
-- 			if slvi_chk_quiet(slvi) = false then
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E00: No request from any master"));
-- 					writeline(output, L);
-- 				end if;
-- 				return false;
-- 			end if;
-- 		else
-- 			gmst_idx := gmst_idx_fn(msto, mst_mask_vector);
-- 			madr 		:= msto(gmst_idx).adr & "00";
--
-- 			-- compare, search for selected slave
-- 			for i in 0 to NWBSLV-1 loop
-- 				sadr := slvo(i).wbcfg(63 downto 34) & "00" ;
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'(
-- 						"[addr_cmp] slv(" & integer'image(i) &
-- 						") with its address: " & hstr(sadr)  &
-- 						" mst(" & integer'image(gmst_idx) &
-- 						") with its address: " & hstr(madr)));
-- 					writeline(output, L);
-- 				end if;
-- 				if (slvadrmap(slvo(i).wbcfg, msto(gmst_idx).adr) = true) and slvo(i).wbcfg(31 downto 24) = x"FF" then
-- 					slv_found 	:= true;
-- 					ssel_idx 	:= i;
-- 				end if;
--
-- 			end loop;
-- 			-- end compare
--
-- 			if (slv_found = true) then
-- 				if (slvi(ssel_idx).cyc /= '1') then
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E01: No request from master(" & integer'image(gmst_idx) &
-- 										") for slv(" & integer'image(ssel_idx) & ")"));
-- 						writeline(output, L);
-- 					end if;
-- 					return false;
-- 				end if;
-- 			else
-- 				if (slvi(ssel_idx).cyc /= '0') then
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E02: request address " & hstr(madr) & " not map with any slave, there should be no request signal " &
-- 										"from the granted master (" & integer'image(gmst_idx) & ")"));
-- 						writeline(output, L);
-- 					end if;
-- 					return false;
-- 				end if;
-- 			end if;
--
-- 		end if;
--
-- 		return true;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: msti_chk_all(msti_vector, msto_vector, slvo_vector, mst_mask_vector)
-- --
-- -- Check msti
-- -- This function check if there is only granted master get the ack from selected slave (ack = 1)
-- -- Other master should not receive asserted ack signal from all slave (ack = 0)
-- -- slv exist check by slvo(i).wbcfg(31 downto 24) must be x"FF" which will be called by wb_membar in order to reformat the mask addr of the slave
-- ---------------------------------------------------------------
-- 	function msti_chk_all (
-- 		signal 		msti			: wb_mst_in_vector;
-- 		signal		msto			: wb_mst_out_vector;
-- 		signal		slvo			: wb_slv_out_vector; -- response from selected slave (if no addr map, no slave never been selected !!)
-- 		constant	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
-- 		constant 	ScrnOut			: boolean := false;
-- 		constant 	InstancePath	: string  := "msti_chk_all "
-- 	) return boolean is
-- 		variable madr, sadr		: std_logic_vector(31 downto 0) := (others=>'0'); -- for display purpose only
-- 		variable gmst_idx 		: integer range 0 to NWBMST-1;
-- 		variable ssel_idx 		: integer range 0 to NWBSLV-1;
-- 		variable slv_found		: boolean := false;
-- 		variable L				: Line;
-- 	begin
--
-- 		if (msto_chk_quiet(msto) = true) then   -- No request from all master, No need to continue check slvi
-- 			if msti_chk_quiet(msti) = false then
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E00: No request from any master"));
-- 					writeline(output, L);
-- 				end if;
-- 				return false;
-- 			end if;
-- 		else
-- 			-- Get master index of granted master
-- 			gmst_idx 	:= gmst_idx_fn(msto, mst_mask_vector);
-- 			madr 		:= msto(gmst_idx).adr & "00";
--
-- 			-- compare, search for selected slave
-- 			for i in 0 to NWBSLV-1 loop
-- 				sadr := slvo(i).wbcfg(63 downto 34) & "00" ; -- for disp on report only
--
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("[addr_cmp] slv(" & integer'image(i) &
-- 						") with its address: " & hstr(sadr)  &
-- 						" mst(" & integer'image(gmst_idx) &
-- 						") with its address: " & hstr(madr)));
-- 					writeline(output, L);
-- 				end if;
--
-- 				if (slvadrmap(slvo(i).wbcfg, msto(gmst_idx).adr) = true) and slvo(i).wbcfg(31 downto 24) = x"FF" then
-- 					slv_found 	:= true;
-- 					ssel_idx 	:= i;  -- ssel_idx wont update immediately need to be next iteration ??
-- 				end if;
-- 			end loop;
-- 			-- end compare
--
-- 			for i in 0 to NWBMST-1 loop
-- 				if (i = gmst_idx) then
-- 					-- handle for no grant like this case m3 = disable, cyc = 1 and m2 = enable, cyc = 0 -> no grant (correct)  => no need to assert the error
-- 					-- for master that really request although it's inactive,
-- 					if msto(i).cyc = '1' then
-- 						if slv_found = true then
-- 							--if msti(i).ack /= '1' and slvo(ssel_idx).ack /= '1' and slv_found /= true then
-- 							if msti(i).ack /= '1' and slvo(ssel_idx).ack /= '1' then
-- 								if ScrnOut then
-- 								write(L, Now, Right, 15);
-- 								write(L, " : " & InstancePath);
-- 								write(L, String'("E01: no Ack to granted master(" & integer'image(i) & ") from slv (" & integer'image(ssel_idx) & ")"));
-- 								writeline(output, L);
-- 								end if;
-- 								return false;
-- 							end if;
-- 						else
-- 							if ScrnOut then
-- 								write(L, Now, Right, 15);
-- 								write(L, " : " & InstancePath);
-- 								write(L, String'("E02: request address " & hstr(madr) & " not map with any slave, there should be no request signal " &
-- 												"from the granted master (" & integer'image(gmst_idx) & ")"));
-- 								writeline(output, L);
-- 							end if;
-- 							return false;
-- 						end if;
-- 					end if;
-- 				else -- non grant master (ack must be 0)
-- 					if msti(i).ack /= '0' then
-- 						if ScrnOut then
-- 							write(L, Now, Right, 15);
-- 							write(L, " : " & InstancePath);
-- 							write(L, String'("E03: mst(" & integer'image(i) & ") should not have any response from any slv !!!"));
-- 							writeline(output, L);
-- 						end if;
-- 						return false;
-- 					end if;
-- 				end if;
-- 			end loop;
-- 		end if;
-- 		return true;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: wbmi2core_chk(wb2core, we, mo_sel, mo_dat, mi_ack, resp_rddat)
-- --
-- -- This function checks response signal conversion from memory(wb_msti) to core(in_dmem_core)
-- -- esp made for core2wb.vhd testing
-- -- *** For SIM_ACC, the function has not supported so far. It MUST be manually put either RD_ACC or WR_ACC
-- -- 1st ack of SIM_ACC, fn should verify as write (ack)
-- -- 2nd ack of SIM_ACC, fn should verify as read (ack, rd_dat)
-- ---------------------------------------------------------------
-- 	function wbmi2core_chk(
-- 		signal		wb2core 	:	dmem_core;
-- 		constant 	we	 		:	access_type := NO_ACC;
-- 		signal		mo_sel		:	std_logic_vector(WB_SEL_WIDTH-1 downto 0);
-- 		signal		mi_ack		:	std_logic;
-- 		signal  	resp_rddat	:	std_logic_vector(memory_width - 1 downto 0);
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "wbmi2core_chk "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 			if we = RD_ACC then -- read
-- 				if wb2core.ready = mi_ack and
-- 					wb2core.read_data = dec_wb_dat(mo_sel, resp_rddat)  -- optional since mainly check from sel signal
-- 					then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						if we = RD_ACC then
-- 							write(L, String'("E00: Read req - "));
-- 						else
-- 							write(L, String'("E00: Sim req (read) - "));
-- 						end if;
-- 						if wb2core.ready = mi_ack then
-- 							write(L, String'("Mismacth read data: msti.dat = " & hstr(wb2core.read_data) & ", resp_rddat = " & hstr(dec_wb_dat(mo_sel, resp_rddat))));
-- 						end if;
-- 						if wb2core.read_data /= dec_wb_dat(mo_sel, resp_rddat) then
-- 							write(L, String'(" Incorrect ack. ready = " & str(wb2core.ready) & ", msti.ack = "& str(mi_ack)));
-- 						end if;
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			elsif we = WR_ACC then -- write
-- 				if wb2core.ready = mi_ack then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E01: Write req - Incorrect ack. (ready = " & str(wb2core.ready) & ", msti.ack = "& str(mi_ack)));
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			elsif we = SIM_ACC then -- check only SIMACC_WR and for SIMACC_RD, use same as RD_ACC
-- 				if wb2core.ready = '0' and mi_ack = '1' then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E02: Write req - Incorrect ack. (in_dmem.ready, msti.ack) should be = (0, 1) since the request is not complete yet"));
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			else -- we = NO_ACC
-- 				if wb2core.ready = '1' then
-- 					return true;
-- 				else
-- 					if ScrnOut then
-- 						write(L, Now, Right, 15);
-- 						write(L, " : " & InstancePath);
-- 						write(L, String'("E03: No request - wb2core.ready should always assert"));
-- 						writeline(output, L);
-- 					end if;
-- 				end if;
-- 			end if;
--
-- 		return false;
-- 	end function;
-- ---------------------------------------------------------------
-- -- Function: wb2mem_chk(wb2mem, slvi, we)
-- --
-- -- This function checks control signals (stb, cyc, we) of wb-to-mem conversion for single slave(memory)
-- -- Esp made for mem2wb.vhd testing
-- ---------------------------------------------------------------
-- 	function wb2mem_chk(
-- 		signal		wb2mem 	:	core_dmem;
-- 		signal		slvi	:	wb_slv_in_type;
-- 		constant 	we	 		:	access_type := NO_ACC;
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "wb2mem_chk "
-- 	) return boolean is
-- 		variable 	L:	Line;
-- 	begin
-- 		if we = RD_ACC then -- read
-- 			if 	wb2mem.read_en = '1' and
-- 				wb2mem.read_addr(WB_ADR_WIDTH-1 downto WB_ADR_BOUND) = slvi.adr and
-- 				wbszconv_chk(wb2mem.read_size) and
-- 				wb2mem.write_en = '0'	then
-- 				return true;
-- 			else
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'(	"E00: Read req - wrong conversion from WB to MEMORY. wb_adr = " &
-- 										hstr(wb2mem.read_addr) &
-- 										" ,slvi.adr = "  &
-- 										hstr(slvi.adr) &
-- 										" ,wb.read_en = "
-- 										));
-- 					writeline(output, L);
-- 				end if;
-- 			end if;
-- 		elsif we = WR_ACC then -- write
-- 				if 	wb2mem.write_en = '1' and
-- 					wb2mem.write_addr(WB_ADR_WIDTH-1 downto WB_ADR_BOUND) = slvi.adr and
-- 					wbszconv_chk(wb2mem.write_size) and
-- 					wb2mem.write_data = dec_wb_dat(slvi.sel, slvi.dat) and
-- 					wb2mem.read_en = '0'	then
-- 				return true;
-- 			else
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E01: Write req - "));
-- 					if wb2mem.write_en /= '1' then
-- 						write(L, String'("Write_en should be active, "));
-- 					end if;
--
-- 					writeline(output, L);
-- 				end if;
-- 			end if;
-- 		elsif we = NO_ACC then
-- 			if 	wb2mem.read_en = '0' and
-- 				wb2mem.write_en = '0' then
-- 				return true;
-- 			else
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E02: No request"));
-- 					writeline(output, L);
-- 				end if;
-- 			end if;
-- 		else
-- 			if 	wb2mem.read_en = '1' and
-- 				wb2mem.write_en = '1' then
-- 				return true;
-- 			else
-- 				if ScrnOut then
-- 					write(L, Now, Right, 15);
-- 					write(L, " : " & InstancePath);
-- 					write(L, String'("E03: Sim request"));
-- 					writeline(output, L);
-- 				end if;
-- 			end if;
-- 		end if;
--
-- 		return false;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: gmst_idx = gmst_idx_fn(msto, mst_mask_vector, grant)
-- --
-- -- return: index of master that get the grant (highest priority/index number)
-- -- 		   this index get the highest priority w/o checking active status (mst_mask_vector) ???
-- ---------------------------------------------------------------
-- 	function gmst_idx_fn (
-- 		signal		msto			: wb_mst_out_vector;
-- 		constant 	mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
-- 		constant 	ScrnOut			: boolean := false;
-- 		constant 	InstancePath	: string  := "gmst_idx_fn "
-- 	) return integer is
-- 		variable gnt_idx 	:integer range 0 to NWBMST-1;
-- 		variable L				: Line;
-- 	begin
--
-- 		for i in 0 to NWBMST-1 loop
-- 			if(msto(i).cyc='1' and mst_mask_vector(i) = '1' )then
-- 				gnt_idx := i;
-- 			end if;
-- 		end loop;
--
-- 		if ScrnOut then
-- 			write(L, Now, Right, 15);
-- 			write(L, " : " & InstancePath);
-- 			write(L, String'("master grant idx: "& integer'image(gnt_idx)));
-- 			writeline(output, L);
-- 		end if;
--
-- 		return gnt_idx;
-- 	end function;
--
-- ---------------------------------------------------------------
-- -- Function: wbszconv_chk = wbszconv_chk(size)
-- --
-- -- return:
-- --
-- -- remark: Internal use in wb_tp itself
-- ---------------------------------------------------------------
-- 	function wbszconv_chk(
-- 		signal 		size : in std_logic_vector(1 downto 0);
-- 		constant 	ScrnOut		:	boolean := false;
-- 		constant 	InstancePath:	string  := "wbszconv_chk"
-- 	) return boolean is
-- 			variable 	L:	Line;
-- 		begin
-- 			case WB_PORT_GRAN is
-- 			when 8 =>
-- 				if size = "00" then return true; end if;
-- 			when 16 =>
-- 				if size = "01" then return true; end if;
-- 			when 32 =>
-- 				if size = "10" then return true; end if;
-- 			when 64 =>
-- 				if size = "11" then return true; end if;
-- 			end case;
--
-- 			if ScrnOut then
-- 				write(L, Now, Right, 15);
-- 				write(L, " : " & InstancePath);
-- 				write(L, String'("E00: wb port gran doesn't match with port gran of core or memory"));
-- 				writeline(output, L);
-- 			end if;
--
-- 			return false;
-- 	end function;
--end commenting
---------------------------------------------------------------
-- Function: corewb_conv_chk(core2wb_in, msto)
--
---------------------------------------------------------------
--	function corewb_conv_chk(
--		core2wb_in					: core_dmem;
--		msto						: wb_mst_out_type;
--		constant 	InstancePath	: string  := "corewb_conv_chk";
--		constant 	ScrnOut			: boolean := false
--	) return boolean is
--		variable result		: boolean := false;
--		variable L			: Line;
--	begin
--
--		--check enable
--
--
--		write_data : std_logic_vector(memory_width - 1 downto 0);
--		write_addr : std_logic_vector(memory_width - 1 downto 0);
--		write_size : std_logic_vector(1 downto 0);
--		write_en   : std_logic;
--
--
--		read_addr : std_logic_vector(memory_width - 1 downto 0);
--		read_size : std_logic_vector(1 downto 0);
--		read_en   : std_logic;
--
--		if ScrnOut then
--			write(L, Now, Right, 15);
--			write(L, " : " & InstancePath);
--			write(L, String'(" xxxxx"));
--			writeline(output, L);
--			end if;
--			return false;
--		end if;
--
--
--		return result;
--	end function;
--

---------------------------------------------------------------
-- Procedure: gencore2mem_req(req_acc, rd_adr, rd_sz, wr_adr, wr_sz, wr_dat)
-- 			  gencore2mem_req(XX_ACC, x"AAAAAAAA", "00", x"AAAAAAAA", "00", x"DDDDDDDD")
--
---------------------------------------------------------------
	procedure gencore2mem_req (
		signal	core2dmem 		:out	core_dmem;
		--
		constant req_acc		:in 	access_type := NO_ACC;
		constant rd_adr			:in		std_logic_vector(memory_width - 1 downto 0) := (others=>'0');
		constant rd_sz 			:in		std_logic_vector(1 downto 0) := "00";
		--
		constant wr_adr			:in		std_logic_vector(memory_width - 1 downto 0):= (others=>'0');
		constant wr_sz 			:in		std_logic_vector(1 downto 0):= "00";
		constant wr_dat			:in		std_logic_vector(memory_width - 1 downto 0):= (others=>'-');
		--
		constant ScrnOut		:in		boolean := false;
		constant InstancePath	:in		string  := "gencore2mem_req "
	)	is
		variable L:                   	Line;
	begin

			if ScrnOut then
				write(L, Now, Right, 15);
				write(L, " : " & InstancePath);
				case(req_acc) is
					when RD_ACC =>
						write(L, String'("RD request: adr: " & hstr(rd_adr)));
					when WR_ACC =>
						write(L, String'("WR request: adr: " & hstr(wr_adr) & " WR data: " & hstr(wr_dat)));
					when SIM_ACC =>
						write(L, String'("SIM, RD request: adr: " & hstr(rd_adr)));
						write(L, String'("SIM, WR request: adr: " & hstr(wr_adr) & " WR data: " & hstr(wr_dat)));
					when others =>
						write(L, String'("NO request"));
				end case;
				writeline(output, L);
			end if;

			case(req_acc) is
			when RD_ACC =>
				core2dmem.read_en <= '1'; core2dmem.write_en <= '0';
			when WR_ACC =>
				core2dmem.read_en <= '0'; core2dmem.write_en <= '1';
			when SIM_ACC =>
				core2dmem.read_en <= '1'; core2dmem.write_en <= '1';
			when others =>
				core2dmem.read_en <= '0'; core2dmem.write_en <= '0';
			end case;

			-- leave data and adr as it is, although enable = 0
			core2dmem.read_addr 	<= rd_adr;
			core2dmem.read_size 	<= rd_sz;
			--
			core2dmem.write_addr 	<= wr_adr;
			core2dmem.write_size 	<= wr_sz;
			core2dmem.write_data 	<= wr_dat;

	end gencore2mem_req;

---------------------------------------------------------------
--  Procedure: genwb2core(msti, req_acc, rd_sz, wb_sel, read_data, ready)
--
--	similar to function 'dec_wb_dat' in wishbone.vhd
---------------------------------------------------------------
	procedure genwb2core (
		signal		msti		:out	wb_mst_in_type;
		--
		constant 	req_acc		:in 	access_type := NO_ACC;
		constant 	rd_sz		:in		std_logic_vector(1 downto 0) := "00";
		constant	wb_sel		:in		std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		--
		constant 	read_data 	:in 	std_logic_vector(memory_width - 1 downto 0);
		constant	ready     	:in 	std_logic := '0';
		constant 	ScrnOut		:in		boolean := false;
		constant 	InstancePath	:in		string  := "genwb2core"
	)	is
		variable L		:Line;
		variable mi		:wb_mst_in_type;
	begin
			mi.ack 	:= ready;
			--gen data based on sel and size
			mi.dat	:= (others=>'0');
			if req_acc = RD_ACC then
			--read
				case (rd_sz) is
				when "00" =>
					mi.dat( 7 downto  0) := read_data( 7 downto  0);
					if		wb_sel = "0001" then	mi.dat( 7 downto  0) := read_data( 7 downto  0);
					elsif 	wb_sel = "0010" then	mi.dat(15 downto  8) := read_data(15 downto  8);
					elsif 	wb_sel = "0100" then	mi.dat(23 downto 16) := read_data(23 downto 16);
					elsif 	wb_sel = "1000" then	mi.dat(31 downto 24) := read_data(31 downto 24);
					else 					 		mi.dat			   := (others=>'0');
					end if;
				when "01" =>
					if		wb_sel = "0001" then	mi.dat(15 downto  0) := read_data(15 downto  0);
					elsif 	wb_sel = "0010" then	mi.dat(31 downto 16) := read_data(31 downto 16);
					elsif 	wb_sel = "0011" then	mi.dat(23 downto  8) := read_data(23 downto  8);
					else 					 		mi.dat			   := (others=>'0');
					end if;
				when "10" =>
					mi.dat 	:= read_data;
				when others =>
					mi.dat	:= (others=>'0');
				end case;

				if ScrnOut then
					write(L, Now, Right, 15);
					write(L, " : " & InstancePath);
					write(L, String'("RD resp: RD data: " &
										hstr(mi.dat) & ", sel: " &
										str(wb_sel) & ", rd_sz: " &
										str(rd_sz) & ", ack = " &
										str(mi.ack)));
					writeline(output, L);
				end if;

			else
				mi.dat	:= (others=>'0');
				if ScrnOut then
					write(L, Now, Right, 15);
					write(L, " : " & InstancePath);
					write(L, String'("WR resp: ack = " & str(mi.ack)));
					writeline(output, L);
				end if;

			end if;

			msti <= mi;


	end genwb2core;
---------------------------------------------------------------
-- Procedure: genmst_req(msto(req_mst_idx),req_mst_idx, we, adr, dat, sel)
--
-- Master read/Write req function for wb_intercon_tb
-- CAUTION: input slave address as 32 bits instaed of 30 bits to be readable
---------------------------------------------------------------
	procedure genmst_req (
		signal	mst_out 		:out	wb_mst_out_type;
		constant req_idx	 	:in		integer  := 0;
		constant we				:in		std_logic;
		constant adr			:in		std_logic_vector(WB_ADR_WIDTH-1 downto 0);
		constant dat			:in		std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant sel 			:in		std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		constant ScrnOut		:in		boolean := false;
		constant InstancePath	:in		string  := "genmst_req "
	)	is
		variable L:                   	Line;
	begin
		if ScrnOut then
			write(L, Now, Right, 15);
			write(L, " : " & InstancePath);
			write(L, String'("Master(" & integer'image(req_idx) &") Request address: " & hstr(adr)));
			writeline(output, L);
		end if;

		mst_out 		<= wbm_out_none; -- initial
		mst_out.adr 	<= adr(31 downto 2);
		mst_out.sel		<= sel;
		mst_out.stb		<= '1';
		mst_out.cyc		<= '1';
--		mst_out.wbidx	<= req_idx;

		if we = '0' then -- read
			mst_out.we	<= '0';
			mst_out.dat <= (others=>'-');
		else -- write
			mst_out.we	<= '1';
			mst_out.dat <= dat;
		end if;
	end genmst_req;

---------------------------------------------------------------
-- Procedure: list_all_mst_req(msto_vector, mst_mask_vector);
--
-- Utility procedure to list all master request(s)
---------------------------------------------------------------
	procedure list_all_mst_req (
		signal	msto				: in wb_mst_out_vector;
		constant mst_mask_vector	: std_logic_vector(0 to NWBMST-1) := b"0000";
		constant ScrnOut			: boolean := false;
		constant InstancePath		: string  := "list_all_mst_req "
	) is
		variable mstat :integer range 0 to 1 := 0; -- for disp purpose
		variable madr : std_logic_vector(31 downto 0) := (others=> '0');
		variable noreq: boolean := true;
		variable L				: Line;
	begin

		for i in 0 to NWBMST-1 loop
			if msto(i).cyc = '1' then
				if mst_mask_vector(i) = '0' then
					mstat := 0;
				else
					mstat := 1;
				end if;
				madr := msto(i).adr & "00";
				if ScrnOut then
					write(L, Now, Right, 15);
					write(L, " : " & InstancePath);
					write(L, String'("Request mst(" & integer'image(i) & "), addr: " & hstr(madr) & " with status:  " & integer'image(mstat)));
					writeline(output, L);
				end if;
				noreq := false;
			end if;
		end loop;

		if noreq and ScrnOut then
			write(L, Now, Right, 15);
			write(L, " : " & InstancePath);
			write(L, String'("No request"));
			writeline(output, L);
		end if;

	end  list_all_mst_req;

	procedure generate_sync_wb_single_write(
		signal msto			: out wb_mst_out_type;
		signal slvo			: in wb_slv_out_type;
		signal clk			: in std_logic;
		signal writedata	: std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant size		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10";
		constant adr_offset	: integer := 0 -- Offset added to the access address
	) is
		variable adr	: std_logic_vector(31 downto 0);
		variable sel	: std_logic_vector(WB_SEL_WIDTH downto 0);
	begin
		adr := slvo.wbcfg(63 downto 32);
		adr := std_logic_vector(unsigned(adr) + adr_offset);

		--continue if rising edge active, else wait for it
		--allows subsequent procedure calls without waiting for next edge
		if not rising_edge(clk) then
			wait until rising_edge(clk);
		end if;

		msto		<= wbm_out_none;
		msto.cyc	<= '1';
		msto.stb	<= '1';
		msto.we		<= '1';
		msto.sel	<= gen_select(adr(1 downto 0),size);
		msto.adr	<= adr(31 downto 2);
		msto.dat	<= enc_wb_dat(adr(1 downto 0),size,writedata);

		wait until rising_edge(clk);
		wait until slvo.ack = '1' for 100 ns;
		assert slvo.ack = '1' report "Slave did not ACK the write properly within 10 wait states";

		wait until rising_edge(clk);

		msto.cyc <= '0';
		msto.stb <= '0';
		msto.we  <= '-';
		msto.sel <= (others=>'-');
		msto.dat <= (others=>'-');
		msto.adr <= (others=>'-');
	end procedure;

	procedure generate_sync_wb_burst_write(
		signal msto			: out wb_mst_out_type;
		signal slvo			: in wb_slv_out_type;
		signal clk			: in std_logic;
		signal writedata	: std_logic_vector(WB_PORT_SIZE-1 downto 0);
		constant NUMBURSTS	: positive := 4;
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10";
		constant ADR_OFFSET	: integer := 0 -- Offset added to the access address
	) is
		variable adr	: std_logic_vector(31 downto 0);
		variable sel	: std_logic_vector(WB_SEL_WIDTH downto 0);
		variable i		: integer := 1;
	begin
		adr := slvo.wbcfg(63 downto 32);
		adr := std_logic_vector(unsigned(adr) + ADR_OFFSET);

		--continue if rising edge active, else wait for it
		--allows subsequent procedure calls without waiting for next edge
		if not rising_edge(clk) then
			wait until rising_edge(clk);
		end if;

		msto		<= wbm_out_none;
		msto.cyc	<= '1';
		msto.stb	<= '1';
		msto.we		<= '1';
		msto.sel	<= gen_select(adr(1 downto 0),SIZE);
		msto.adr	<= adr(31 downto 2);
		msto.dat	<= enc_wb_dat(adr(1 downto 0),SIZE,writedata);
		msto.cti	<= "010";

		while i /= NUMBURSTS loop
			wait until rising_edge(clk);
			wait until slvo.ack = '1' for 1 ps;
			adr			:= std_logic_vector(unsigned(adr) + 4);
			msto.adr	<= adr(31 downto 2);
			msto.dat	<= enc_wb_dat(adr(1 downto 0),SIZE,std_logic_vector(unsigned(writedata)+i));
			i := i+1;
		end loop;

		msto.cti	<= "111";
		wait until rising_edge(clk);
		msto.stb	<= '0';
		msto.cti	<= (others => '-');
		msto.dat	<= (others => '-');
		msto.sel	<= (others => '-');
		wait until rising_edge(clk);
		if slvo.ack = '1' then
			msto		<= wbm_out_none;
		end if;

	end procedure;

	procedure generate_sync_wb_single_read(
		signal msto			: out wb_mst_out_type;  -- Slave input
		signal slvo			: in wb_slv_out_type; -- Slave output
		signal clk			: in std_logic;
		signal readdata		: out std_logic_vector(WB_PORT_SIZE -1 downto 0);
		constant adr_offset	: integer := 0; -- Offset added to the access address
		constant size		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10"
	) is
		variable sel : std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		variable adr : std_logic_vector(31 downto 0);
	begin
		adr := slvo.wbcfg(63 downto 32);
		adr := std_logic_vector(unsigned(adr) + adr_offset);
		sel := gen_select(adr(1 downto 0),size);

		--allow subsequent reads
		if not rising_edge(clk) then
			wait until rising_edge(clk);
		end if;

		msto		<= wbm_out_none;
		msto.cyc	<= '1';
		msto.stb	<= '1';
		msto.we		<= '0';
		msto.sel	<= sel;
		msto.adr	<= adr(31 downto 2);

		wait until rising_edge(clk);
		wait until slvo.ack='1' for 100 ns;
		assert slvo.ack='1' report "Slave did not ACK the read properly within 10 wait states";
		if slvo.ack='1' then
			readdata <= dec_wb_dat(sel,slvo.dat);
		else
			readdata <= (others=>'X');
		end if;
		wait until rising_edge(clk);
		msto.cyc <= '0';
		msto.stb <= '0';
		msto.we  <= '-';
		msto.sel <= (others=>'-');
		msto.dat <= (others=>'-');
		msto.adr <= (others=>'-');
	end procedure;

	procedure generate_sync_wb_burst_read(
		signal msto			: out wb_mst_out_type;  -- Slave input
		signal slvo			: in wb_slv_out_type; -- Slave output
		signal clk			: in std_logic;
		signal readdata		: out std_logic_vector(WB_PORT_SIZE -1 downto 0);
		constant NUMBURSTS	: positive := 4;
		constant ADR_OFFSET	: integer := 0; -- Offset added to the access address
		constant SIZE		: std_logic_vector(WB_ADR_BOUND-1 downto 0) := "10"
	) is
		variable sel : std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		variable adr : std_logic_vector(31 downto 0);
		variable i : integer := 1;
	begin
		adr := slvo.wbcfg(63 downto 32);
		adr := std_logic_vector(unsigned(adr) + ADR_OFFSET);
		sel := gen_select(adr(1 downto 0),SIZE);

		--allow subsequent reads
		if not rising_edge(clk) then
			wait until rising_edge(clk);
		end if;

		msto		<= wbm_out_none;
		msto.cyc	<= '1';
		msto.stb	<= '1';
		msto.we		<= '0';
		msto.sel	<= sel;
		msto.adr	<= adr;
		msto.cti	<= "010";

		while i /= NUMBURSTS loop
			wait until rising_edge(clk);
				adr			:= std_logic_vector(unsigned(adr) + 4);
				msto.adr	<= adr(31 downto 2);
				readdata 	<= dec_wb_dat(sel,slvo.dat);
				i := i+1;
		end loop;

		msto.cti	<= "111";
		wait until rising_edge(clk);
		msto.stb	<= '0';
		msto.cti	<= (others => '-');
		msto.dat	<= (others => '-');
		msto.sel	<= (others => '-');
		if slvo.ack = '1' then
			readdata	<= dec_wb_dat(sel,slvo.dat);
		end if;
		wait until rising_edge(clk);
		msto		<= wbm_out_none;
	end procedure;

end wb_tp;
