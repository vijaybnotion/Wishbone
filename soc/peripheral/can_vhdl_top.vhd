-- 
-- can_vhdl_top
--
-- Wraps the verilog component for the con controller into an VHDL entity
-- The wrapper translates the 8-bit wishbone interface into an 32 bit interface.
-- Still, only 8-bit accesses are allowed. 
-- @autor: Thoams Fehmel
--


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.wishbone.all;
use work.config.all;

entity can_vhdl_top is
generic(
	memaddr		: generic_addr_type;
	addrmask	: generic_mask_type
);
port(
	clk 		: in std_logic;
	rstn 		: in std_logic;
	wbs_i 		: in wb_slv_in_type;
	wbs_o 		: out wb_slv_out_type;
	rx_i 		: in std_logic;
	tx_o 		: out std_logic;
	driver_en	: out std_logic;
	irq_on 		: out std_logic
	
);
end can_vhdl_top;

architecture Behavioral of can_vhdl_top is

component can_top is
port(
wb_clk_i : in std_logic;
wb_rst_i : in std_logic;
wb_dat_i : in std_logic_vector(7 downto 0);
wb_dat_o : out std_logic_vector(7 downto 0);
wb_cyc_i : in std_logic;
wb_stb_i : in std_logic;
wb_we_i : in std_logic;
wb_adr_i : in std_logic_vector(7 downto 0);
wb_ack_o : out std_logic;
clk_i : in std_logic;
rx_i : in std_logic;
tx_o : out std_logic;
bus_off_on : out std_logic;
irq_on : out std_logic;
clkout_o : out std_logic
);
end component;

signal wb_dat_i : std_logic_vector(7 downto 0);
signal wb_dat_o : std_logic_vector(7 downto 0);

signal wb_addr : std_logic_vector(7 downto 0);

signal bus_off_on : std_logic;
signal clkout_o : std_logic;

signal irq_can : std_logic;
signal irq_tmp : std_logic;

signal tx_int : std_logic;

begin

can_mod : can_top 
port map(
wb_clk_i=>clk, 
wb_rst_i=>rstn, 
wb_dat_i=>wb_dat_i,
wb_dat_o=>wb_dat_o,
wb_cyc_i=>wbs_i.cyc,
wb_stb_i=>wbs_i.stb,
wb_we_i=>wbs_i.we,
wb_adr_i=>wb_addr,
wb_ack_o=>wbs_o.ack,
clk_i=>clk,
rx_i=>rx_i,
tx_o=>tx_int,
bus_off_on=>bus_off_on, --goes nowhere
irq_on=>irq_can,
clkout_o=>clkout_o --goes nowhere
);

wb_dat_i <=
	wbs_i.dat(31 downto 24) when wbs_i.sel = "1000" else
	wbs_i.dat(23 downto 16) when wbs_i.sel = "0100"	else
	wbs_i.dat(15 downto  8) when wbs_i.sel = "0010"	else
	wbs_i.dat( 7 downto  0) when wbs_i.sel = "0001"	else
	(others=>'0');

--assert (wbs_i.stb='0' or ((wbs_i.sel="1000") or (wbs_i.sel="0100") or (wbs_i.sel="0010") or (wbs_i.sel="0001") or (wbs_i.sel="0000"))) report "CAN wishbone itnerface only supports 8-bit accesses" severity ERROR;

wbs_o.dat(31 downto 24) <= wb_dat_o when wbs_i.sel(3) = '1' else (others=>'0');
wbs_o.dat(23 downto 16) <= wb_dat_o when wbs_i.sel(2) = '1' else (others=>'0');
wbs_o.dat(15 downto  8) <= wb_dat_o when wbs_i.sel(1) = '1' else (others=>'0');
wbs_o.dat( 7 downto  0) <= wb_dat_o when wbs_i.sel(0) = '1' else (others=>'0');

--wb_addr <= wbs_i.adr(WB_ADR_BOUND+6 downto WB_ADR_BOUND) & sel2adr(wbs_i.sel);

addr_adder: if to_unsigned(memaddr, 16)(7 downto 2) /= "000000" generate
	wb_addr <= std_logic_vector(unsigned(wbs_i.adr(7 downto 2) & sel2adr(wbs_i.sel)) - to_unsigned(memaddr, 16)(7 downto 0));
end generate;

addr_forw: if to_unsigned(memaddr, 16)(7 downto 2) = "000000" generate
	wb_addr(7 downto 2) <= wbs_i.adr(7 downto 2);
	wb_addr(1 downto 0) <= sel2adr(wbs_i.sel);
end generate;

--convert irq : active low(can) to activ high(soc)
--interrupt generation: only active for one clk cycle after falling edge of irq_can
irq_gen: process(clk)
begin
	if clk = '1' and clk'event then
		if irq_tmp = '1' and irq_can = '0' then
			irq_on <= '1';
		else
			irq_on <= '0';
		end if;
		irq_tmp <= irq_can;
	end if;
end process;

--NOTE: address check is skipped udner the assumption that the interconnect handles it.
wbs_o.wbcfg <= wb_membar(memaddr, addrmask);

-- driver enable 
tx_o <= tx_int;
driver_en <= not(tx_int);

end architecture;