-- See the file "LICENSE" for the full license governing this code. --
library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_textio.all;

library  std;
use      std.standard.all;
use      std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
 
ENTITY corewrap_tb IS
END corewrap_tb;
 
ARCHITECTURE behavior OF corewrap_tb IS 
 
 	component corewrapper
	generic(
		wbidx: integer := 0
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_imem   : in	imem_core;
		out_imem  : out	core_imem;
		
		in_proc   : in  irq_core;
		out_proc  : out core_irq;
		
		hardfault : out std_logic;
		
		wmsti	:	in	wb_mst_in_type;
		wmsto	:	out	wb_mst_out_type
	);
	end component;
	
    component irq_controller
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;

		in_proc   : in  core_irq;
		out_proc  : out irq_core;

		irq_lines : in  std_logic_vector((2 ** irq_num_width) - 1 downto 0)
	);
	end component;

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal in_imem : imem_core;
   signal in_proc : irq_core;
   signal wmsti : wb_mst_in_type := wbm_in_none;

 	--Outputs
   signal out_imem : core_imem;
   signal out_proc : core_irq;
   signal hardfault : std_logic;
   signal wmsto : wb_mst_out_type;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
   --internal signal 
   	--signal irq2core	: irq_core;
	--signal core2irq	: core_irq;
	signal irq_lines        : std_logic_vector((2 ** irq_num_width) - 1 downto 0) := (others => '0'); 	
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   	uut: corewrapper
	generic map(
		wbidx => CFG_LT16
	)
	port map(
		clk => clk,
        rst => rst,
		
		in_imem		=> in_imem, 
		out_imem	=> out_imem,
		
		in_proc		=> in_proc, 
		out_proc	=> out_proc,
		
		hardfault	=> hardfault,
		
		wmsti		=> wmsti, 
		wmsto		=> wmsto 
	);
	
	irqcontr_inst: irq_controller
	port map(
		clk			=>	clk,
		rst			=>	rst,
		in_proc		=>	out_proc, 
		out_proc	=>	in_proc,  
		irq_lines	=>	irq_lines
	);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	reset : process is
	begin
		rst <= '1';
		wait for 3.5 * clk_period;
		rst <= '0';
		wait;
	end process reset;
	
	irq_stimuli : process is
	begin
		irq_lines(irq_lines'high downto 3) <= (others => '0');
		irq_lines(0) <= '0';
		--irq_lines(1) <= hardfault;
		wait;
	end process irq_stimuli;
	
   -- Stimulus process
   stim_proc: process
   begin		
   --init
	   in_imem.read_data 	<= (others=>'0');
	   in_imem.ready 		<= '0';
	   wmsti 				<= wbm_in_none;
   --end init
   
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

    --------------------------------------
	-- Test_case 00:
	--------------------------------------
	-- No request 
	-- Expected output	all control signal should be inactive
	-- Expected error:	None
	--------------------------------------
	--report ">> TC0 starts <<";
	--------------------------------------
	--data
	assert wmsti.ack = '1'
	report"E-00: No data request, but msti.ack for dmem should always be active"
	severity error;
	
	--ins
	assert in_imem.ready = '1'
	report"E-01: No ins request, but in_imem.ready should always be active"
	severity error;	
	--------------------------------------
	--report ">> TC0 ends <<";
	--------------------------------------
	--
	--E N D Test_case 00
	--
	--------------------------------------

    --/////////////////////////////////////////
	  assert false
	  report ">>>> Simulation beendet!"
      severity failure;
   end process;

END;
