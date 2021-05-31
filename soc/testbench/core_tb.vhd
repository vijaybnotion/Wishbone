-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;

-- this testbench testes the core in total
entity core_tb is
end entity core_tb;

architecture RTL of core_tb is
	-- clock period, f = 1/period
	constant period : time := 10 ns;

	component core
		port(clk       : in  std_logic;
			 rst       : in  std_logic;
			 stall     : in  std_logic;
			 in_dmem   : in  dmem_core;
			 out_dmem  : out core_dmem;
			 in_imem   : in  imem_core;
			 out_imem  : out core_imem;
			 in_irq    : in  irq_core;
			 out_irq   : out core_irq;
			 hardfault : out std_logic);
	end component core;

	component memory
		generic(filename     : string  := "program.ram";
			    size         : integer := 256;
			    imem_latency : time    := 5 ns;
			    dmem_latency : time    := 5 ns);
		port(clk      : in  std_logic;
			 rst      : in  std_logic;
			 in_dmem  : in  core_dmem;
			 out_dmem : out dmem_core;
			 in_imem  : in  core_imem;
			 out_imem : out imem_core;
			 fault    : out std_logic;
			 out_byte : out std_logic_vector(7 downto 0));
	end component memory;
	
	component irq_controller
		port(clk       : in  std_logic;
			 rst       : in  std_logic;
			 in_proc   : in  core_irq;
			 out_proc  : out irq_core;
			 irq_lines : in  std_logic_vector((2 ** irq_num_width) - 1 downto 0));
	end component irq_controller;

	-- clock signal
	signal clk : std_logic := '0';
	-- reset signal, active high
	signal rst : std_logic := '1';
	-- outbyte signal
	signal out_byte : std_logic_vector(7 downto 0);

	-- signals between instances
	signal dmem_proc_signal : dmem_core;
	signal proc_dmem_signal : core_dmem;
	signal imem_proc_signal : imem_core;
	signal proc_imem_signal : core_imem;
	signal irq_proc_signal  : irq_core;
	signal proc_irq_signal  : core_irq;
	signal irq_lines        : std_logic_vector((2 ** irq_num_width) - 1 downto 0);
begin
	core_inst : component core
		port map(clk       => clk,
			     rst       => rst,
			     stall     => '0',
			     in_dmem   => dmem_proc_signal,
			     out_dmem  => proc_dmem_signal,
			     in_imem   => imem_proc_signal,
			     out_imem  => proc_imem_signal,
			     in_irq    => irq_proc_signal,
			     out_irq   => proc_irq_signal,
			     hardfault => irq_lines(1));

	memory_inst : component memory
		generic map(--filename	=> "sample-programs\test_endianess2.ram",
					--filename		=> "sample-programs\rawhztest.ram",
					filename		=> "sample-programs\rdmem.ram",
			        size         => 256,
			        imem_latency => 0 ns,
			        dmem_latency => 0 ns)
		port map(clk      => clk,
			     rst      => rst,
			     in_dmem  => proc_dmem_signal,
			     out_dmem => dmem_proc_signal,
			     in_imem  => proc_imem_signal,
			     out_imem => imem_proc_signal,
			     fault    => irq_lines(2),
			     out_byte => out_byte);

	irq_controller_inst : component irq_controller
		port map(clk       => clk,
			     rst       => rst,
			     in_proc   => proc_irq_signal,
			     out_proc  => irq_proc_signal,
			     irq_lines => irq_lines);

	-- irq line stimuli
	irq_stimuli : process is
	begin
		irq_lines(irq_lines'high downto 3) <= (others => '0');
		irq_lines(0) <= '0';
		-- irq0 is reset
		-- irq1 is hardfault
		-- irq2 is memfault

		--		wait for 600 ns;
				
		--		wait until rising_edge(clk);
		--		irq_lines(3) <= '1';
		--		irq_lines(4) <= '1';
		--		wait until rising_edge(clk);
		--		irq_lines(3) <= '0';
		--		irq_lines(4) <= '0';

		wait;

	end process irq_stimuli;

	-- clock stimuli
	clock : process is
	begin
		clk <= not clk;
		wait for period / 2;
	end process clock;

	-- reset stimuli
	reset : process is
	begin
		rst <= '1';
		wait for 3.5 * period;
		rst <= '0';
		wait;
	end process reset;

end architecture RTL;
