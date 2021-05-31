-- LED CONTROLLER FILE
LIBRARY IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_controller is
	port
	(
		clk : in std_logic;
		rst : in std_logic;
		on_off : in std_logic;
		cnt_start : out std_logic;
		cnt_done : in std_logic;
		next_pattern : out std_logic;
		led_pattern : in std_logic_vector(7 downto 0);
		led : out std_logic_vector(7 downto 0)
	);
end led_controller;


architecture rtl of led_controller is

--define the states
type state_type is (off_s, wait_s, update_s);
signal next_state, current_state: state_type;
signal led_reg: std_logic_vector(7 downto 0);
begin
	
	comb_logic: process(clk)
	begin
	if rising_edge(clk) then
	if rst = '1' then
			current_state <= off_s;
			led_reg <= "00000000";
			cnt_start <= '0';
			next_pattern <= '0';
		else
			current_state <= next_state;
		end if;
	case current_state is
		when off_s => if on_off = '0' then
						 led_reg 		<= "00000000";
						 cnt_start 		<= '0';
						 next_pattern 	<= '0';
					  elsif on_off = '1' then
						 next_state   <= update_s;
						 led_reg 	  <= led_pattern;
						 cnt_start    <= '1';
						 next_pattern <= '1';
					  end if;
		when update_s => if on_off = '1' then
						 next_state <= off_s;
						 led_reg 		<= "00000000";
						 cnt_start 		<= '0';
						 next_pattern 	<= '0';
					  elsif on_off = '0' then
						 next_state   <= wait_s;
						 led_reg 	  <= led_pattern;
						 cnt_start    <= '0';
						 next_pattern <= '0';
					  end if;
		when wait_s => if (on_off = '0' and cnt_done = '1') then
						 next_state <= update_s;
						 led_reg 		<= led_pattern;
						 cnt_start 		<= '1';
						 next_pattern 	<= '1';
					  elsif (on_off = '1') then
						 next_state   <= off_s;
						 led_reg 	  <= "00000000";
						 cnt_start    <= '0';
						 next_pattern <= '0';
					  elsif (on_off = '0' and cnt_done = '0') then
						led_reg <= led_pattern;
						cnt_start <= '0';
						next_pattern <= '0';
					  end if;	
		end case;
		led <= led_reg;
	end if;
	end process;
end architecture;