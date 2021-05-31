-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;

package lt16x32_internal is

	-- PACKAGE CONFIGURATION

	-- execute branch delay slot. if set to true, the first operation behind
	-- any type of branch is executed. if set to false, stalls are inserted
	constant execute_branch_delay_slot : boolean := TRUE;
	-- register width
	constant reg_width                 : integer := 32;
	-- pc width (should be smaller or equal to register width)
	constant pc_width                  : integer := 32;

	-- CONSTANT DECLARATIONS (part 1)
	-- memory access width (must be 32 in all conditions)
	constant mem_width : integer                       := 32;
	-- 16bit nop
	constant nop16     : std_logic_vector(15 downto 0) := "0000000000000000";

	-- constants for register numbers are found below function declaration

	-- TYPE DEFINITIONS

	-- type register numbers
	subtype reg_number is unsigned(3 downto 0);

	-- type for data size
	type size_type is (
		--  8 bit
		size_byte,
		-- 16 bit
		size_halfword,
		-- 32 bit
		size_word
	);

	-- type for ALU operation
	type alu_mode_type is (

		-- calculations

		-- perform an addition
		alu_add,
		-- perform a subtraction
		alu_sub,
		-- perform a binary and
		alu_and,
		-- perform a binary or
		alu_or,
		-- perform a binary xor
		alu_xor,
		-- perform a left shift
		alu_lsh,
		-- perform a right shift
		alu_rsh,

		-- comparisons

		-- compare for equal
		alu_cmp_eq,
		-- compare for not equal
		alu_cmp_neq,
		-- compare for greater than or equal
		alu_cmp_ge,
		-- compare for greater than
		alu_cmp_gg,
		-- compare for less then or equal
		alu_cmp_le,
		-- compare for less than
		alu_cmp_ll,
		-- always return true
		alu_cmp_true,
		-- always return false
		alu_cmp_false
	);

	-- type for mode of current instruction
	type instruction_mode_type is (
		-- instruction is normal 16bit instruction
		sel_normal16,
		-- instruction is normal 32bit instruction
		sel_normal32,
		-- instruction is call
		sel_call,
		-- instruction is trap
		sel_trap,
		-- instruction is branch (needed for optional branch delay)
		sel_branch,
		-- instruction is reti
		sel_reti,
		-- stall, insert nop without pc increment
		sel_stall
	);

	-- type for selecting mux input in decoder mux
	type dec_mux_control_type is (
		-- select 16bit decoder output
		sel_ir16,
		-- select 32bit decoder output
		sel_ir32,
		-- select shadow decoder output
		sel_irshadow
	);

	-- type for selecting which data is used for data memory write
	type memory_write_data_select_type is (
		-- use register value for data memory write
		sel_register_value,
		-- use memory read data or'ed with 0x80 for data memory write
		sel_dmemORx80
	);

	-- type for selecting from which address the data memory is read
	type memory_read_addr_select_type is (
		-- use value of register a as data memory read address
		sel_register_a,
		-- use value of register b as data memory read address
		sel_register_b,
		-- use ldr-address as data memory read address
		sel_ldr_address
	);

	-- type for selecting which register number is used to write to register file
	type register_write_number_select_type is (
		-- use register number a
		sel_register_a,
		-- use register number d
		sel_register_d,
		-- use link register
		sel_lr,
		-- use status register
		sel_sr
	);

	-- type for selecting which data is written to register file
	type register_write_data_select_type is (
		-- use data memory read value
		sel_memory,
		-- use alu result
		sel_alu_result,
		-- use immediate value
		sel_immediate
	);

	-- type for selecting which bit is written to trueth flag
	type tflag_write_data_select_type is (
		-- use the 7th bit of data read from data memory
		sel_dmem7,
		-- use alu compare result
		sel_alu
	);

	-- type for selecting which data is used as second alu input
	type alu_input_data_select_type is (
		-- use value of register b as second alu input
		sel_register_b,
		-- use immediate value as second alu input
		sel_imm
	);

	-- type for selecting the pc increment
	type pc_summand_select_type is (
		-- use normal command width
		sel_run,
		-- use immediate value
		sel_immediate,
		-- use value of register a
		sel_register_a
	);

	-- type for selecting the mode of the pc
	type pc_mode_select_type is (
		-- increment relative to old pc
		sel_relative,
		-- set pc to an absolute value
		sel_absolute
	);

	-- type for selecting the width of the current operation
	type instruction_width_type is (
		-- operation is 16 bit wide
		sel_16bit,
		-- operation is 32 bit wide
		sel_32bit
	);

	-- type for selecting if pc jump is conditional
	type pc_condition_type is (
		-- always perform the pc jump
		sel_unconditional,
		-- perform the pc jump only if trueth flag is set
		sel_true
	);

	-- RECORD DECLARATIONS

	-- type for signals from controlpath to PC
	type cp_pc is record
		-- select signal for the pc increment
		summand_select    : pc_summand_select_type;
		-- select signal for the mode of the PC
		mode_select       : pc_mode_select_type;
		-- width of current instruction
		instruction_width : instruction_width_type;
	end record;

	-- type for signals from datapath to PC 
	type dp_pc is record
		-- immediate value for PC calculation
		immediate_value : signed(reg_width - 2 downto 0);
		-- register value for PC calculation
		register_value  : signed(reg_width - 2 downto 0);
	end record;

	-- type for signals from decoder to PC 
	type dec_pc is record
		-- stall signal, active high
		stall : std_logic;
	end record;

	-- type for signals from datapath to decoder
	type dp_dec is record
		-- current runtime priority
		runtime_priority : unsigned(irq_prio_width - 1 downto 0);
	end record;

	-- type for signals from decoder to instruction memory 
	type dec_imem is record
		-- enable signal, active high
		en : std_logic;
	end record;

	-- type for signals from PC to datapath
	type pc_dp is record
		-- current PC value
		value : unsigned(pc_width - 1 downto 0);
	end record;

	-- type for signals from PC to instruction memory
	type pc_imem is record
		-- current PC value
		value : unsigned(pc_width - 1 downto 0);
	end record;

	-- type for signals from interrupt controller to decoder 
	type irq_dec is record
		-- interrupt number of requested interrupt
		num      : unsigned(irq_num_width - 1 downto 0);
		-- priority of requested interrupt (higher number means higher priority)
		priority : unsigned(irq_prio_width - 1 downto 0);
		-- request signal, active high
		req      : std_logic;
		-- non maskable interrupt flag, active high
		nmi      : std_logic;
	end record;

	-- type for signals from decoder to interrupt controller
	type dec_irq is record
		-- interrupt acknowledge, high if requested interrupt is processed
		ack      : std_logic;
		-- number of interrupt requested by internal trap instruction
		trap_num : unsigned(irq_num_width - 1 downto 0);
		-- request signal for internal trap, active high
		trap_req : std_logic;
	end record;

	-- type for signals from decoder pre stage to decoder finite state machine
	type pre_fsm is record
		-- instruction bits, as from imem. For 16bit instructions only instruction(15 downto 0) is used.
		instruction : std_logic_vector(31 downto 0);
		-- mode of this instruction
		mode        : instruction_mode_type;
	end record;

	-- type for signals from decoder finite state machine to decoder for 16bit instructions
	type fsm_dec16 is record
		-- 16bit instruction
		instruction : std_logic_vector(15 downto 0);
	end record;

	-- type for signals from decoder finite state machine to decoder for 32bit instructions
	type fsm_dec32 is record
		-- 32bit instruction
		instruction : std_logic_vector(31 downto 0);
	end record;

	-- type for signals from decoder finite state machine to decoder for shadow instructions
	type fsm_decshd is record
		-- shadow instruction
		instruction : std_logic_vector(31 downto 0);
	end record;

	-- type for signals from decoder finite state machine to decoder mux
	type fsm_decmux is record
		-- control signal of decoder mux
		mode : dec_mux_control_type;
	end record;

	-- type for signals from control path to decoder
	type cp_dec is record
		-- condition signal, high if given condition holds, always high if no condition given
		condition_holds : std_logic;
	end record;

	-- type for signals from control path to data path in first stage
	type cp_dp_s1 is record
		-- register number of register a (first read register)
		register_read_number_a : reg_number;
		-- register number of register b (second read register)
		register_read_number_b : reg_number;
	end record;

	-- type for signals from control path to datapath in second stage
	type cp_dp_s2 is record
		-- 8 bit immediate value
		immediate               : signed(8 - 1 downto 0);
		-- control signal to select which address is used for data memory read
		memory_read_addr_select : memory_read_addr_select_type;
		-- control signal to select which data is used as second alu input
		alu_input_data_select   : alu_input_data_select_type;
		-- mode of alu operation
		alu_mode                : alu_mode_type;
	end record;
	
	-- type for signals from control path to datapath in third stage
	type cp_dp_s3 is record
		-- control signal to select which data is used for data memory write 
		memory_write_data_select   : memory_write_data_select_type;
		-- control signal to select which data is used for register file write
		register_write_data_select : register_write_data_select_type;
		-- register number of register that will be written to
		register_write_number      : reg_number;
		-- enable write to register file, active high
		register_write_enable      : std_logic;
		-- size of register write, standard size data
		register_write_size        : size_type;
		-- enable tflag write, active high
		tflag_write_enable         : std_logic;
		-- control signal, which data is used for tflag write
		tflag_write_data_select    : tflag_write_data_select_type;
		-- enable ovffag write, active high
		ovfflag_write_enable       : std_logic;
	end record;

	-- type for signals from control path to data memory
	type cp_dmem is record
		-- size of data memory read, standard size data
		read_size  : size_type;
		-- enable data memory read, active high
		read_en    : std_logic;
		-- size of data memory write, standard size data
		write_size : size_type;
		-- enable data memory write, active high
		write_en   : std_logic;
	end record;

	-- type for signals from decoder to controlpath for first stage
	type dec_cp_s1 is record
		-- register number of register a (first read register)
		register_read_number_a : reg_number;
		-- register number of register b (second read register)
		register_read_number_b : reg_number;
		-- instruction width of current instruction
		instruction_width      : instruction_width_type;
	end record;

	-- type for signals from decoder to controlpath for second stage
	type dec_cp_s2 is record
		-- these signals are forwarded to datapath

		-- 8 bit immediate value
		immediate             : signed(8 - 1 downto 0);
		-- control signal to select which address is used for data memory read
		dmem_read_addr_select : memory_read_addr_select_type;
		-- control signal to select which data is used as second alu input
		alu_input_data_select : alu_input_data_select_type;
		-- mode of alu operation
		alu_mode              : alu_mode_type;

		-- these signals are forwarded to dmem

		-- size of data memory read, standard size data
		dmem_read_size : size_type;
		-- enable data memory read, active high
		dmem_read_en   : std_logic;

		-- these signals are modified in controlpath

		-- control signal to select which increment is used for pc calculation
		pc_summand_select : pc_summand_select_type;
		-- control signal to select the mode of the pc
		pc_mode_select    : pc_mode_select_type;
		-- control signal to select conditionality of pc jump
		pc_condition      : pc_condition_type;
	end record;

	-- type for signals from decoder to controlpath for third stage
	type dec_cp_s3 is record
		-- these signals are forwarded to datapath

		-- control signal to select which data is used for data memory write 
		dmem_write_data_select     : memory_write_data_select_type;
		-- control signal to select which data is used for register file write
		register_write_data_select : register_write_data_select_type;
		-- register number of register that will be written to
		register_write_number      : reg_number;
		-- enable write to register file, active high
		register_write_enable      : std_logic;
		-- size of register write, standard size data
		register_write_size        : size_type;
		-- enable tflag write, active high
		tflag_write_enable         : std_logic;
		-- control signal, which data is used for tflag write
		tflag_write_data_select    : tflag_write_data_select_type;
		-- enable clfag write, active high
		ovfflag_write_enable       : std_logic;

		-- these signals are forwarded to dmem

		-- size of data memory write, standard size data
		dmem_write_size : size_type;
		-- enable data memory write, active high
		dmem_write_en   : std_logic;
	end record;

	-- type for signals from datapath to controlpath in second stage
	type dp_cp_s2 is record
		-- value of truth flag
		tflag : std_logic;
	end record;

	-- type for signals from datapath to data memory
	type dp_dmem is record
		-- data for data memory write access
		write_data : std_logic_vector(mem_width - 1 downto 0);
		-- address for data memory write access
		write_addr : std_logic_vector(mem_width - 1 downto 0);
		-- address for data memory read access
		read_addr  : std_logic_vector(mem_width - 1 downto 0);
	end record;

	-- type for signals from data memory to datapath 
	type dmem_dp is record
		-- data read
		read_data : std_logic_vector(mem_width - 1 downto 0);
	end record;

	-- type for signals from instruction memory to decoder
	type imem_dec is record
		-- instruction read
		read_data                   : std_logic_vector(mem_width - 1 downto 0);
		-- ready signal, active high
		ready                       : std_logic;
		-- low/high half-word access (i.e. second bit of imem address)
		instruction_halfword_select : std_logic;
	end record;

	-- Pipeline Stages Combinations

	-- type for signals from decoder to controlpath in all stages
	type dec_cp is record
		-- first stage signals
		s1        : dec_cp_s1;
		-- second stage signals
		s2        : dec_cp_s2;
		-- third stage signals
		s3        : dec_cp_s3;
		-- hardfault signal, active high
		hardfault : std_logic;
	end record;

	-- type for signals from controlpath to datapath in all stages
	type cp_dp is record
		-- first stage signals
		s1 : cp_dp_s1;
		-- second stage signals
		s2 : cp_dp_s2;
		-- third stage signals
		s3 : cp_dp_s3;
	end record;

	-- type for signals from datapath to controlpath in all stages
	type dp_cp is record
		-- second stage signals
		s2 : dp_cp_s2;
	end record;

	-- FUNCTION DECLARATIONS

	-- Conversion Functions
	function to_reg_number(i : integer) return reg_number;
	function to_stdlogicvector(s : size_type) return std_logic_vector;
	function reg_size return size_type;

	-- Default Value Functions	
	function get_default_dec_cp_s1 return dec_cp_s1;
	function get_default_dec_cp_s2 return dec_cp_s2;
	function get_default_dec_cp_s3 return dec_cp_s3;

	-- CONSTANT DECLARATIONS (part 2)

	-- register number for stack pointer
	constant sp_num : reg_number := to_reg_number(12);
	-- register number for link register
	constant lr_num : reg_number := to_reg_number(13);
	-- register number for status register
	constant sr_num : reg_number := to_reg_number(14);
	-- register number for pc register
	constant pc_num : reg_number := to_reg_number(15);

	-- OPCODE AND MODE CONSTANT DECLARATIONS

	-- 16 BIT INSTRUCTION OPCODES

	-- opcode of addition (register,register)
	constant op_add  : std_logic_vector(3 downto 0) := "0011";
	-- opcode of subtraction
	constant op_sub  : std_logic_vector(3 downto 0) := "0001";
	-- opcode of binary and
	constant op_and  : std_logic_vector(3 downto 0) := "0010";
	-- opcode of binary or
	constant op_or   : std_logic_vector(3 downto 0) := "0000";
	-- opcode of binary xor
	constant op_xor  : std_logic_vector(3 downto 0) := "0100";
	-- opcode of left shift
	constant op_lsh  : std_logic_vector(3 downto 0) := "0101";
	-- opcode of right shift
	constant op_rsh  : std_logic_vector(3 downto 0) := "0110";
	-- opcode of addition with immediate
	constant op_addi : std_logic_vector(3 downto 0) := "0111";
	-- opcode of compare
	constant op_cmp  : std_logic_vector(3 downto 0) := "1000";
	-- opcode of set status register
	constant op_tst  : std_logic_vector(3 downto 0) := "1001";
	-- opcode of load pc-relative
	constant op_ldr  : std_logic_vector(3 downto 0) := "1010";
	-- opcode of memory operations (load and store)
	constant op_mem  : std_logic_vector(3 downto 0) := "1011";
	-- opcode of branch/call/trap
	constant op_bct  : std_logic_vector(3 downto 0) := "1100";

	-- SHADOW INSTRUCTION OPCODES	

	-- opcode of push
	constant op_shd_push  : std_logic_vector(3 downto 0) := "0001";
	-- opcode of set SR
	constant op_shd_setsr : std_logic_vector(3 downto 0) := "0010";
	-- opcode of reset instruction
	constant op_shd_reset : std_logic_vector(3 downto 0) := "1111";

	-- COMPARE MODES

	-- compare-mode "is equal"
	constant op_cmp_eq    : std_logic_vector(3 downto 0) := "0000";
	-- compare-mode "is not equal"
	constant op_cmp_neq   : std_logic_vector(3 downto 0) := "1000";
	-- compare-mode "is greater or equal"
	constant op_cmp_ge    : std_logic_vector(3 downto 0) := "0001";
	-- compare-mode "is less than"
	constant op_cmp_ll    : std_logic_vector(3 downto 0) := "1001";
	-- compare-mode "is greater than"
	constant op_cmp_gg    : std_logic_vector(3 downto 0) := "0010";
	-- compare-mode "is less or equal"
	constant op_cmp_le    : std_logic_vector(3 downto 0) := "1010";
	-- compare-mode "always true"
	constant op_cmp_true  : std_logic_vector(3 downto 0) := "0011";
	-- compare-mode "always false"
	constant op_cmp_false : std_logic_vector(3 downto 0) := "1011";

	-- BRANCH/CALL/TRAP/RETI MODES

	-- bct-mode "return from interrupt", NB: three bit long!
	constant op_bct_reti   : std_logic_vector(2 downto 0) := "000";
	-- bct-mode "branch to table"
	constant op_bct_table  : std_logic_vector(1 downto 0) := "00";
	-- bct-mode "branch" (pc=newvalue)
	constant op_bct_branch : std_logic_vector(1 downto 0) := "01";
	-- bct-mode "call" (lr=pc, pc=newvalue)
	constant op_bct_call   : std_logic_vector(1 downto 0) := "10";
	-- bct-mode "trap" (trigger interrupt)
	constant op_bct_trap   : std_logic_vector(1 downto 0) := "11";

	-- MEMORY MODES

	-- mem-mode "load 8 bit"
	constant op_mem_ld08 : std_logic_vector(3 downto 0) := "0000";
	-- mem-mode "load 16 bit"
	constant op_mem_ld16 : std_logic_vector(3 downto 0) := "0001";
	-- mem-mode "load 32 bit"
	constant op_mem_ld32 : std_logic_vector(3 downto 0) := "0010";
	-- mem-mode "store 8 bit"
	constant op_mem_st08 : std_logic_vector(3 downto 0) := "1000";
	-- mem-mode "store 16 bit"
	constant op_mem_st16 : std_logic_vector(3 downto 0) := "1001";
	-- mem-mode "store 32 bit"
	constant op_mem_st32 : std_logic_vector(3 downto 0) := "1010";

