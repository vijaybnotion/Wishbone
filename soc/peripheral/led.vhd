-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

entity wb_led is
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
end wb_led;

architecture Behavioral of wb_led is

	signal data : std_logic_vector(7 downto 0);
	signal ack	: std_logic;

begin

	process(clk)
	begin
		if clk'event and clk='1' then
			if rst = '1' then
				ack		<= '0';
				data	<= x"0F";
			else
				if wslvi.stb = '1' and wslvi.cyc = '1' then
					if wslvi.we='1' then
						data	<= dec_wb_dat(wslvi.sel,wslvi.dat)(7 downto 0);
					end if;
					if ack = '0' then
						ack	<= '1';
					else
						ack	<= '0';
					end if;
				else
					ack <= '0';
				end if;
			end if;
		end if;
	end process;

	wslvo.dat(7 downto 0)	<= data;
	wslvo.dat(31 downto 8)	<= (others=>'0');

	led <= data;

	wslvo.ack	<= ack;
	wslvo.wbcfg	<= wb_membar(memaddr, addrmask);

end Behavioral;
