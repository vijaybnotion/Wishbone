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

entity wb_led_tb2 is
end wb_led_tb2;

architecture tb of wb_led_tb2 is

    component wb_led
		generic(
		memaddr		:	generic_addr_type := CFG_BADR_LED;
		addrmask	:	generic_mask_type := CFG_MADR_LED
		);
        port (clk      : in std_logic;
              rst      : in std_logic;
              led	   : out std_logic_vector(7 downto 0);
              wslvi    : in wb_slv_in_type;
              wslvo    : out wb_slv_out_type);
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
	signal led 		: std_logic_vector(7 downto 0);
    signal wslvi    : wb_slv_in_type;
    signal wslvo    : wb_slv_out_type;
    signal data     : std_logic_vector(31 downto 0) := (others => '0');
    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';
    
begin

    dut : wb_led
    port map (clk      => clk,
              rst      => rst,
              led 	   => led,
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
		
		data <= x"00000003";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 4);
		wait for 5*TbPeriod;

	    
		data <= "00000001000000000000000100000001";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		--data <= x"00000000";
		--generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
	    --wait for 2*TbPeriod;
	    
		data <= "00000001000000010000000000000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		--data <= x"00000000";
		--generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
	    --wait for 2*TbPeriod;
	    
		data <= "00000001000000100000000000000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		--data <= x"00000000";
		--generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
	    --wait for 2*TbPeriod;
	    
		data <= "00000001000001000000000000000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
        --data <= x"00000000";
		--generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
	    --wait for 2*TbPeriod;
		
		data <= "00000011100001000000000000000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
        --data <= x"00000000";
		--generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
	    --wait for 50*TbPeriod;
	    
		data <= "00000011100001000000000000000001";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		
		for i in 0 to 15 loop
		data <= "00000011100001000000000000000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		end loop;
		
		data <= "00000011100001000000000000000001";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		
		data <= "00000011100001000000000100000000";
		generate_sync_wb_single_write(wslvi, wslvo, clk, data, "10", 0);
		wait for 25*TbPeriod;
		
		
		wait;
    end process;

end tb;


