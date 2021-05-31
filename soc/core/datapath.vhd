-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;

-- the datapath handles all data interactions, including the registerfile and the ALU
entity datapath is
	port(
		-- clock signal
		clk       : in  std_logic;
		-- reset signal, active high, synchronous
		rst       : in  std_logic;
		-- stall signal (halts pipelines and all flipflops), active high, synchronous
		stall     : in  std_logic;

		-- signals to decoder
		out_dec   : out dp_dec;

		-- signals from control path
		in_cp     : in  cp_dp;
		-- signals to control path
		out_cp    : out dp_cp;

		-- signals from PC counter
		in_pc     : in  pc_dp;
		-- signals to PC counter
		out_pc    : out dp_pc;

		-- signals from data memory
		in_dmem   : in  dmem_dp;
		-- signals to data memory
		out_dmem  : out dp_dmem;

		-- hardfault signal
		hardfault : out std_logic
	);
end entity datapath;

architecture RTL of datapath is
	component alu
		port(in_a     : in  signed(reg_width - 1 downto 0);
			 in_b     : in  signed(reg_width - 1 downto 0);
			 t_out    : out std_logic;
			 ovf_out  : out std_logic;
			 mode     : in  alu_mode_type;
			 data_out : out signed(reg_width - 1 downto 0));
	end component alu;

	component registerfile
		port(clk              : in  std_logic;
			 rst              : in  std_logic;
			 stall            : in  std_logic;
			 a_num            : in  reg_number;
			 a_out            : out signed(reg_width - 1 downto 0);
			 b_num            : in  reg_number;
			 b_out            : out signed(reg_width - 1 downto 0);
			 pc_in            : in  unsigned(pc_width - 1 downto 0);
			 write_data       : in  signed(reg_width - 1 downto 0);
			 write_num        : in  reg_number;
			 write_en         : in  std_logic;
			 true_writeenable : in  std_logic;
			 true_in          : in  std_logic;
			 true_out         : out std_logic;
			 ovf_writeenable  : in  std_logic;
			 ovf_in           : in  std_logic;
			 runtime_priority : out unsigned(irq_prio_width - 1 downto 0));
	end component registerfile;

	-- signals from register file
	signal regfile_reg_a : signed(reg_width - 1 downto 0);
	signal regfile_reg_b : signed(reg_width - 1 downto 0);
	signal regfile_tflag : std_logic;

	-- signals from ALU
	signal alu_result  : signed(reg_width - 1 downto 0);
	signal alu_tflag   : std_logic;
	signal alu_ovfflag : std_logic;

	-- mux output signals
	-- data written to register file (if registerfile.we = '1')
	signal reg_write_data   : signed(reg_width - 1 downto 0);
	-- second alu input data
	signal alu_input_b      : signed(reg_width - 1 downto 0);
	-- bit saved as truth-flag (if registerfile.tflag_we = '1')
	signal tflag_write_data : std_logic;

	-- forwarded register values
	-- register a value after forwarding unit
	signal regfile_reg_a_fwd : signed(reg_width - 1 downto 0);
	-- register b value after forwarding unit
	signal regfile_reg_b_fwd : signed(reg_width - 1 downto 0);
	-- truth-flag after forwarding
	signal regfile_tflag_fwd : std_logic;

	-- pipelined signals
	signal register_number_a_s2 : reg_number;
	signal register_number_b_s2 : reg_number;

	signal regfile_reg_a_s3 : signed(reg_width - 1 downto 0);
	signal regfile_reg_b_s3 : signed(reg_width - 1 downto 0);

	signal alu_result_s3  : signed(reg_width - 1 downto 0);
	signal alu_tflag_s3   : std_logic;
	signal alu_ovfflag_s3 : std_logic;

	signal pc_value_s2 : unsigned(pc_width - 1 downto 0);

	signal immediate_signext_s3 : signed(reg_width - 1 downto 0);

	-- signals calculated internally in datapath

	-- LDR address
	signal ldr_address : signed(reg_width - 1 downto 0);

	-- immediate value with signextension for use as alu input
	signal immediate_signext : signed(reg_width - 1 downto 0);

	-- write data to register file including masking for size
	signal reg_write_data_sized : signed(reg_width - 1 downto 0);

	-- dmem read data or'ed with 0xF0
	signal dmemORx80 : std_logic_vector(reg_width - 1 downto 0);

	-- hardfault signals
	signal regwrite_size_error : std_logic;

	-- returns minimum of (a, b). needed, since XILINX does not support constant conditional syntax
	function minval(a : integer; b : integer) return integer is
	begin
		if (a <= b) then
			return a;
		else
			return b;
		end if;
	end function minval;

