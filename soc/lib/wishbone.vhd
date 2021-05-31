-- See the file "LICENSE" for the full license governing this code. --

-- This is a Package defining the Internal Interfaces and Constants of the Bus Bridge
-- Signal naming conventions: input signals end with _i, output signals end with _o
-- Signals inside of Records do not have these endings
--
-- Constants names are written uppercase

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.lt16x32_global.all;

package wishbone is
	constant DEBUG: boolean := true;

	type endian_type is (big, little);

	-- Configuration of the Wishbone Bus (every non-derived constant must be a power of 2)
	constant WB_PORT_SIZE:  integer     := 32; 			-- Data Port Bitwidth
	constant WB_PORT_GRAN:  integer     := 8;			-- Data Port Granularity (Bitsize of smallest addressable unit)
	constant WB_MAX_OPSIZE: integer     := WB_PORT_SIZE;	-- Maximum Operand Size
	constant WB_ENDIANESS:  endian_type := big;			-- Endianess, 0 => Little Endian, 1 => Big Endian
	constant WB_ADR_WIDTH:	integer     := 32;			-- Length of Bus Addresses
	constant WB_ADR_BOUND:	integer     := 2; 			-- lower boundary of Address, derived from PORT_SIZE and PORT_GRAN ( log2(SEL_WIDTH) ), number of Adress Bits which can not be used
	constant WB_SEL_WIDTH:  integer     := WB_PORT_SIZE/WB_PORT_GRAN; 			-- Bitwidth of the select signal (sel_I/O), number of min size units that fit on data bus (WB_PORT_SIZE/WB_PORT_GRAN)

	constant NWBMST:	integer	:=4; --Number of Wishbone master connectors on the Interconnect
	constant NWBSLV:	integer :=16; --Number of Wishbone slave connectors on the Interconnect

	subtype wb_addr_type			is std_logic_vector(WB_ADR_WIDTH-1 downto WB_ADR_BOUND);

	constant zadr : wb_addr_type := (others => '0');
	constant zdat : std_logic_vector(WB_PORT_SIZE-1 downto 0):= (others=>'0');
	constant zslv22: std_logic_vector(21 downto 0) := (others=>'0');

	constant zadr32 : std_logic_vector(31 downto 0):= (others=>'0');
	constant dc32: std_logic_vector(31 downto 0):= (others=>'-');

