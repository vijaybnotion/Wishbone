----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2021 15:14:30
-- Design Name: 
-- Module Name: switches - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wb_switches is
	generic(
		memaddr : generic_addr_type;
		addrmask: generic_mask_type
		);
		port (
		clk : in std_logic;
		rst : in std_logic;
		button : in std_logic_vector(4 downto 0);
		switches  : in std_logic_vector(15 downto 0);
		wslvi : in wb_slv_in_type;
		wslvo : out wb_slv_out_type
		);
		
--  Port ( );
end wb_switches;

architecture Behavioral of wb_switches is
	
	signal btn : std_logic_vector(4 downto 0);
	signal swt : std_logic_vector(15 downto 0);
	signal ack : std_logic;
	signal data : std_logic_vector(31 downto 0); --:= (others=>'0');

begin
	process(clk)
	variable swbt : std_logic_vector(31 downto 0):=(others=>'0');
	begin
	swbt(15 downto 0) := switches;
    swbt (20 downto 16):= button;
		if clk'event and clk='1' then
			if rst = '1' then
				ack			<= '0';
				data        <= x"00000000";
				
			else
				if wslvi.stb = '1' and wslvi.cyc = '1' then

					if wslvi.we = '0' then
						--btn	<= button(4 downto 0);
						--swt <= switches(15 downto 0);
						data <= enc_wb_dat(sel2adr(wslvi.sel),decsz(wslvi.sel),swbt);
					end if;

					if ack = '0' then
						ack		<= '1';
					else
						ack		<= '0';
					end if;
				else
					ack			<= '0';
				end if;
			end if;
		end if;
	end process;
	wslvo.dat(31 downto 0) <= data;
	--wslvo.dat(15 downto 0) <= swt;
	--wslvo.dat(20 downto 16) <= btn(4 downto 0);
	--wslvo.dat(31 downto 21) <= (others => '0');
	
	wslvo.ack <= ack;
	wslvo.wbcfg <= wb_membar(memaddr, addrmask);

end Behavioral;