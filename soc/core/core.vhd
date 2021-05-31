-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;

-- the core bundles all entities inside the core itself
entity core is
	port(
		-- clock signal
		clk       : in  std_logic;
		-- reset signal, active high, synchronous
		rst       : in  std_logic;
		-- external stall signal, active high, synchronous
		stall     : in  std_logic;

		-- signals from data memory
		in_dmem   : in  dmem_core;
		-- signals to data memory
		out_dmem  : out core_dmem;

		-- signals from instruction memory
		in_imem   : in  imem_core;
		-- signals to instruction memory
		out_imem  : out core_imem;

		-- signals from interrupt controller
		in_irq    : in  irq_core;
		-- signals to interrupt controller
		out_irq   : out core_irq;

		-- hardfault signal, active high
		hardfault : out std_logic
	);
end entity core;

architecture RTL of core is
	component datapath
		port(clk       : in  std_logic;
			 rst       : in  std_logic;
			 stall     : in  std_logic;
			 out_dec   : out dp_dec;
			 in_cp     : in  cp_dp;
			 out_cp    : out dp_cp;
			 in_pc     : in  pc_dp;
			 out_pc    : out dp_pc;
			 in_dmem   : in  dmem_dp;
			 out_dmem  : out dp_dmem;
			 hardfault : out std_logic);
	end component datapath;
	component controlpath
		port(clk       : in  std_logic;
			 rst       : in  std_logic;
			 stall     : in  std_logic;
			 in_dec    : in  dec_cp;
			 out_dec   : out cp_dec;
			 out_dp    : out cp_dp;
			 out_pc    : out cp_pc;
			 out_dmem  : out cp_dmem;
			 in_dp     : in  dp_cp;
			 hardfault : out std_logic);
	end component controlpath;
	component decoder
		port(clk      : in  std_logic;
			 rst      : in  std_logic;
			 stall    : in  std_logic;
			 in_imem  : in  imem_dec;
			 in_dp    : in  dp_dec;
			 in_cp    : in  cp_dec;
			 out_cp   : out dec_cp;
			 out_pc   : out dec_pc;
			 out_imem : out dec_imem;
			 in_irq   : in  irq_dec;
			 out_irq  : out dec_irq);
	end component decoder;
	component programcounter
		port(clk      : in  std_logic;
			 rst      : in  std_logic;
			 stall    : in  std_logic;
			 in_cp    : in  cp_pc;
			 in_dp    : in  dp_pc;
			 in_dec   : in  dec_pc;
			 out_dp   : out pc_dp;
			 out_imem : out pc_imem);
	end component programcounter;

	-- signals between instances
	signal dp_cp_signal    : dp_cp;
	signal dp_dmem_signal  : dp_dmem;
	signal dmem_dp_signal  : dmem_dp;
	signal imem_dec_signal : imem_dec;
	signal dec_cp_signal   : dec_cp;
	signal dec_imem_signal : dec_imem;
	signal cp_dp_signal    : cp_dp;
	signal cp_dmem_signal  : cp_dmem;
	signal cp_dec_signal   : cp_dec;
	signal pc_dp_signal    : pc_dp;
	signal dp_pc_signal    : dp_pc;
	signal dec_pc_signal   : dec_pc;
	signal pc_imem_signal  : pc_imem;
	signal cp_pc_signal    : cp_pc;
	signal irq_dec_signal  : irq_dec;
	signal dec_irq_signal  : dec_irq;
	signal dp_dec_signal   : dp_dec;

	signal hardfault_dp    : std_logic;
	signal hardfault_cp    : std_logic;

	-- general halt signal
	signal stall_internal  : std_logic;
