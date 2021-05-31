-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;

-- the processor bundles all entities needed for a running system, including the core itself, the interrupt controller and the memory.
entity processor is
	port(
		-- clock signal
		clk      : in  std_logic;
		-- reset signal, active high, synchronous
		rst      : in  std_logic;

		-- interrupt lines
		-- three interrupts are used internally
		irq      : in  std_logic_vector(2 ** irq_num_width - 4 downto 0);
		-- out_byte to communicate to extern world
		out_byte : out std_logic_vector(7 downto 0)
	);
end entity processor;

architecture RTL of processor is
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
			    imem_latency : in time := 5 ns;
			    dmem_latency : in time := 5 ns);
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

	-- signals between instances
	signal dmem_core_signal : dmem_core;
	signal core_dmem_signal : core_dmem;
	signal imem_core_signal : imem_core;
	signal core_imem_signal : core_imem;
	signal irq_core_signal  : irq_core;
	signal core_irq_signal  : core_irq;
	signal irq_lines        : std_logic_vector((2 ** irq_num_width) - 1 downto 0);

	-- fault signal from core
	signal core_fault : std_logic;
	-- fault signal from memory
	signal mem_fault  : std_logic;
begin
	-- fixed interrupt lines
	-- irq0 is reset
	irq_lines(0)                       <= '0'; -- reset
	-- irq1 is core fault
	irq_lines(1)                       <= core_fault;
	-- irq2 is memory fault
	irq_lines(2)                       <= mem_fault;
	-- other lines can be used from the outside
	irq_lines(irq_lines'high downto 3) <= irq;

	core_inst : component core
		port map(clk       => clk,
			     rst       => rst,
			     stall     => '0',
			     in_dmem   => dmem_core_signal,
			     out_dmem  => core_dmem_signal,
			     in_imem   => imem_core_signal,
			     out_imem  => core_imem_signal,
			     in_irq    => irq_core_signal,
			     out_irq   => core_irq_signal,
			     hardfault => core_fault);

	memory_inst : component memory
		generic map(filename     => "../programs/example_led.ram",
			        size         => 32,
			        imem_latency => 0 ns,
			        dmem_latency => 0 ns)
		port map(clk      => clk,
			     rst      => rst,
			     in_dmem  => core_dmem_signal,
			     out_dmem => dmem_core_signal,
			     in_imem  => core_imem_signal,
			     out_imem => imem_core_signal,
			     fault    => mem_fault,
			     out_byte => out_byte);

	irq_controller_inst : component irq_controller
		port map(clk       => clk,
			     rst       => rst,
			     in_proc   => core_irq_signal,
			     out_proc  => irq_core_signal,
			     irq_lines => irq_lines);

end architecture RTL;
