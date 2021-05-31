-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;

-- the registerfile contains memory for all registers and flags
-- two registers can be read and one register can be written per clock cycle
-- reading and writing of flags is independent
entity registerfile is
	port(
		-- clock signal
		clk              : in  std_logic;
		-- reset signal, active high, synchronous
		rst              : in  std_logic;
		-- stall signal, active high
		stall            : in  std_logic;

		-- number of register a
		a_num            : in  reg_number;
		-- content of register a
		a_out            : out signed(reg_width - 1 downto 0);
		-- number of register b
		b_num            : in  reg_number;
		-- content of register b
		b_out            : out signed(reg_width - 1 downto 0);

		-- current pc value		
		pc_in            : in  unsigned(pc_width - 1 downto 0);

		-- data that will be written to register file (if write_en = '1')
		write_data       : in  signed(reg_width - 1 downto 0);
		-- number of register that will be written to
		write_num        : in  reg_number;
		-- write enable, active high
		write_en         : in  std_logic;

		-- write enable for truth flag
		true_writeenable : in  std_logic;
		-- input for truth flag write
		true_in          : in  std_logic;
		-- output of current truth flag
		true_out         : out std_logic;

		-- write enable for carry flag, active high
		ovf_writeenable  : in  std_logic;
		-- input for carry flag write
		ovf_in           : in  std_logic;

		-- output of current runtime priority
		runtime_priority : out unsigned(irq_prio_width - 1 downto 0)
	);
end entity registerfile;

architecture RTL of registerfile is
	-- type for memory
	type reg_array_type is array (0 to 13) of signed(reg_width - 1 downto 0);
	-- memory array for the registers
	signal reg_array : reg_array_type;

	-- runtime priority
	signal runtime_priority_internal : unsigned(irq_prio_width - 1 downto 0);
	-- truth flag
	signal t_flag                    : std_logic;
	-- carry flag
	signal ovf_flag                  : std_logic;
	-- status register
	signal sreg                      : std_logic_vector(reg_width - 1 downto 0);
begin
	-- minimum reg_width is 8 to have enough space for SR
	assert (reg_width >= 8) report "Register width (reg_width) must be >= 8." severity failure;

	-- output signals
	output_t : true_out            <= t_flag;
	output_prio : runtime_priority <= runtime_priority_internal;

	-- status register generation
	sreg_out : process(ovf_flag, t_flag, true_writeenable, ovf_writeenable, true_in, ovf_in, runtime_priority_internal) is
	begin
		-- standard output
		sreg <= (others => '0');

		-- runtime priority
		sreg(7 downto (8 - irq_prio_width)) <= std_logic_vector(runtime_priority_internal);

		-- truth flag with write before read
		if (true_writeenable = '1') then
			sreg(1) <= true_in;
		else
			sreg(1) <= t_flag;
		end if;

		-- carry flag
		if (ovf_writeenable = '1') then
			sreg(0) <= ovf_in;
		else
			sreg(0) <= ovf_flag;
		end if;
	end process sreg_out;

	-- register a output
	read_a : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- in reset, output zeros
				a_out <= (others => '0');
			elsif (stall = '0') then
				-- if not stalling, output new value

				if (a_num <= 13) then
					-- standard register

					if ((a_num = write_num) and (write_en = '1')) then
						-- write before read
						a_out <= write_data;
					else
						-- no write
						a_out <= reg_array(to_integer(a_num));
					end if;

				elsif (a_num = 14) then
					-- SR, write to SR is catched combinatorically in sreg_out process
					a_out <= signed(sreg);
				elsif (a_num = 15) then
					-- PC, write to PC is not catched, old values may be seen here
					a_out                        <= (others => '0');
					a_out(pc_width - 1 downto 0) <= signed(pc_in);
				end if;
			end if;
		end if;
	end process read_a;

	-- register b output
	read_b : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- in reset output zeros
				b_out <= (others => '0');

			elsif (stall = '0') then
				-- if not stalling, output new value
				if (b_num <= 13) then
					-- standard register
					if ((b_num = write_num) and (write_en = '1')) then
						-- write before read
						b_out <= write_data;
					else
						b_out <= reg_array(to_integer(b_num));
					end if;
				elsif (b_num = 14) then
					-- SR, write to SR is catched combinatorically in sreg_out process
					b_out <= signed(sreg);
				elsif (b_num = 15) then
					-- PC, write to PC is not catched, old values may be seen here
					b_out                        <= (others => '0');
					b_out(pc_width - 1 downto 0) <= signed(pc_in);
				end if;
			end if;
		end if;
	end process read_b;

	-- write to register
	write : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- do not reset register array, it's bad for synthesis.
				-- TODO: make sure, it's initialized correctly in synthesis
				-- synthesis translate_off
				for i in 0 to 13 loop
					reg_array(i) <= (others => '0');
				end loop;
				-- synthesis translate_on

				-- PC is resetted in pc_counter
				-- reset SR contents
				ovf_flag                  <= '0';
				t_flag                    <= '0';
				runtime_priority_internal <= (others => '1'); -- set runtime priority to maximum

			elsif ((write_en = '1') and (stall = '0')) then
				-- if write enabled and not stalling

				if (write_num <= 13) then
					-- write to normal register
					reg_array(to_integer(write_num)) <= write_data;

				elsif (write_num = sr_num) then
					-- write to SR
					runtime_priority_internal <= unsigned(write_data(7 downto (8 - irq_prio_width)));
					t_flag                    <= write_data(1);
					ovf_flag                  <= write_data(0);
				end if;
				-- write to PC ignored
			end if;

			-- write carry flag
			if ((ovf_writeenable = '1') and (stall = '0')) then
				ovf_flag <= ovf_in;
			end if;

			-- write truth flag
			if ((true_writeenable = '1') and (stall = '0')) then
				t_flag <= true_in;
			end if;
		end if;
	end process write;

end architecture RTL;
