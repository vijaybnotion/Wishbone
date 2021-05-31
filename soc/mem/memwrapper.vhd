-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;


entity memwrapper is
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask	:	generic_mask_type := CFG_MADR_MEM;
		filename	:	string  := "program.ram";
		size		:	integer := IMEMSZ
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_imem    : in   core_imem;
		out_imem   : out  imem_core;
		
		fault    : out std_logic;
		--out_byte : out std_logic_vector(7 downto 0);
		
		-- wb master port
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
end entity memwrapper;

architecture RTL of memwrapper is

--//////////////////////////////////////////////////////
-- component
--//////////////////////////////////////////////////////
component memdiv
	generic(
		filename     : in string  := "program.ram";
		size         : in integer := IMEMSZ;
		imem_latency : in time    := 5 ns;
		dmem_latency : in time    := 5 ns
	);
	port(
		clk      : in  std_logic;
		rst      : in  std_logic;

		in_dmem  : in  core_dmem;
		out_dmem : out dmem_core;

		in_imem  : in  core_imem;
		out_imem : out imem_core;

		fault    : out std_logic
	);
end component;


component mem2wb
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask	:	generic_mask_type := CFG_MADR_MEM
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
--//////////////////////////////////////////////////////
-- signal 
--//////////////////////////////////////////////////////
	signal outimem	: imem_core;
	signal in_dmem	: core_dmem;
	signal out_dmem	: dmem_core;
begin

--//////////////////////////////////////////////////////
-- Instantiate
--//////////////////////////////////////////////////////
	mem_inst: memdiv
	generic map(
		filename		=>	filename,
		size			=>	size,
		imem_latency	=>	1 ns,
		dmem_latency	=>	1 ns
	)
	port map(
		clk			=>	clk,
		rst			=>	rst,
		in_dmem		=>	in_dmem,
		out_dmem	=>	out_dmem,
		in_imem		=>	in_imem,
		out_imem	=>	outimem,
		fault		=>	fault
		);	
	
	------------------------------------
	-- wb_slv coversion (dmem)
	------------------------------------
	mem2wb_inst: mem2wb
	generic map(
		memaddr		=>	memaddr,
		addrmask	=>	addrmask
	)
	port map(
		clk			=>	clk,
		rst			=>	rst,
		
		in_dmem   	=>	in_dmem,
		out_dmem  	=>	out_dmem,
		
		wslvi		=>	wslvi,
		wslvo		=>	wslvo
	);
	
	------------------------------------
	-- mem ctrl block
	
	out_imem.read_data	<=	outimem.read_data;
	
	memctrl_reg:process(clk)
	begin
		if rst = '1' then
			out_imem.ready		<= '0';
		elsif(rising_edge(clk)) then
			-- TODO: dmem is going to access in imem data portion : how about write ??, can slv overwrite ins (Read only ) ?
			if (in_dmem.read_en  = '1' and (to_integer(unsigned(in_dmem.read_addr )) <= IMEMSZ)) or
			   (in_dmem.write_en = '1' and (to_integer(unsigned(in_dmem.write_addr)) <= IMEMSZ))
			then
				out_imem.ready		<=	'0';
			else
				out_imem.ready		<=	outimem.ready;
			end if;
		end if;
	end process;
	------------------------------------
	-- E N D mem ctrl block
	------------------------------------

end architecture RTL;