begin
	-- configuration tests

	-- irq_num_width must be smaller than or equal to 6 to fit into first byte of SR
	assert (irq_prio_width <= 6) report "irq_prio_width must be <= 6." severity failure;
	-- irq_num_width must fit into immediate
	assert (irq_num_width < dec_cp_signal.s2.immediate'high) report "irq_num_width must be <= " & integer'image(dec_cp_signal.s2.immediate'high - 1) & "." severity failure;
	-- reg_width must be 8, 16 or 32bit
	assert ((reg_width = 8) or (reg_width = 16) or (reg_width = 32)) report "selected reg_width is not allowed. allowed values are 8, 16, 32, 64." severity failure;
	-- pc must fit into register
	assert (pc_width <= reg_width) report "pc_width must be smaller than or equal to reg_width." severity failure;

	-- component instantiation
	datapath_inst : component datapath
		port map(clk       => clk,
			     rst       => rst,
			     stall     => stall_internal,
			     out_dec   => dp_dec_signal,
			     in_cp     => cp_dp_signal,
			     out_cp    => dp_cp_signal,
			     in_pc     => pc_dp_signal,
			     out_pc    => dp_pc_signal,
			     in_dmem   => dmem_dp_signal,
			     out_dmem  => dp_dmem_signal,
			     hardfault => hardfault_dp);

	controlpath_inst : component controlpath
		port map(clk       => clk,
			     rst       => rst,
			     stall     => stall_internal,
			     in_dec    => dec_cp_signal,
			     out_dec   => cp_dec_signal,
			     out_dp    => cp_dp_signal,
			     out_pc    => cp_pc_signal,
			     out_dmem  => cp_dmem_signal,
			     in_dp     => dp_cp_signal,
			     hardfault => hardfault_cp);

	decoder_inst : component decoder
		port map(clk      => clk,
			     rst      => rst,
			     stall    => stall_internal,
			     in_imem  => imem_dec_signal,
			     in_dp    => dp_dec_signal,
			     in_cp    => cp_dec_signal,
			     out_cp   => dec_cp_signal,
			     out_pc   => dec_pc_signal,
			     out_imem => dec_imem_signal,
			     in_irq   => irq_dec_signal,
			     out_irq  => dec_irq_signal);

	programcounter_inst : component programcounter
		port map(clk      => clk,
			     rst      => rst,
			     stall    => stall_internal,
			     in_cp    => cp_pc_signal,
			     in_dp    => dp_pc_signal,
			     in_dec   => dec_pc_signal,
			     out_dp   => pc_dp_signal,
			     out_imem => pc_imem_signal);

	-- signals from data memory
	dmem_dp_signal.read_data <= in_dmem.read_data;

	-- signals to data memory	
	out_dmem.read_addr  <= dp_dmem_signal.read_addr;
	out_dmem.read_size  <= to_stdlogicvector(cp_dmem_signal.read_size);
	out_dmem.write_addr <= dp_dmem_signal.write_addr;
	out_dmem.write_data <= dp_dmem_signal.write_data;
	out_dmem.write_size <= to_stdlogicvector(cp_dmem_signal.write_size);

	-- dmem read enable is overwritten if stall is active
	dmem_read_en : with stall select out_dmem.read_en <=
		'0' when '1',
		cp_dmem_signal.read_en when others;
	-- dmem write enable is overwritten if stall is active
	dmem_write_en : with stall select out_dmem.write_en <=
		'0' when '1',
		cp_dmem_signal.write_en when others;

	-- signals from instruction memory
	imem_dec_signal.read_data <= in_imem.read_data;
	imem_dec_signal.ready     <= in_imem.ready;

	-- signals to instruction memory

	-- fill imem address, if pc width is smaller than memory width
	-- all warnings of the type "Null range" can be safely ignored for pc_width = mem_width
	imem_addr_fill : if (pc_width < mem_width) generate
		out_imem.read_addr(mem_width - 1 downto pc_width) <= (others => '0');
	end generate imem_addr_fill;

	out_imem.read_addr(pc_width - 1 downto 0)         <= std_logic_vector(pc_imem_signal.value);
	-- imem read enable is overwritten if stall is active
	imem_read_en : with stall_internal select out_imem.read_en <=
		'0' when '1',
		dec_imem_signal.en when others;

	-- the halfword flag needs a delay as it refers to last clock cycles imem address
	-- (the corresponding data is read in this clock cycle)
	halfword_delay : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- reset to zero
				imem_dec_signal.instruction_halfword_select <= '0';
			elsif (stall_internal = '0') then
				-- set to pc_value(1)
				imem_dec_signal.instruction_halfword_select <= pc_imem_signal.value(1);
			--! else? --TF
			end if;
		end if;
	end process halfword_delay;

	-- signals from interrupt controller
	irq_dec_signal.num      <= in_irq.num;
	irq_dec_signal.priority <= in_irq.priority;
	irq_dec_signal.req      <= in_irq.req;
	irq_dec_signal.nmi      <= in_irq.nmi;

	-- signals to interrupt controller
	out_irq.ack      <= dec_irq_signal.ack;
	out_irq.trap_num <= dec_irq_signal.trap_num;
	out_irq.trap_req <= dec_irq_signal.trap_req;

	-- stall if dmem not ready, imem not ready is handled in decoder_fsm
	stall_internal <= (not in_dmem.ready) or stall;

	-- hardfault logic
	hardfault <= hardfault_cp or hardfault_dp;

end architecture RTL;