--
--	----------------------------------------------------------------------------------------
--	-- master:data tag signals (input and output)
--	type wb_tag_mst_i_data_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_mst_o_data_type is record
--		dc: std_logic;
--	end record;
--
--	-- address tag signals (input and output)
--	type wb_tag_mst_i_adr_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_mst_o_adr_type is record
--		dc: std_logic;
--	end record;
--
--	-- cycle tag signals (input and output)
--	type wb_tag_mst_i_cyc_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_mst_o_cyc_type is record
--		dc: std_logic;
--	end record;
--	-- slv:data tag signals (input and output)
--	type wb_tag_slv_i_data_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_slv_o_data_type is record
--		dc: std_logic;
--	end record;
--
--	-- address tag signals (input and output)
--	type wb_tag_slv_i_adr_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_slv_o_adr_type is record
--		dc: std_logic;
--	end record;
--
--	-- cycle tag signals (input and output)
--	type wb_tag_slv_i_cyc_type is record
--		dc: std_logic;
--	end record;
--
--	type wb_tag_slv_o_cyc_type is record
--		dc: std_logic;
--	end record;
--	----------------------------------------------------------------------------------------
--	-- tag types
--	----------------------------------------------------------------------------------------
--	-- master input tag signals
--	type wb_tag_mst_i_type is record
--		tgd: wb_tag_mst_i_data_type;
--		tga: wb_tag_mst_i_adr_type;
--		tgc: wb_tag_mst_i_cyc_type;
--	end record;
--
--	-- master output tag signals
--	type wb_tag_mst_o_type is record
--		tgd: wb_tag_mst_o_data_type;
--		tga: wb_tag_mst_o_adr_type;
--		tgc: wb_tag_mst_o_cyc_type;
--	end record;
--
--	-- slave input tag signals
--	type wb_tag_slv_i_type is record
--		tgd: wb_tag_slv_i_data_type;
--		tga: wb_tag_slv_i_adr_type;
--		tgc: wb_tag_slv_i_cyc_type;
--	end record;
--
--	-- slave output tag signals
--	type wb_tag_slv_o_type is record
--		tgd: wb_tag_slv_o_data_type;
--		tga: wb_tag_slv_o_adr_type;
--		tgc: wb_tag_slv_o_cyc_type;
--	end record;
--
--	----------------------------------------------------------------------------------------
--	-- Wishbone Clock and Reset
--	type wb_sys_type is record
--		rst: std_logic;
--		clk: std_logic;
--	end record;

	subtype wb_config_type is std_logic_vector(63 downto 0);

	--Cycle type identifier:
	--000: Classic cycle, 001: Constant address burst, 010: Incrementing burst
	--111: End-of-Burst
	subtype wb_tag_cti_io is std_logic_vector(2 downto 0);

	--Burst type extension:
	--00: Linear burst, 01: 4-beat wrap burst
	--10: 8-beat wrap burst, 11: 16-beat wrap burst
	subtype wb_tag_bte_io is std_logic_vector(1 downto 0);

	-- Wishbone Master Input Signals
	type wb_mst_in_type is record
		dat:   std_logic_vector(WB_PORT_SIZE-1 downto 0);
		ack:   std_logic;
		--tagn:  wb_tag_mst_i_type;
		--stall: std_logic;
		--err:   std_logic;
		--rty:   std_logic;
	end record;

	-- Wishbone Master Output Signals
	type wb_mst_out_type is record
		adr : wb_addr_type;
		dat : std_logic_vector(WB_PORT_SIZE-1 downto 0);
		we  : std_logic;
		sel : std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		stb : std_logic;
		cyc : std_logic;
		cti	: wb_tag_cti_io;
		bte	: wb_tag_bte_io;
		--tagn: wb_tag_mst_o_type;
		--lock: std_logic;
		--wbcfg:  wb_config_type;	 		-- memory access reg.
	end record;

	-- Wishbone Slave Input Signals
