LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
library work;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;
use work.wb_tp.all;
 
ENTITY dmem_test IS
END dmem_test;
 
ARCHITECTURE behavior OF dmem_test IS 

	COMPONENT wb_dmem is
	generic(
		memaddr		:	generic_addr_type;
		addrmask	:	generic_mask_type := CFG_MADR_DMEM
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
	end COMPONENT;

	--Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	signal wslvi : wb_slv_in_type := wbs_in_none;

	--Outputs
	signal wslvo : wb_slv_out_type;

	-- Clock period definitions
	constant clk_period : time := 10 ns;
	
	type block_array is array (0 to 63) of std_logic_vector(7 downto 0);
	type ram_array is array (0 to 3) of block_array;
	constant test_values : ram_array := (
		(x"00", x"04", x"08", others=>x"00"),
		(x"01", x"05", x"09", others=>x"00"),
		(x"02", x"06", x"0a", others=>x"00"),
		(x"03", x"07", x"0b", others=>x"00")
	);
	
	signal readdata : std_logic_vector(WB_PORT_SIZE -1 downto 0);
	signal writedata : std_logic_vector(WB_PORT_SIZE -1 downto 0);
	
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: wb_dmem 
	generic map(memaddr=>0)
	PORT MAP(clk => clk, rst => rst, wslvi => wslvi, wslvo => wslvo);
	
	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;
   
	-- Stimulus process
	stim_proc: process
	begin
	rst <= '1';
	wait for 100 ns;
	rst <= '0';
	wait until falling_edge(clk);
	
	for i in 0 to 63 loop
		--test 1: write word, read bytes
		
		-- assume word data is always given in little endian
		writedata <= test_values(3)(i) & test_values(2)(i) & test_values(1)(i) & test_values(0)(i); 
		
		wait until falling_edge(clk);
		generate_async_wb_slave_writeaccess(
			slvi=>wslvi,
			slvo=>wslvo, 
			writedata=>writedata
			);
			
		wait for clk_period;
		
		for j in 0 to 3 loop
			
			generate_async_wb_slave_readaccess(
				slvi=>wslvi,
				slvo=>wslvo,
				readdata=>readdata,
				adr_offset=>j,
				size=>"00"
				);
			--wait for 1 ps;
			assert readdata(7 downto 0)=test_values(j)(i) report "Wrong value read!" severity error;
			wait until falling_edge(clk);
		end loop;
		
	end loop;

	
	wait for clk_period*10;

	assert false report "Simulation Finished!" severity failure;
	end process;

END;
