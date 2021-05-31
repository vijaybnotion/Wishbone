-- See the file "LICENSE" for the full license governing this code. --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

-- package to incorperate memory modules
package lt16soc_memories is

	--insert components and used functions for the memory modules 

	component wb_dmem is
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_DMEM;
		addrmask	:	generic_mask_type := CFG_MADR_DMEM
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
	end component wb_dmem;
	
	component memwrapper
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask 	:	generic_mask_type := CFG_MADR_MEM;
		filename    :	in string  := "programs/program.ram";
		size		:	in integer := IMEMSZ
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_imem    : in   core_imem;
		out_imem   : out  imem_core;
		
		fault    : out std_logic;
		
		-- wb slv port
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
	end component;
end lt16soc_memories;

package body lt16soc_memories is

	--insert function bodies

end lt16soc_memories;

