-- Testbench automatically generated online
-- at https://vhdl.lapinoo.net
-- Generation date : 17.5.2021 22:09:50 UTC

library ieee;
use ieee.std_logic_1164.all;

entity tb_led_timer is
end tb_led_timer;

architecture tb of tb_led_timer is

    component led_timer
        port (clk       : in std_logic;
              rst       : in std_logic;
              cnt_start : in std_logic;
              cnt_done  : out std_logic;
              cnt_value : in std_logic_vector (31 downto 0));
    end component;

    signal clk       : std_logic;
    signal rst       : std_logic;
    signal cnt_start : std_logic;
    signal cnt_done  : std_logic;
    signal cnt_value : std_logic_vector (31 downto 0);

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : led_timer
    port map (clk       => clk,
              rst       => rst,
              cnt_start => cnt_start,
              cnt_done  => cnt_done,
              cnt_value => cnt_value);


    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    clk <= TbClock;

    stimuli : process
    begin
		cnt_value <= x"00000010";
        cnt_start <= '1';
        wait for 10ns;
        cnt_start <= '0';
        wait for 10ns;
        
        wait for 250ns;
        cnt_value <= x"00000005";
        cnt_start <= '1';
        wait for 10ns;
        cnt_start <= '0';
        wait for 10ns;
        
        

        
	wait;
    end process;

end tb;

configuration cfg_tb_led_timer of tb_led_timer is
    for tb
    end for;
end cfg_tb_led_timer;