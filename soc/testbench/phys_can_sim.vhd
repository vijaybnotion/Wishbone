library ieee;
use ieee.std_logic_1164.all;

entity phys_can_sim is
	generic(
		peer_num	: integer	--number of can participants connected to the bus
	);
	port(
		rst		: in std_logic;

		rx_vector	: out std_logic_vector(peer_num - 1 downto 0);	--vector containing all rx_signals
		tx_vector	: in std_logic_vector(peer_num - 1 downto 0)	--vector containing all tx_signals
	);
end entity;

architecture behav of phys_can_sim is


begin


	process(tx_vector, rst)
	
	variable value : std_logic := '1';
	variable i : integer;
	
	begin
		if rst = '1' then
			rx_vector <= (others => '1');
		else
			value := '1';
			for i in 0 to peer_num - 1 loop
					value := value and tx_vector(i);
				end loop;
			if value = '1' then
					
				rx_vector <= (others => '1');
			else
				rx_vector <= (others => '0');
			end if;
		end if;
	end process;


end architecture;

--TODO: physical transmission delay simulation if needed (in a later simulation stage)