begin
	registerfile_inst : component registerfile
		port map(clk              => clk,
			     rst              => rst,
			     stall            => stall,
			     a_num            => in_cp.s1.register_read_number_a,
			     a_out            => regfile_reg_a,
			     b_num            => in_cp.s1.register_read_number_b,
			     b_out            => regfile_reg_b,
			     pc_in            => pc_value_s2,
			     write_data       => reg_write_data_sized,
			     write_num        => in_cp.s3.register_write_number,
			     write_en         => in_cp.s3.register_write_enable,
			     true_writeenable => in_cp.s3.tflag_write_enable,
			     true_in          => tflag_write_data,
			     true_out         => regfile_tflag,
			     ovf_writeenable  => in_cp.s3.ovfflag_write_enable,
			     ovf_in           => alu_ovfflag_s3,
			     runtime_priority => out_dec.runtime_priority);

	alu_inst : component alu
		port map(in_a     => regfile_reg_a_fwd,
			     in_b     => alu_input_b,
			     t_out    => alu_tflag,
			     ovf_out  => alu_ovfflag,
			     mode     => in_cp.s2.alu_mode,
			     data_out => alu_result);

	-- simple output assignments
	out_pc.register_value                       <= regfile_reg_a_fwd(regfile_reg_a_fwd'high downto 1); -- last bit ignored for PC
	hardfault                                   <= regwrite_size_error;
	out_dmem.write_addr(reg_width - 1 downto 0) <= std_logic_vector(regfile_reg_a_s3);
	out_cp.s2.tflag                             <= regfile_tflag_fwd;
	
	-- create signextended immediate
	-- sign extension
	immediate_signext(immediate_signext'left downto (in_cp.s2.immediate'left + 1)) <= (others => in_cp.s2.immediate(7));
	-- actual data
	immediate_signext(in_cp.s2.immediate'range)                                    <= in_cp.s2.immediate;
	
	-- ldr address calculation
	-- ldr_address = PC + (immediate << 1)
	ldr_address <= signed(pc_value_s2) + signed(immediate_signext(reg_width - 2 downto 0) & "0");

	-- create immediate value for pc block
	-- sign extension
	pc_imm_fill : if (reg_width > 8) generate
		out_pc.immediate_value(out_pc.immediate_value'left downto (in_cp.s2.immediate'left + 1)) <= (others => in_cp.s2.immediate(7));
	end generate;
	-- actual data, (left shift by one is performed by PC)
	out_pc.immediate_value(minval(out_pc.immediate_value'high, in_cp.s2.immediate'left) downto 0) <= in_cp.s2.immediate(minval(out_pc.immediate_value'high, in_cp.s2.immediate'left) downto 0);
	

	-- fill dmem read/write address and dmem write data, if reg width is smaller than memory width
	-- all warnings of the type "Null range" can be safely ignored for reg_width = mem_width
	dmem_fill : if (reg_width < mem_width) generate
		out_dmem.write_addr(mem_width - 1 downto reg_width) <= (others => '0');
		out_dmem.write_data(mem_width - 1 downto reg_width) <= (others => '0');
		out_dmem.read_addr(mem_width - 1 downto reg_width)  <= (others => '0');
	end generate dmem_fill;

	-- dmem data or'ing (dmemORx80 = dmem.read_data or 0x80)
	dmemORx80_calc : process(in_dmem.read_data) is
	begin
		dmemORx80    <= in_dmem.read_data(reg_width - 1 downto 0);
		dmemORx80(7) <= '1';
	end process dmemORx80_calc;

	-- multiplexer

	regfile_write_data_mux : with in_cp.s3.register_write_data_select select reg_write_data <=
		signed(in_dmem.read_data(reg_width - 1 downto 0)) when sel_memory,
		alu_result_s3 when sel_alu_result,
		immediate_signext_s3 when sel_immediate;

	alu_in_b_mux : with in_cp.s2.alu_input_data_select select alu_input_b <=
		regfile_reg_b_fwd when sel_register_b,
		immediate_signext when sel_imm;

	dmem_write_data_mux : with in_cp.s3.memory_write_data_select select out_dmem.write_data(reg_width - 1 downto 0) <=
		std_logic_vector(regfile_reg_b_s3) when sel_register_value,
		dmemORx80 when sel_dmemORx80;

	dmem_read_addr_mux : with in_cp.s2.memory_read_addr_select select out_dmem.read_addr(reg_width - 1 downto 0) <=
		std_logic_vector(regfile_reg_a_fwd) when sel_register_a,
		std_logic_vector(regfile_reg_b_fwd) when sel_register_b,
		std_logic_vector(ldr_address) when sel_ldr_address;

	tflag_write_data_mux : with in_cp.s3.tflag_write_data_select select tflag_write_data <=
		(not in_dmem.read_data(7)) when sel_dmem7,
		alu_tflag_s3 when sel_alu;

	-- forwarding units

	forward_register_a : process(in_cp.s3.register_write_number, register_number_a_s2, reg_write_data_sized, regfile_reg_a, in_cp.s3.register_write_enable) is
	begin
		if ((in_cp.s3.register_write_enable = '1') and (in_cp.s3.register_write_number = register_number_a_s2)) then
			-- next cycle, there's a write to register number a, forward new value
			regfile_reg_a_fwd <= reg_write_data_sized;
		else
			-- next cycle is no write to register number a, no forwarding
			regfile_reg_a_fwd <= regfile_reg_a;
		end if;
	end process forward_register_a;

	forward_register_b : process(in_cp.s3.register_write_number, register_number_b_s2, reg_write_data_sized, regfile_reg_b, in_cp.s3.register_write_enable) is
	begin
		if ((in_cp.s3.register_write_enable = '1') and (in_cp.s3.register_write_number = register_number_b_s2)) then
			-- next cycle, there's a write to register number b, forward new value
			regfile_reg_b_fwd <= reg_write_data_sized;
		else
			-- next cycle is no write to register number b, no forwarding
			regfile_reg_b_fwd <= regfile_reg_b;
		end if;
	end process forward_register_b;

	forward_tflag : process(tflag_write_data, regfile_tflag, in_cp.s3.tflag_write_enable) is
	begin
		if (in_cp.s3.tflag_write_enable = '1') then
			-- next cycle, there's a write to the truth flag, forward new value
			regfile_tflag_fwd <= tflag_write_data;
		else
			-- next cycle is no write to the truth flag
			regfile_tflag_fwd <= regfile_tflag;
		end if;
	end process forward_tflag;

	-- generate size-matched data for the register file and forwarding units from the full-word write data
	reg_write_data_sized_calc : process(reg_write_data, in_cp.s3.register_write_size) is
		variable error : boolean;
	begin
		error                := false;
		reg_write_data_sized <= (others => '0');

		case in_cp.s3.register_write_size is
			when size_byte =>
				reg_write_data_sized(7 downto 0) <= reg_write_data(7 downto 0);
			when size_halfword =>
				if (reg_width >= 16) then
					reg_write_data_sized(minval(reg_width - 1, 15) downto 0) <= reg_write_data(minval(reg_width - 1, 15) downto 0);
				else
					error := true;
				end if;
			when size_word =>
				if (reg_width >= 32) then
					reg_write_data_sized(minval(reg_width - 1, 31) downto 0) <= reg_write_data(minval(reg_width - 1, 31) downto 0);
				else
					error := true;
				end if;
		end case;

		if (error) then
			-- synthesis translate_off
			assert false report "size not supported" severity warning;
			-- synthesis translate_on
			regwrite_size_error <= '1';
		else
			regwrite_size_error <= '0';
		end if;

	end process reg_write_data_sized_calc;

	-- pipelining
	pipeline : process(clk) is
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- default values in reset state
				pc_value_s2          <= (others => '0');
				alu_result_s3        <= (others => '0');
				alu_tflag_s3         <= '0';
				alu_ovfflag_s3       <= '0';
				register_number_a_s2 <= (others => '0');
				register_number_b_s2 <= (others => '0');
				regfile_reg_a_s3     <= (others => '0');
				regfile_reg_b_s3     <= (others => '0');
				immediate_signext_s3 <= (others => '0');
			elsif (stall = '0') then
				-- if stall is not active, pipeline values
				pc_value_s2          <= in_pc.value;
				alu_result_s3        <= alu_result;
				alu_tflag_s3         <= alu_tflag;
				alu_ovfflag_s3       <= alu_ovfflag;
				register_number_a_s2 <= in_cp.s1.register_read_number_a;
				register_number_b_s2 <= in_cp.s1.register_read_number_b;
				regfile_reg_a_s3     <= regfile_reg_a_fwd;
				regfile_reg_b_s3     <= regfile_reg_b_fwd;
				immediate_signext_s3 <= immediate_signext;
			end if;
		end if;
	end process pipeline;

end architecture RTL;