--	type wb_slv_in_type is record
--		adr : wb_addr_type;
--		dat : std_logic_vector(WB_PORT_SIZE-1 downto 0);
--		we  : std_logic;
--		sel : std_logic_vector(WB_SEL_WIDTH-1 downto 0);
--		stb : std_logic;
--		cyc : std_logic;
--		cti	: wb_tag_cti_io;
--		bte	: wb_tag_bte_io;
--		--tagn: wb_tag_slv_o_type;
--		--lock: std_logic;
--	end record;
	subtype wb_slv_in_type is wb_mst_out_type;

	-- Wishbone Slave Output Signals
	type wb_slv_out_type is record
		dat:   std_logic_vector(WB_PORT_SIZE-1 downto 0);
		ack:   std_logic;
		--tagn:  wb_tag_slv_i_type;
		--stall: std_logic;
		--err:   std_logic;
		--rty:   std_logic;
		wbcfg : wb_config_type;	 		-- memory access reg.
	end record;
	--
	--array types
	--
	type wb_mst_out_vector_type is array (natural range <>) of wb_mst_out_type;
	type wb_mst_in_vector_type  is array (natural range <>) of wb_mst_in_type;
	type wb_slv_out_vector_type is array (natural range <>) of wb_slv_out_type;
	type wb_slv_in_vector_type  is array (natural range <>) of wb_slv_in_type;

	subtype wb_mst_out_vector is wb_mst_out_vector_type(NWBMST-1 downto 0);
	subtype wb_slv_out_vector is wb_slv_out_vector_type(NWBSLV-1 downto 0);
	subtype wb_mst_in_vector is wb_mst_in_vector_type(NWBMST-1 downto 0);
	subtype wb_slv_in_vector is wb_slv_in_vector_type(NWBSLV-1 downto 0);
	--30 bits
	subtype generic_addr_type      is integer range 0 to 16#7fffffff#;
	subtype generic_mask_type      is integer range 0 to 16#7fffffff#; --lowest 2 get disregarded



	constant wbm_in_none : wb_mst_in_type :=
		( zdat, 	--data
			'0'				--ack
			--(others=>'0'),	--tagn
			--'0'				--stall
			--'0',				--err
			--'0'				--rty
		  );

	constant wbm_out_none : wb_mst_out_type :=
	( zadr, 	-- adr
	  zdat,   -- dat
	  '0', 					-- we
	  (others => '0'), 	-- sel
	  '0', 					-- stb
	  '0', 					-- cyc
	  "000",				-- cti
	  "00"					-- bte
	  --(others => '0'), 	-- tagn
	  --'0'						--lock
	  );

	constant wbs_in_none:	wb_slv_in_type :=
	( zadr, 	-- adr
	  zdat,   -- dat
	  '0', 					-- we
	  (others => '0'), 	-- sel
	  '0', 					-- stb
	  '0', 					-- cyc
	  "000",				-- cti
	  "00"					-- bte
	  --(others => '0'), 	-- tagn
	  --'0'						--lock
	);

	constant wbs_out_none:	wb_slv_out_type :=
	(	zdat,	--	dat
		'0',				-- ack
		--(others=>'0'),  --tagn
		--'0',			--stall
		--'0', 			--err
		--'0', 			--rty
		(others=>'1') --cfg
	);

	-- function to calculate a valid sel signal (see Wishbone Specification B4 Page 58 ff.)
	function select_bytes(
		address: std_logic_vector;
		len: std_logic_vector; -- number of Granularity sized Units transferred
		sel: std_logic_vector
	) return std_logic_vector;

	function wb_membar(
		memaddr  : generic_addr_type;
		addrmask : generic_mask_type)
	return std_logic_vector;

	function slvadrmap(
		cfg				: std_logic_vector(63 downto 0);
		mstadr			: wb_addr_type
		)
	return boolean;

	function gen_select(
		adr		:	std_logic_vector(1 downto 0); -- core_adr
		sz		:	std_logic_vector(1 downto 0)
		)
	return std_logic_vector;

	function decsz(
		sel		: std_logic_vector(WB_SEL_WIDTH-1 downto 0)
		)
	return std_logic_vector;

	function sel2adr(
		sel:  std_logic_vector(WB_SEL_WIDTH-1 downto 0)
	)
	return std_logic_vector;

	function enc_wb_dat(
		wradr	:	std_logic_vector(1 downto 0);
		wrsz		:	std_logic_vector(1 downto 0);
		din		:	std_logic_vector(memory_width - 1 downto 0)
		)
	return std_logic_vector;

	function dec_wb_dat(
		sel		:	std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		din		:	std_logic_vector(WB_PORT_SIZE-1 downto 0)
		)
	return std_logic_vector;

----------------------------------------------------------------------------------------
-- end package definition
----------------------------------------------------------------------------------------
end;

