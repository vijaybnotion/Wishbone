library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

ENTITY wb_led IS
	generic(
		memaddr		:	generic_addr_type; --:= CFG_BADR_LED;
		addrmask	:	generic_mask_type --:= CFG_MADR_LED;
	);
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		led		: out  std_logic_vector(7 downto 0);
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
END ENTITY;

ARCHITECTURE rtl of wb_led IS
------- SIGNAL DECLARATIONS
signal data : std_logic_vector(7 downto 0);
signal ack	: std_logic;
-- LED TIMER
signal cnt_start : std_logic;
signal cnt_done  : std_logic;
signal cnt_value : std_logic_vector(31 downto 0);

-- LED BUFFER
signal buffer_clear : std_logic;
signal buffer_write : std_logic;
signal buffer_data 	: std_logic_vector(7 downto 0);
signal next_pattern : std_logic;
signal led_pattern 	: std_logic_vector(7 downto 0);
signal on_off : std_logic;
------- END SIGNAL DECLARATIONS

------- Component Declarations ---------------
component led_timer is
	port(
		clk		  : in std_logic;
		rst 	  : in std_logic;
		cnt_start : in std_logic;
		cnt_done  : out std_logic;
		cnt_value : in std_logic_vector(31 downto 0)
		);
end component;

component led_buffer is
	port(
			clk 		 : in std_logic;
			rst 		 : in std_logic;
			buffer_clear : in std_logic;
			buffer_write : in std_logic;
			buffer_data  : in std_logic_vector(7 downto 0);
			next_pattern : in std_logic;
			led_pattern  : out std_logic_vector(7 downto 0)
		);
end component;

component led_controller is
port(
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

------- END COMPONENT DECLARATIONS ------------
BEGIN

-- Component Instantination
timer_component: led_timer 
	port map(
	clk 	  => clk,
	rst 	  => rst,
	cnt_start => cnt_start,
	cnt_done  => cnt_done,
	cnt_value => cnt_value
	);
	
buffer_component: led_buffer
	port map(
	clk => clk,
	rst => rst,
	buffer_clear => buffer_clear,
	buffer_data => buffer_data,
	buffer_write => buffer_write,
	next_pattern => next_pattern,
	led_pattern => led_pattern);

controller : led_controller
	port map(
	clk => clk,
	rst => rst,
	on_off => on_off,
	cnt_start => cnt_start,
	cnt_done => cnt_done,
	next_pattern=> next_pattern,
	led_pattern => led_pattern,
	led => led);
	
process(clk)
	begin
		if clk'event and clk='1' then
			if rst = '1' then
				ack		<= '0';
				data	<= x"0F";
			else
				if wslvi.stb = '1' and wslvi.cyc = '1' then
					if wslvi.we='1' then
					
						if wslvi.adr(2) = '1' then
							cnt_value <= dec_wb_dat(wslvi.sel, wslvi.dat)(31 downto 0);
						elsif wslvi.adr(2) = '0' then
							on_off <= dec_wb_dat(wslvi.sel, wslvi.dat)(0);
							buffer_clear <= dec_wb_dat(wslvi.sel, wslvi.dat)(8);
							buffer_data <= dec_wb_dat(wslvi.sel, wslvi.dat)(23 downto 16);
							buffer_write <= dec_wb_dat(wslvi.sel, wslvi.dat)(24);
						--data	<= dec_wb_dat(wslvi.sel,wslvi.dat)(7 downto 0);
						end if;
					
					
					end if;
					if ack = '0' then
						ack	<= '1';
					else
						ack	<= '0';
					end if;
				else
					ack <= '0';
					if on_off = '1' then
					on_off <= '0';
					end if;
					
					if buffer_write = '1' then
					buffer_write  <= '0';
					end if;
					
					if buffer_clear = '1' then
					buffer_clear <= '0';
					end if;
					
				end if;
			end if;
		end if;
	end process;

	wslvo.dat(7 downto 0)	<= data;
	wslvo.dat(31 downto 8)	<= (others=>'0');

	--led <= data;

	wslvo.ack	<= ack;
	wslvo.wbcfg	<= wb_membar(memaddr, addrmask);
END ARCHITECTURE rtl;