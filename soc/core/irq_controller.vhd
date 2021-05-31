-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;

-- the interrupt controller constantly checks interrupt lines for interrupt signals,
-- which then are send to the processor.
entity irq_controller is
	port(
		-- clock signal
		clk       : in  std_logic;
		-- reset signal, active high, synchronous
		rst       : in  std_logic;

		-- signals from the processor
		in_proc   : in  core_irq;
		-- signals to the processor
		out_proc  : out irq_core;

		-- irq lines from the "outside world"
		irq_lines : in  std_logic_vector((2 ** irq_num_width) - 1 downto 0)
	);
end entity irq_controller;

architecture RTL of irq_controller is
	-- interrupt number of current request, valid if req = '1' 
	signal num      : unsigned(irq_num_width - 1 downto 0);
	-- interrupt priority of current request, valid if req = '1'
	signal priority : unsigned(irq_prio_width - 1 downto 0);
	-- request signal, active high
	signal req      : std_logic;
	-- non maskable interrupt signal, active high
	signal nmi      : std_logic;

	-- storage of all interrupts that are pending currently
	signal pending : std_logic_vector(irq_lines'range);

	-- returns the priority of a given interrupt number, which
	-- is - for simplicity - calculated as
	-- priority = number modulo maximum priority
	-- this could be extended/changed for each application 
	function get_priority(num : unsigned(irq_num_width - 1 downto 0)) return unsigned is
		variable result : unsigned(irq_prio_width - 1 downto 0);
	begin
		result := num(result'range);

		return result;
	end function get_priority;

begin
	-- simple signal forwarding
	out_proc.req      <= req;
	out_proc.num      <= num;
	out_proc.nmi      <= nmi;
	out_proc.priority <= priority;

	-- reading in both trap signal and external interrupt lines, setting the signal pending
	read_in : process(clk) is
		variable pendingVar : std_logic_vector(pending'range);
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- in reset, all pending interrupts are cleared
				pending <= (others => '0');
			else
				-- read in current pending interrupts
				pendingVar := pending;

				-- clear acknowledged interrupt
				if (req = '1') and (in_proc.ack = '1') then
					pendingVar(to_integer(num)) := '0';
				end if;

				-- read in trap request
				if (in_proc.trap_req = '1') then
					pendingVar(to_integer(unsigned(in_proc.trap_num))) := '1';
				end if;

				-- read in external interrupt request
				if (irq_lines /= (irq_lines'range => '0')) then
					pendingVar := pendingVar or irq_lines;
				end if;

				-- output variable to signal
				pending <= pendingVar;
			end if;
		end if;
	end process read_in;

	-- generate request signals
	request_gen : process(pending, rst) is
		-- highest priority in search process
		variable prio_highest : unsigned(irq_prio_width - 1 downto 0) := (others => '0');
		-- number of interrupt with highes priority
		variable num_highest  : unsigned(irq_num_width - 1 downto 0)  := (others => '0');
	begin
		-- if not in request, and something is pending (ignoring startup uninitialized state)
		if ((rst = '0') and ((pending /= (pending'range => '0')) and (pending /= (pending'range => 'U')))) then
			-- something is pending

			-- initialize variables before loop
			prio_highest := to_unsigned(0, irq_prio_width);
			num_highest  := to_unsigned(0, irq_num_width);

			-- get highest prioritized pending interrupt
			for i in pending'range loop
				if (pending(i) = '1') and (get_priority(to_unsigned(i, irq_num_width)) >= prio_highest) then
					num_highest  := to_unsigned(i, irq_num_width);
					prio_highest := get_priority(to_unsigned(i, irq_num_width));
				end if;
			end loop;

			-- output next interrupt
			num      <= num_highest;
			priority <= prio_highest;
			req      <= '1';

			-- interrupt 2 is NMI
			if (num_highest = to_unsigned(2, irq_num_width)) then
				nmi <= '1';
			else
				nmi <= '0';
			end if;
		else
			-- nothing is pending
			num      <= to_unsigned(1, irq_num_width);
			priority <= to_unsigned(2, irq_prio_width);
			req      <= '0';
			nmi      <= '0';
		end if;
	end process request_gen;

end architecture RTL;
