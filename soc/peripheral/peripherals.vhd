-- See the file "LICENSE" for the full license governing this code. --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

library work;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

package lt16soc_peripherals is

	component wb_led is
	generic(
		memaddr		:	generic_addr_type;-- := CFG_BADR_LED;
		addrmask	:	generic_mask_type-- := CFG_MADR_LED;
	);
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		led		: out  std_logic_vector(7 downto 0);
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
	end component;
	
	component wb_switches is
		generic(
		memaddr		:	generic_addr_type;
		addrmask	:	generic_mask_type
		);
        port (clk      : in std_logic;
              rst      : in std_logic;
              button   : in std_logic_vector (4 downto 0);
              switches : in std_logic_vector (15 downto 0);
              wslvi    : in wb_slv_in_type;
              wslvo    : out wb_slv_out_type);
    end component;
	
	
	component wb_timer is
	generic(
		memaddr		:	generic_addr_type; --:= CFG_BADR_TIMER;
		addrmask	:	generic_mask_type --:= CFG_MADR_TIMER
	);
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		wslvi		:	in	wb_slv_in_type;
		wslvo		:	out	wb_slv_out_type;
		irq_out		: out std_logic
	);
end component;

end lt16soc_peripherals;

package body lt16soc_peripherals is

	

end lt16soc_peripherals;

