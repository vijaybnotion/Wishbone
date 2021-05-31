library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_led_buffer is
end tb_led_buffer;

architecture tb of tb_led_buffer is

    component led_buffer
        port (clk          : in std_logic;
              rst          : in std_logic;
              buffer_clear : in std_logic;
              buffer_write : in std_logic;
              buffer_data  : in std_logic_vector (7 downto 0);
              next_pattern : in std_logic;
              led_pattern  : out std_logic_vector (7 downto 0));
    end component;

    signal clk          : std_logic;
    signal rst          : std_logic;
    signal buffer_clear : std_logic;
    signal buffer_write : std_logic;
    signal buffer_data  : std_logic_vector (7 downto 0);
    signal next_pattern : std_logic;
    signal led_pattern  : std_logic_vector (7 downto 0);

    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : led_buffer
    port map (clk          => clk,
              rst          => rst,
              buffer_clear => buffer_clear,
              buffer_write => buffer_write,
              buffer_data  => buffer_data,
              next_pattern => next_pattern,
              led_pattern  => led_pattern);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin

        rst <= '1';
        wait for 10 ns;
        rst <= '0';
        wait for 10 ns;
		
        buffer_data <= x"FF";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        buffer_data <= x"Fe";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"22";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"33";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"66";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        buffer_data <= x"FF";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        buffer_data <= x"Fe";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"22";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"33";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"66";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        buffer_data <= x"FF";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;

        buffer_clear <= '1';
        wait for 10ns;
        buffer_clear <= '0';
        wait for 10ns;

        buffer_data <= x"Fe";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"22";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"33";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"66";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        buffer_data <= x"ee";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
       
        buffer_data <= x"ab";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
       
       next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
         
         buffer_data <= x"bc";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"33";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
         buffer_data <= x"66";
        buffer_write <= '1';
        wait for 10ns;
        buffer_write <= '0';
        wait for 10ns;
        
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;

        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        next_pattern <= '1';
		wait for 10ns;
        report integer'image(conv_integer(led_pattern));
		next_pattern <= '0';
        wait for 10ns;
        
        wait;
    end process;

end tb;

-- Configuration block below is required by some simulators. Usually no need to edit.

configuration cfg_tb_led_buffer of tb_led_buffer is
    for tb
    end for;
end cfg_tb_led_buffer;