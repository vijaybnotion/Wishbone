-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package lt16x32_global is
	-- width of the memory, the core supports 32 only
	constant memory_width   : integer := 32;
	-- width of the vector holding the interrupt number, maximum 7 due to processor architecture
	constant irq_num_width  : integer := 4;
	-- width of the vector holding the interrupt priority, maximum 6 due to processor architecture
	constant irq_prio_width : integer := 4;

	-- collection of all signals from the core to the data memory
	type core_dmem is record
		-- data written to the memory
		write_data : std_logic_vector(memory_width - 1 downto 0);
		-- address to which the data is written
		write_addr : std_logic_vector(memory_width - 1 downto 0);
		-- size of the written data
		-- 00: byte     (8bits)
		-- 01: halfword (16bits)
		-- 10: word     (32bits)
		-- 11: longword (64bits, currently not featured) 
		write_size : std_logic_vector(1 downto 0);
		-- write enable signal, active high
		write_en   : std_logic;

		-- address from which data is read
		read_addr : std_logic_vector(memory_width - 1 downto 0);
		-- size of the read data
		-- 00: byte     (8bits)
		-- 01: halfword (16bits)
		-- 10: word     (32bits)
		-- 11: longword (64bits, currently not featured) 
		read_size : std_logic_vector(1 downto 0);
		-- read enable signal, active high
		read_en   : std_logic;
	end record;

	-- collection of all signals from the data memory to the core 
	type dmem_core is record
		-- read data, right aligned and zero-filled
		read_data : std_logic_vector(memory_width - 1 downto 0);
		-- ready signal, high if read data is valid
		ready     : std_logic;
	end record;

	-- collection of all signals from the core to the instruction memory
	type core_imem is record
		-- address from which the instruction should be read
		read_addr : std_logic_vector(memory_width - 1 downto 0);
		-- read enable signal, active high
		read_en   : std_logic;
	end record;

	-- collection of all signals from the instruction memory to the core
	type imem_core is record
		-- read data
		read_data : std_logic_vector(memory_width - 1 downto 0);
		-- ready signal, high if read data is valid
		ready     : std_logic;
	end record;

	-- collection of all signals from the interrupt controller to the core
	type irq_core is record
		-- interrupt number of requested interrupt
		num      : unsigned(irq_num_width - 1 downto 0);
		-- priority of requested interrupt (higher number means higher priority)
		priority : unsigned(irq_prio_width - 1 downto 0);
		-- request signal, active high
		req      : std_logic;
		-- non maskable interrupt flag, active high
		nmi      : std_logic;
	end record;

	-- collection of all signals from the core to the interrupt controller
	type core_irq is record
		-- interrupt acknowledge, high if requested interrupt is processed
		ack      : std_logic;
		-- number of interrupt requested by internal trap instruction
		trap_num : unsigned(irq_num_width - 1 downto 0);
		-- request signal for internal trap, active high
		trap_req : std_logic;
	end record;

end package lt16x32_global;

package body lt16x32_global is
end package body lt16x32_global;
