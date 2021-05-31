
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.wishbone.all;
use work.can_tp.all;
use work.config.all;

entity can_demo_tb is
end entity can_demo_tb;

architecture RTL of can_demo_tb is

	
	component can_vhdl_top is
	generic(
		memaddr	 : generic_addr_type;
		addrmask : generic_mask_type
	);
	port(
		clk	 : in std_logic;
		rstn	 : in std_logic;
		wbs_i	 : in wb_slv_in_type;
		wbs_o	 : out wb_slv_out_type;
		rx_i	 : in std_logic;
		tx_o	 : out std_logic;
		irq_on	 : out std_logic
	);
	end component can_vhdl_top;
	
	
	component phys_can_sim 
		generic(
			peer_num : integer );
		port(
			rst : in std_logic;
			rx_vector : out std_logic_vector(peer_num - 1 downto 0);
			tx_vector : in std_logic_vector(peer_num - 1 downto 0) );
	end component phys_can_sim;
	
	
	-- management signal
	signal clk : std_logic := '0';
	signal rst : std_logic := '1';
	signal test_result: rx_check_result;
	--signal tx_frame: std_logic_vector(0 to 108);
	
	-- signals to/from controller 1
	signal wbs_i1 : wb_slv_in_type := wbs_in_default;
	signal wbs_o1 : wb_slv_out_type;
	signal irq_on1 : std_logic;
	
	-- signals to/from controller 
	signal wbs_i2 : wb_slv_in_type:= wbs_in_default;
	signal wbs_o2 : wb_slv_out_type;
	signal irq_on2 : std_logic;
	
	--signals can interconnect
	constant peer_num_inst : integer := 3;
	signal rx_vector : std_logic_vector(peer_num_inst - 1 downto 0);
	signal tx_vector : std_logic_vector(peer_num_inst - 1 downto 0);
	
begin
			
	
	can_inst_1 : component can_vhdl_top
		generic map(
			memaddr=>CFG_BADR_MEM,
			addrmask=>CFG_MADR_FULL
		)
		port map(
			clk	=> clk,
			rstn	=> rst,
			wbs_i	=> wbs_i1,
			wbs_o	=> wbs_o1,
			rx_i	=> rx_vector(0),
			tx_o	=> tx_vector(0),
			irq_on	=> irq_on1);
			
	can_inst_2 : component can_vhdl_top
		generic map(
			memaddr=>CFG_BADR_MEM,
			addrmask=>CFG_MADR_FULL
		)
		port map(
			clk	=> clk,
			rstn	=> rst,
			wbs_i	=> wbs_i2,
			wbs_o	=> wbs_o2,
			rx_i	=> rx_vector(1),
			tx_o	=> tx_vector(1),
			irq_on	=> irq_on2);
			  
	can_interconnect : component phys_can_sim
		generic map(	peer_num => peer_num_inst)
		port map(	rst => rst,
				rx_vector => rx_vector,
				tx_vector => tx_vector);
				
	-- stimuli
	stimuli: process is
	begin
		report "begin stimuli" severity warning;
		--this tx line is used manually
		tx_vector(2) <= '1';
		
		wait for 40 ns;
		rst <= '0';
		

		--setup both can nodes
		write_regs_from_file( "./testdata/default_setup.tdf", wbs_i1, wbs_o1, clk);
		--wait for 1000 ns;
		write_regs_from_file( "./testdata/default_setup.tdf", wbs_i2, wbs_o2, clk);
		
		wait for 1000 ns;
		--setup and execute a 2 byte transmission in controller 1
		write_regs_from_file( "./testdata/data_send.tdf", wbs_i1, wbs_o1, clk);
		tx_vector(2) <= tx_vector(1);
		
		--manual ack by copying controler 2's ack
		wait on tx_vector(1);
		tx_vector(2) <= '0';
		wait for 300 ns;
		tx_vector(2) <= '1';
		
		wait on irq_on2;
		
		--read status register of controller 1
		can_wb_read_reg(wbs_i1, wbs_o1, 2, clk);
		--read from controller 2's read buffer
		read_regs_with_fileaddr("./testdata/data_read.tdf", "read_data0.tdf", wbs_i2, wbs_o2, clk);
		
		wait for 1200 ns;
		--release receive buffer of controller 2
		can_wb_write_reg(wbs_i2, wbs_o2, 1, "00000100", clk);
		
		wait for 1200 ns;
		
		--manually transmit a 2 byte message on tx line 2 (tx_vector(2))
		simulate_can_transmission("11100010111", x"770F000000000000", 2, 300 ns, rx_vector(2), tx_vector(2), test_result);
		tx_vector(2) <= '1';
		
		wait on irq_on2;
		
		--read from both receive buffers
		read_regs_with_fileaddr("./testdata/data_read.tdf", "read_data1.tdf", wbs_i1, wbs_o1, clk);
		read_regs_with_fileaddr("./testdata/data_read.tdf", "read_data2.tdf", wbs_i2, wbs_o2, clk);
		wait for 2400 ns;
		--release both receive buffers
		can_wb_write_reg(wbs_i1, wbs_o1, 1, "00000100", clk);
		can_wb_write_reg(wbs_i2, wbs_o2, 1, "00000100", clk);
		
		wait for 1200 ns;
		report "end stimuli" severity failure;
		wait;
	
	end process stimuli;
	

	-- clock generation
	clock : process is
	begin
		clk <= not clk;
		wait for 10 ns / 2;
	end process clock;
	
-- 	files used in this testbench:
--
-- 	default_setup.tdf:
-- 	4 00000000
-- 	5 11111111
-- 	6 10000000
-- 	7 01001000
-- 	8 00000010
-- 	0 11111110
--
-- 	data_send.tdf:
-- 	10 10101010
-- 	11 11000010
-- 	12 10101010
-- 	13 00001111
-- 	1 00000001
--
-- 	data_read.tdf:
-- 	20
-- 	21
-- 	22
-- 	23

end architecture RTL;
