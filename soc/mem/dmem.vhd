-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

-- a small 4x64 byte memory. byte-addressable
entity wb_dmem is
	generic(
		memaddr		:	generic_addr_type;
		addrmask	:	generic_mask_type := CFG_MADR_DMEM
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;

		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
end wb_dmem;

architecture Behavioral of wb_dmem is

	component blockram
	port (
		clk  : in std_logic;
		we   : in std_logic;
		en   : in std_logic;
		addr : in std_logic_vector(5 downto 0);
		di   : in std_logic_vector(7 downto 0);
		do   : out std_logic_vector(7 downto 0));
	end component blockram;

	signal we : std_logic_vector(3 downto 0);
	signal en : std_logic;
	signal addr : std_logic_vector(5 downto 0);
	signal cached_addr	: std_logic_vector(5 downto 0);
	type di_t is array (3 downto 0) of std_logic_vector (7 downto 0);
	signal di : di_t;
	type do_t is array (3 downto 0) of std_logic_vector (7 downto 0);
	signal do : do_t;

	type burst_t is (CLASSIC,BURST,ENDOFBURST);
	signal burst_state	: burst_t;

	signal ack : std_logic;

begin

	process(wslvi.sel, wslvi.we)
	begin
		for i in 3 downto 0 loop
			we(i) <= wslvi.sel(i) and wslvi.we;
		end loop;
	end process;

-- 	we(3) <= wslvi.sel(0) and wslvi.we;
-- 	we(2) <= wslvi.sel(1) and wslvi.we;
-- 	we(1) <= wslvi.sel(2) and wslvi.we;
-- 	we(0) <= wslvi.sel(3) and wslvi.we;

	en <= wslvi.stb and wslvi.cyc;
	addr <= wslvi.adr(7 downto 2);

	block3 : blockram
	port map(clk,we(0),en,addr,di(3),do(3));
	block2 : blockram
	port map(clk,we(1),en,addr,di(2),do(2));
	block1 : blockram
	port map(clk,we(2),en,addr,di(1),do(1));
	block0 : blockram
	port map(clk,we(3),en,addr,di(0),do(0));

	di(3) <= wslvi.dat(7 downto 0);
	di(2) <= wslvi.dat(15 downto 8);
	di(1) <= wslvi.dat(23 downto 16);
	di(0) <= wslvi.dat(31 downto 24);

	process(clk)
	begin
		if clk'event and clk='1' then
			if rst = '1' then
				ack				<= '0';
				burst_state		<= CLASSIC;
			else
				case burst_state is
				when CLASSIC =>
					if wslvi.stb = '1' and wslvi.cyc = '1' then
						if ack = '0' then
							ack			<= '1';
						elsif wslvi.cti = "010" then
							burst_state	<= BURST;
							ack			<= '1';
						else
							ack			<= '0';
						end if;
					else
						ack			<= '0';
					end if;
				when BURST =>
					if wslvi.cti = "111" then
						burst_state	<= ENDOFBURST;
						ack	<= '1';
					end if;
				when ENDOFBURST =>
					burst_state	<= CLASSIC;
					ack			<= '0';
				end case;
			end if;
		end if;
	end process;

	wslvo.ack	<= ack;
	wslvo.dat	<= do(0) & do(1) & do(2) & do(3);
	wslvo.wbcfg	<= wb_membar(memaddr, addrmask);

END ARCHITECTURE;
