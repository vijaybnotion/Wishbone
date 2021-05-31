LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.ALL;
entity led_timer is
	port(
		clk : in std_logic;
		rst : in std_logic;
		cnt_start : in std_logic;
		cnt_done : out std_logic;
		cnt_value : in std_logic_vector(31 downto 0)
		);
end led_timer;

architecture rtl of led_timer is 

signal counter : unsigned(31 downto 0);


begin
	
	
	timer: process(clk)
	begin
	if rising_edge(clk) then
		if cnt_start = '1' then
			counter <= unsigned(cnt_value);
		end if;
		
		if counter /= x"00000000" then
			cnt_done <= '0';
			counter <= counter - x"1";
		elsif counter = x"00000000" then
			cnt_done <= '1';
		end if;
		
	end if;
	end process;
end architecture;