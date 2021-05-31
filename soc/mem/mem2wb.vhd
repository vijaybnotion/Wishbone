-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

entity mem2wb is
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
end mem2wb;

ARCHITECTURE Behavioral OF mem2wb IS

	signal indmem	: core_dmem;
	signal ack		: std_logic;

BEGIN
	wbs2dmem: process(wslvi)
	begin
		--init
		indmem.write_en	<= '0';
		indmem.write_addr(memory_width - 1 downto WB_ADR_BOUND) <= (others=>'0');
		indmem.write_addr(1 downto 0) <= "00";
		indmem.write_data	<= (others=>'0');
		indmem.write_size	<= "00";
		--
		indmem.read_en 	<= '0';
		indmem.read_addr(memory_width - 1 downto WB_ADR_BOUND)	<=  (others=>'0');
		indmem.read_addr(1 downto 0) <= "00";
		indmem.read_size	<= "00";
		--end init

		if wslvi.stb = '1' and wslvi.cyc = '1' then
			if wslvi.we = '1' then
				indmem.write_en	<= '1';
				indmem.write_addr	<= wslvi.adr & sel2adr(wslvi.sel);
				indmem.write_data	<= dec_wb_dat(wslvi.sel, wslvi.dat);
				indmem.write_size	<= decsz(wslvi.sel);
			else
				indmem.read_en 	<= '1';
				indmem.read_addr 	<= wslvi.adr & sel2adr(wslvi.sel);
				indmem.read_size	<= decsz(wslvi.sel);
			end if;
		end if;
	end process;
	---
	in_dmem <= indmem;

	dmem2wbs:process(out_dmem, indmem.read_addr, indmem.read_size)
	begin
		--init
		wslvo.dat <= (others=>'0');
		--end init
		wslvo.dat	<= enc_wb_dat(indmem.read_addr(1 downto 0), indmem.read_size, out_dmem.read_data);


	end process;

	process(clk, rst)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				ack	<= '0';
			else
				if wslvi.stb = '1' and wslvi.cyc = '1' and ack = '0' and out_dmem.ready = '1' then
					ack	<= '1';
				else
					ack	<= '0';
				end if;
			end if;
		end if;
	end process;

	wslvo.ack	<= ack;
	wslvo.wbcfg	<= wb_membar(memaddr, addrmask);

END ARCHITECTURE;
