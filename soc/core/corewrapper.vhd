-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

-- TODO: check core(big/little endian) -> assume as little !!
entity corewrapper is
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_imem   : in	imem_core;
		out_imem  : out	core_imem;
		
		in_proc   : in  irq_core;
		out_proc  : out core_irq;
		
		hardfault : out std_logic;
		
		-- wb master port
		wmsti	:	in	wb_mst_in_type;
		wmsto	:	out	wb_mst_out_type
	);
end entity corewrapper;

architecture RTL of corewrapper is
	signal wbmo		: wb_mst_out_type := wbm_out_none;
	--signal indmem	: dmem_core;
	signal in_dmem	: dmem_core;
	signal out_dmem	: core_dmem;
	
--	signal inimem	: imem_core;
--	signal outimem	: core_imem;
	
	
--//////////////////////////////////////////////////////
-- component
--//////////////////////////////////////////////////////
component core
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		stall     : in  std_logic;

		in_dmem   : in  dmem_core;
		out_dmem  : out core_dmem;

		in_imem   : in  imem_core;
		out_imem  : out core_imem;

		in_irq    : in  irq_core;
		out_irq   : out core_irq;

		hardfault : out std_logic
	);
end component;

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
	
begin

--//////////////////////////////////////////////////////
-- Instantiate
--//////////////////////////////////////////////////////
--
	core_inst: core
		port map(
		clk			=>	clk,
		rst			=>	rst,
		stall		=>	'0',  -- no stall for now -- wmsti.stall
		
		in_dmem		=>	in_dmem,
		out_dmem	=>	out_dmem,
		
		in_imem		=>	in_imem, -- inimem, 
		out_imem	=>	out_imem, -- outimem, 
		in_irq		=>	in_proc,
		out_irq		=>	out_proc,
		hardfault	=>	hardfault
	);
	
	core2wb_inst: core2wb
	port map(
		clk			=>	clk,
		rst			=>	rst,
		
		in_dmem   => in_dmem,
		out_dmem  => out_dmem,
		
		-- wb master port
		wmsti	=> wmsti,
		wmsto	=> wmsto
	);


--//////////////////////////////////////////////////////
-- I - mem
--//////////////////////////////////////////////////////
	
	
	-- core connect directly to the mem
	
--	imem: process(clk)
--	begin
--		if rising_edge(clk) then
--			if rst = '1' then
--				-- to core
--				inimem.read_data	<= (others=>'-');
--				inimem.ready		<= '0';
--				-- out from core
--				outimem.read_addr	<= (others=>'0');
--				outimem.read_en		<= '0';
--				
--				out_imem.read_addr	<= (others=>'0');
--				out_imem.read_en	<= '0';
--			else
--				-- to core
--				inimem		<= in_imem;
--				-- out from core
--				out_imem	<= outimem;
--			end if;
--		end if;
--	end process;

end architecture RTL;