end package lt16x32_internal;

package body lt16x32_internal is

	-- CONVERSION FUNCTIONS

	-- returns parameter i as reg_number type
	function to_reg_number(i : integer) return reg_number is
	begin
		if ((i >= 0) and (i <= 15)) then
			-- in valid range
			return to_unsigned(i, 4);
		else
			-- in invalid range
			assert false report "register number must be between 0 and 15" severity error;
			return to_unsigned(0, 4);
		end if;
	end function to_reg_number;

	-- returns size as stdlogicvector 
	function to_stdlogicvector(s : size_type) return std_logic_vector is
	begin
		case s is
			when size_byte     => return "00";
			when size_halfword => return "01";
			when size_word     => return "10";
		end case;

	end function;

	-- returns register width as size type
	function reg_size return size_type is
	begin
		case reg_width is
			when 8 =>
				return size_byte;
			when 16 =>
				return size_halfword;
			when 32 =>
				return size_word;
			when others =>              -- will not happen due to assert in core
				return size_byte;
		end case;
	end function reg_size;

	-- DEFAULT VALUE PARAMETERS

	-- returns default (nop) configuration for all stage one signals
	function get_default_dec_cp_s1 return dec_cp_s1 is
		variable defaults : dec_cp_s1;
	begin
		defaults.register_read_number_a := to_reg_number(0);
		defaults.register_read_number_b := to_reg_number(0);
		defaults.instruction_width      := sel_16bit;
		
		return defaults;
	end function get_default_dec_cp_s1;

	-- returns default (nop) configuration for all stage two signals
	function get_default_dec_cp_s2 return dec_cp_s2 is
		variable defaults : dec_cp_s2;
	begin
		defaults.immediate             := to_signed(0, 8);
		defaults.dmem_read_addr_select := sel_register_a;
		defaults.alu_input_data_select := sel_register_b;
		defaults.alu_mode              := alu_or;

		defaults.dmem_read_size := reg_size;
		defaults.dmem_read_en   := '0';
		
		defaults.pc_summand_select     := sel_run;
		defaults.pc_mode_select        := sel_relative;
		defaults.pc_condition          := sel_unconditional;
		
		return defaults;
	end function get_default_dec_cp_s2;

	-- returns default (nop) configuration for all stage three signals
	function get_default_dec_cp_s3 return dec_cp_s3 is
		variable defaults : dec_cp_s3;
	begin
		defaults.dmem_write_data_select     := sel_register_value;
		defaults.register_write_data_select := sel_alu_result;
		defaults.register_write_enable      := '0';
		defaults.register_write_number      := to_reg_number(0);
		defaults.register_write_size        := reg_size;

		defaults.tflag_write_data_select := sel_alu;
		defaults.tflag_write_enable      := '0';
		defaults.ovfflag_write_enable    := '0';

		defaults.dmem_write_size := reg_size;
		defaults.dmem_write_en   := '0';
		return defaults;
	end function get_default_dec_cp_s3;

end package body lt16x32_internal;