package body wishbone is

	function select_bytes(
		address: std_logic_vector; -- least significant bits which determine the select signal
		len: std_logic_vector; -- number of Granularity sized Units transferred
		sel: std_logic_vector -- signal which is to set
	) return std_logic_vector is

		-- declarate and initialize variables
		-- initialize result with 1 (dec)
		variable res: unsigned(sel'range) := (others => '0');

		-- convert length to unsigned
		variable len_u: unsigned(WB_ADR_BOUND-1 downto 0) := unsigned(len);

		-- zero vector for comparison with 0
		variable len_zero: unsigned(WB_ADR_BOUND-1 downto 0) := (others => '0');

		-- full select signal
		variable sel_full: std_logic_vector(sel'range) := (others => '1');

	begin
		-- initialization
		res(0) := '1';

		-- handle special case: len=0 = max length
		if (len_u = len_zero) then
			return std_logic_vector(sel_full);
		end if;

		-- check if Bitwidths are valid
		--if (DEBUG = true) then
			assert (sel'length = 2**address'length)
				report "Wishbone, function select_byte: array lengths of address and sel argument do not match, please check your Bitwidths configuration"
				severity failure;
		--end if;

		-- create result vector for case len = 1 (dec)
		for i in address'range loop
			if (address(i) = '1') then
				res := res sll i+1;
			end if;
		end loop;

		-- exponentially expand result vector ones when length > 1 (dec)
		for j in address'range loop
			len_u := len_u sll 1;
			if not(len_u = len_zero) then
				for i in 0 to (WB_SEL_WIDTH/2)-1 loop
					res(2*i+1 downto 2*i) := ( others => ( res(2*i) OR res(2*i+1) ) );
				end loop;
			end if;
		end loop;

		return std_logic_vector(res);
	end; -- end function

---------------------------------------------------------------
-- Function: wb_membar(memaddr, addrmask)
--
-- This function reformat the slave address and mask to support address mapping in slvadrmap function
-- The function will put both the mem address and mask into a field.
-- input: memaddr(30 bits) = base address, addrmask(22 bits)
-- output: cfg (64 bits)
--
-- base_addr[63:34], 30b
-- mask_addr[31: 2], 30b = {FF, 22b}
---------------------------------------------------------------
	function wb_membar(
			memaddr  : generic_addr_type;
			addrmask : generic_mask_type)
	return std_logic_vector is
		variable cfg : std_logic_vector(63 downto 0);
	begin
	--base_addr[63:34], 30b
	--mask_addr[31: 2], 30b = {FF, 22b}
	--slv_exist	= cfg(0);
		cfg(63 downto 32) := std_logic_vector(to_unsigned(memaddr , WB_ADR_WIDTH)); -- 31 b
		--cfg(33 downto 32) := (others=>'0'); --2 bits (free)
		--cfg(31 downto 24) := x"FF"; -- fixed, nonmaskable
		cfg(31 downto  0) := std_logic_vector(to_unsigned(addrmask, WB_ADR_WIDTH)); --31b
		--cfg( 1 downto  0) := "00"; --(free)

		return(cfg);
  end;

---------------------------------------------------------------
-- Function: slvadrmap(cfg, mstadr)
--
-- This function compares the request address from master to slave address (slvo.cfg)
-- slvo.cfg contains its address and mask to identify its address range
-- For non-exist slave, there will be no wb_membar function call in order to format the cfg e.g. setting cfg(31 downto 24) = x"FF"
-- therefore the cfg always return all zeros including the default masking portion
-- besides checking nonexist slave from cfg(31 downto 24) = x"00", slave_mask_vector is another alternative way
-- but the function need to input slave_mask_vector
---------------------------------------------------------------

  function slvadrmap(
			cfg				: std_logic_vector(63 downto 0);
			mstadr			: wb_addr_type
			)
	return boolean is
		variable mmap: std_logic_vector(29 downto 0) := (others=>'0');
		variable addrmapflag: boolean := false;
	begin
	--base_addr = cfg[63:34], 30b
	--mask_addr = cfg[31: 2], 30b
	--mmap = (base_addr ^ mstreq_baseaddr) and mask_addr)
	-----------------------------------------------------
		mmap := (cfg(63 downto 34) xor mstadr) and cfg(31 downto  2);
		if (mmap = (mmap'range => '0')) then
			addrmapflag := true;
		else
			addrmapflag := false;
		end if;
		return(addrmapflag);
  end;

---------------------------------------------------------------
-- Function: gen_select(Address(1 downto 0),ACCESS_SIZE)
-- for the 2 LSBs of an address, returns the WB select signal
-- for a given ACCESS_SIZE{BYTE,HALFWORD,WORD}
---------------------------------------------------------------
	function gen_select(
		adr		: std_logic_vector(1 downto 0);
		sz		: std_logic_vector(1 downto 0)
		)
	return std_logic_vector is
		variable sel_out	:std_logic_vector(WB_SEL_WIDTH-1 downto 0) := (others=>'0');
	begin

		if WB_ENDIANESS = big then
		--if WB_ENDIANESS = little then
			case (sz) is
				when "00" =>
				--SIZE: BYTE
					if		(adr = "11") 	then	sel_out := "0001";
					elsif 	(adr = "10") 	then	sel_out	:= "0010";
					elsif	(adr = "01")	then	sel_out	:= "0100";
					elsif	(adr = "00")	then	sel_out	:= "1000";
					else							sel_out	:= (others=>'0');
					end if;
				when "01" =>
				--SIZE: HALFWORD
					if 		(adr = "10")	then	sel_out := "0011";
					elsif	(adr = "11")	then	sel_out := "0011";
					elsif 	(adr = "01") 	then	sel_out	:= "1100";
					elsif	(adr = "00")	then	sel_out	:= "1100";
					else 							sel_out	:= (others=>'0');
					end if;
				when "10" =>
				--SIZE: WORD
						sel_out	:= (others => '1');
				when others =>
						sel_out	:= (others=>'0');
			end case;
		else
			case (sz) is
				when "00" =>
				--SIZE: BYTE
					if		(adr = "00") 	then	sel_out := "0001";
					elsif 	(adr = "01") 	then	sel_out	:= "0010";
					elsif	(adr = "10")	then	sel_out	:= "0100";
					elsif	(adr = "11")	then	sel_out	:= "1000";
					else							sel_out	:= (others=>'0');
					end if;
				when "01" =>
				--SIZE: HALFWORD
					if 		(adr = "00")	then	sel_out := "0011";
					elsif	(adr = "01")	then	sel_out := "0011";
					elsif 	(adr = "10") 	then	sel_out	:= "1100";
					elsif	(adr = "11")	then	sel_out	:= "1100";
					else 							sel_out	:= (others=>'0');
					end if;
				when "10" =>
				--SIZE: WORD
						sel_out	:= (others => '1');
				when others =>
						sel_out	:= (others=>'0');
			end case;
		end if;

		return(sel_out);
	end;

---------------------------------------------------------------
-- Function: sel2adr(port_gran, wbsel) - decselwb2mem
-- to retrieve last 2 bits address for core
-- big endian
---------------------------------------------------------------
	function sel2adr(
		sel	: std_logic_vector(WB_SEL_WIDTH-1 downto 0)
	)
	return std_logic_vector is
		variable adr	:std_logic_vector(1 downto 0) := (others=>'0');
	begin
		if WB_ENDIANESS = big then
			case WB_PORT_GRAN is
			when 8 =>
				case sel is
				when "1000" => adr := "00";
				when "0100" => adr := "01";
				when "0010" => adr := "10";
				when "0001" => adr := "11";
				when "1100" => adr := "00";
				when "0011" => adr := "10";
				when "1111" => adr := "00";
				when others => adr := "11";
				end case;

			when 16 =>
				--untested! do not use without (extensive) testing
				if		sel(1 downto 0) = "10" then	adr := "00";
				elsif	sel(1 downto 0) = "11" then	adr := "01";
				elsif	sel(1 downto 0) = "01" then	adr := "10";
				else								adr := "00";
				end if;
			when others =>
				--untested! do not use without (extensive) testing
				adr := "00";
			end case;
		else
			case WB_PORT_GRAN is
			when 8 =>
				case sel is
				when "0001" => adr := "00";
				when "0010" => adr := "01";
				when "0100" => adr := "10";
				when "1000" => adr := "11";
				when "0011" => adr := "00";
				when "1100" => adr := "10";
				when "1111" => adr := "00";
				when others => adr := "00";
				end case;

			when 16 =>
				--untested! do not use without (extensive) testing
				if		sel(1 downto 0) = "01" then	adr := "00";
				elsif	sel(1 downto 0) = "11" then	adr := "01";
				elsif	sel(1 downto 0) = "10" then	adr := "10";
				else								adr := "00";
				end if;
			when others =>
				--untested! do not use without (extensive) testing
				adr := "00";
			end case;
		end if;

		return(adr);
	end;

---------------------------------------------------------------
-- Function: enc_wb_dat (byte addr,ACCESS_SIZE,DATA)
-- Encodes a 32-bit input vector to a WB data word,
-- depending on the provided byte address and ACCESS_SIZE
---------------------------------------------------------------
	function enc_wb_dat(
		wradr	:	std_logic_vector(1 downto 0);
		wrsz		:	std_logic_vector(1 downto 0);
		din		:	std_logic_vector(memory_width - 1 downto 0)
		)
	return std_logic_vector is
		variable dword	:std_logic_vector(WB_PORT_SIZE-1 downto 0) := (others=>'0');
	begin
		if WB_ENDIANESS = big then
		--if WB_ENDIANESS = little then
			case wrsz is
			when "00" =>
				if 		wradr = "11" then	dword( 7 downto  0) := din(7 downto 0);
				elsif	wradr = "10" then	dword(15 downto  8) := din(7 downto 0);
				elsif	wradr = "01" then	dword(23 downto 16) := din(7 downto 0);
				elsif	wradr = "00" then	dword(31 downto 24) := din(7 downto 0);
				else						dword				:= (others=>'0');
				end if;
			when "01" =>
				if		wradr = "10" or wradr = "11" then	dword(15 downto 0) := din(15 downto 0);
				elsif	wradr = "00" or wradr = "01" then	dword(31 downto 16):= din(15 downto 0);
				else	dword:= (others=>'0');
				end if;
			when "10" =>
				dword := din;
			when others =>
				dword	:= (others=>'0');
			end case;
		else
			case wrsz is
			when "00" =>
				if 		wradr = "00" then	dword( 7 downto  0) := din(7 downto 0);
				elsif	wradr = "01" then	dword(15 downto  8) := din(7 downto 0);
				elsif	wradr = "10" then	dword(23 downto 16) := din(7 downto 0);
				elsif	wradr = "11" then	dword(31 downto 24) := din(7 downto 0);
				else						dword				:= (others=>'0');
				end if;
			when "01" =>
				if		wradr = "00" or wradr = "01" then	dword(15 downto 0) := din(15 downto 0);
				elsif	wradr = "10" or wradr = "11" then	dword(31 downto 16):= din(15 downto 0);
				else	dword:= (others=>'0');
				end if;
			when "10" =>
				dword := din;
			when others =>
				dword	:= (others=>'0');
			end case;
		end if;

		return(dword);
	end;

---------------------------------------------------------------
-- Function: dec_wb_dat(select,dword)
-- Decodes a WB data word using the given select signal
--
---------------------------------------------------------------
	function dec_wb_dat(
		sel		:	std_logic_vector(WB_SEL_WIDTH-1 downto 0);
		din		:	std_logic_vector(WB_PORT_SIZE-1 downto 0)
		)
	return std_logic_vector is
		variable dword	:std_logic_vector(WB_PORT_SIZE-1 downto 0) := (others=>'0');
	begin
		case WB_PORT_GRAN is
		when 8 =>
			case sel is
			when "0001" =>
				dword(7 downto 0) := din( 7 downto  0);
			when "0010" =>
				dword(7 downto 0) := din(15 downto  8);
			when "0100" =>
				dword(7 downto 0) := din(23 downto 16);
			when "1000" =>
				dword(7 downto 0) := din(31 downto 24);
			when "1100" =>
				dword(15 downto 0) := din(31 downto 16);
			when "0011" =>
				dword(15 downto 0) := din(15 downto 0);
			when "1111" =>
				dword := din;
			when others =>
				dword := (others => '0');
			end case;

		when 16 =>
			--untested! do not use without (extensive) testing
			if		sel = "0011" then	dword(15 downto 0):= din(15 downto 0) ;
			elsif	sel = "1100" then	dword(15 downto 0):= din(31 downto 16);
			else						dword				:= (others=>'0');
			end if;
		when 32 =>
			--untested! do not use without (extensive) testing
			dword := din;
		when others =>
			dword	:= (others=>'0');
		end case;

		return(dword);
	end;

---------------------------------------------------------------
-- Function: decsz(port_gran) equivalent to "decselwb2mem"
--
--
---------------------------------------------------------------
	function decsz(
		sel	: std_logic_vector(WB_SEL_WIDTH-1 downto 0)
	)
	return std_logic_vector is
		variable sz	:std_logic_vector(1 downto 0) := (others=>'0');
	begin
		case WB_PORT_GRAN is
			when  8 =>
				case sel is
				when "0001" =>
					sz := "00";
				when "0010" =>
					sz := "00";
				when "0100" =>
					sz := "00";
				when "1000" =>
					sz := "00";
				when "1100" =>
					sz := "01";
				when "0011" =>
					sz := "01";
				when "1111" =>
					sz := "10";
				when others =>
					sz := "11";
				end case;
			when 16 => sz := "01";
			--untested! do not use without (extensive) testing
			when 32 => sz := "10";
			--untested! do not use without (extensive) testing
			when others => sz := "00";
		end case;
		return(sz);
	end;

end; -- end package body
