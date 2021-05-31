-- See the file "LICENSE" for the full license governing this code. --

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.wishbone.all;

package config is

-----------------------------
-- RST active level override
-----------------------------
	constant RST_ACTIVE_HIGH	:	boolean := false;

-----------------------------
-- mem size (dmem, imem)
-----------------------------
	constant IMEMSZ	: integer := 256; --this is actually WORD-size!

-----------------------------
-- index assignment
-----------------------------
-- >> Master indx <<
	constant CFG_LT16		: integer := 0;  -- LT16SOC processor core
	constant CFG_MST_TEST	: integer := 1;

-- >> Slave indx  <<
	constant CFG_MEM   : integer := 0;
	constant CFG_DMEM  : integer := CFG_MEM+1;
	constant CFG_LED   : integer := CFG_DMEM+1;
	constant CFG_SWT   : integer := CFG_LED+1;
	constant CFG_TIMER : integer := CFG_SWT+1;
	constant CFG_LEDTOP: integer := CFG_TIMER+1;
-----------------------------
-- base address (BADR) & mask address (MADR)
-----------------------------
-- test slv_base_addr	(30bits)
	constant CFG_BADR_MEM		: generic_addr_type := 16#00000000#; -- fixed, must start from 0
	constant CFG_BADR_DMEM		: generic_addr_type := CFG_BADR_MEM + IMEMSZ*4; --16#00000400#;
	--constant CFG_BADR_NEXTFREEADDRESS		: generic_addr_type := 16#00000800#;
	constant CFG_BADR_LED		: generic_addr_type := 16#000F0000#;
	constant CFG_BADR_SWITCH 	: generic_addr_type := 16#000F0004#;
	constant CFG_BADR_TIMER 	: generic_addr_type := 16#000F0008#;
	constant CFG_BADR_LEDTOP	: generic_addr_type := 16#000F0010#;
-- mask addr
	constant CFG_MADR_ZERO		: generic_mask_type := 0;
	constant CFG_MADR_FULL		: generic_mask_type := 16#3FFFFF#;
	constant CFG_MADR_MEM		: generic_mask_type := 16#3FFFFF# - (IMEMSZ*4 -1);
	constant CFG_MADR_DMEM		: generic_mask_type := 16#3FFFFF# - (256 -1); -- uses 6 word-bits, size 256 byte
	constant CFG_MADR_LED		: generic_mask_type := 16#3FFFF8#; -- size=8 byte
	constant CFG_MADR_SWITCH 	: generic_mask_type := 16#3FFFFC#;
	constant CFG_MADR_TIMER 	: generic_mask_type := 16#3FFFFF# - (8 - 1);
	constant CFG_MADR_LEDTOP 	: generic_mask_type := 16#3FFFFF# - (8 - 1);
end package config;

package body config is
end config;
