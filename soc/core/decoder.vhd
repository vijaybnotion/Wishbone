-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use work.lt16x32_internal.all;

-- the decoder translates instructions from the memory into control signals.
-- it bundles pre-stage, finite stage machine and multiple instruction decoder (16bit, 32bit, shadow)
entity decoder is
	port(
		-- clock signal
		clk      : in  std_logic;
		-- reset signal, active high, synchronous
		rst      : in  std_logic;
		-- stall signal, active high, synchronous
		stall    : in  std_logic;

		-- signals from instruction memory
		in_imem  : in  imem_dec;
		-- signals to instruction memory
		out_imem : out dec_imem;

		-- signals from datapath
		in_dp    : in  dp_dec;

		-- signals from controlpath
		in_cp    : in  cp_dec;
		-- signals to controlpath
		out_cp   : out dec_cp;

		-- signals to PC
		out_pc   : out dec_pc;

		-- signals from interrupt controller
		in_irq   : in  irq_dec;
		-- signals to interrupt controller
		out_irq  : out dec_irq
	);
end entity decoder;

architecture RTL of decoder is
	component decoder_pre
		port(input  : in  imem_dec;
			 output : out pre_fsm);
	end component decoder_pre;
	component decoder_16bit
		port(input  : in  fsm_dec16;
			 output : out dec_cp);
	end component decoder_16bit;
	component decoder_32bit
		port(input  : in  fsm_dec32;
			 output : out dec_cp);
	end component decoder_32bit;
	component decoder_shadow
		port(input  : in  fsm_decshd;
			 output : out dec_cp);
	end component decoder_shadow;
	component decoder_fsm
		port(clk      : in  std_logic;
			 rst      : in  std_logic;
			 stall    : in  std_logic;
			 in_pre   : in  pre_fsm;
			 in_cp    : in  cp_dec;
			 in_dp    : in  dp_dec;
			 out_16   : out fsm_dec16;
			 out_32   : out fsm_dec32;
			 out_shd  : out fsm_decshd;
			 out_mux  : out fsm_decmux;
			 out_pc   : out dec_pc;
			 out_imem : out dec_imem;
			 in_irq   : in  irq_dec;
			 out_irq  : out dec_irq);
	end component decoder_fsm;

	-- signals between instances
	signal pre_fsm_signal    : pre_fsm;
	signal fsm_dec16_signal  : fsm_dec16;
	signal fsm_dec32_signal  : fsm_dec32;
	signal fsm_decshd_signal : fsm_decshd;
	signal fsm_mux_signal    : fsm_decmux;
	signal fsm_pc_signal     : dec_pc;
	signal fsm_imem_signal   : dec_imem;
	signal dec16_mux_signal  : dec_cp;
	signal dec32_mux_signal  : dec_cp;
	signal decshd_mux_signal : dec_cp;

begin
	decoder_pre_inst : component decoder_pre
		port map(input  => in_imem,
			     output => pre_fsm_signal);
	decoder_fsm_inst : component decoder_fsm
		port map(clk      => clk,
			     rst      => rst,
			     stall    => stall,
			     in_pre   => pre_fsm_signal,
			     in_cp    => in_cp,
			     in_dp    => in_dp,
			     in_irq   => in_irq,
			     out_irq  => out_irq,
			     out_16   => fsm_dec16_signal,
			     out_32   => fsm_dec32_signal,
			     out_shd  => fsm_decshd_signal,
			     out_mux  => fsm_mux_signal,
			     out_pc   => fsm_pc_signal,
			     out_imem => fsm_imem_signal);
	decoder_16_inst : component decoder_16bit
		port map(input  => fsm_dec16_signal,
			     output => dec16_mux_signal);
	decoder_32_inst : component decoder_32bit
		port map(input  => fsm_dec32_signal,
			     output => dec32_mux_signal);
	decoder_shd_inst : component decoder_shadow
		port map(input  => fsm_decshd_signal,
			     output => decshd_mux_signal);

	-- multiplexer
	mux_output : with fsm_mux_signal.mode select out_cp <=
		dec16_mux_signal when sel_ir16,
		dec32_mux_signal when sel_ir32,
		decshd_mux_signal when sel_irshadow;

	-- simple signal assignments
	out_pc   <= fsm_pc_signal;
	out_imem <= fsm_imem_signal;
end architecture RTL;
