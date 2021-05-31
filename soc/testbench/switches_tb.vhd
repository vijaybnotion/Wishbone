library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wb_tp.all;

entity tb_wb_switches is
end tb_wb_switches;

architecture tb of tb_wb_switches is

    component wb_switches
		generic(
		memaddr		:	generic_addr_type := CFG_BADR_SWITCH;
		addrmask	:	generic_mask_type := CFG_MADR_SWITCH
		);
        port (clk      : in std_logic;
              rst      : in std_logic;
              button   : in std_logic_vector (4 downto 0);
              switches : in std_logic_vector (15 downto 0);
              wslvi    : in wb_slv_in_type;
              wslvo    : out wb_slv_out_type);
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
    signal button   : std_logic_vector (4 downto 0) := (others =>'0');
    signal switches : std_logic_vector (15 downto 0) := (others =>'0');
    signal wslvi    : wb_slv_in_type;
    signal wslvo    : wb_slv_out_type;
    signal data     : std_logic_vector(31 downto 0) := (others => '0');
    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';
    
begin

    dut : wb_switches
    port map (clk      => clk,
              rst      => rst,
              button   => button,
              switches => switches,
              wslvi    => wslvi,
              wslvo    => wslvo);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;
	
    stimuli : process
    begin
		rst <= '1';
		
		wait for 20ns;
		rst <= '0';
	    
	    button <= "11011";
		switches <= x"00CD";
		generate_sync_wb_single_read(wslvi, wslvo, clk, data);
		wait for 20ns;
		
		button <= "00100";
		switches <= x"ABCD";
		generate_sync_wb_single_read(wslvi, wslvo, clk, data);
		
		
		wait;
    end process;

end tb;


