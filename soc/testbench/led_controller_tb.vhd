library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity led_controller_tb is
end;

architecture bench of led_controller_tb is

  component led_controller
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
  end component;

  signal clk: std_logic;
  signal rst: std_logic;
  signal on_off: std_logic;
  signal cnt_start: std_logic;
  signal cnt_done: std_logic;
  signal next_pattern: std_logic;
  signal led_pattern: std_logic_vector(7 downto 0);
  signal led: std_logic_vector(7 downto 0);

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  uut: led_controller port map ( clk          => clk,
                                 rst          => rst,
                                 on_off       => on_off,
                                 cnt_start    => cnt_start,
                                 cnt_done     => cnt_done,
                                 next_pattern => next_pattern,
                                 led_pattern  => led_pattern,
                                 led          => led );

  stimulus: process
  begin
  
    -- Put initialisation code here
    led_pattern <= "10101010";
    rst <= '1';
    wait for 10ns;
    rst <= '0';
    wait for 10ns;
    
   -- OFF STATE - UPDATE STATE - OFF STATE 
    on_off <= '1';
    wait for 10ns;
    on_off <= '1';
    wait for 10ns;

   -- OFF STATE - UPDATE STATE - WAIT STATE
    on_off <= '1';
    wait for 10ns;
    on_off <= '0';
    wait for 10ns;
    
   -- WAIT STATE - WAIT STATE - UPDATE STATE - WAIT STATE- OFF STATE
    on_off <= '0';
    cnt_done <= '0';
    wait for 10ns;
    on_off <= '0';
    cnt_done <= '1';
    wait for 10ns;
    on_off <= '0';
    wait for 10ns;
    on_off <= '1';
    cnt_done <= '0';
        

    stop_the_clock <= false;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      clk <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;