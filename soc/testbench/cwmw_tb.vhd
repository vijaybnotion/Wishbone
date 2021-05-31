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

ENTITY cwmw_tb IS
END cwmw_tb;
 
ARCHITECTURE behavior OF cwmw_tb IS 
--//////////////////////////////////////////////
--
-- component
--
--//////////////////////////////////////////////
	component wb_intercon
	generic(
		slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"0000_0000_0000_0000"; 
		mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000";
		dat_sz: integer	:= WB_PORT_SIZE;
		adr_sz: integer	:= WB_ADR_WIDTH;
		nib_sz: integer	:= WB_PORT_GRAN
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		msti    			: out wb_mst_in_vector;
		msto    			: in  wb_mst_out_vector;
		slvi    			: out wb_slv_in_vector;
		slvo    			: in  wb_slv_out_vector 
	);
	end component;
	--////////////////////////////////////////////	
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
	
	component memwrapper
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask	:	generic_mask_type := CFG_MADR_MEM;
		wbidx		:	integer := CFG_MEM;
		filename	:	string  := "program.ram";
		dmemsz		:	integer := DMEMSZ;
		imemsz		:	integer := IMEMSZ
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_imem    : in   core_imem;
		out_imem   : out  imem_core;
		
		fault    : out std_logic;
		out_byte : out std_logic_vector(7 downto 0);
		
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
	end component;
	
--//////////////////////////////////////////////
-- Signals & constants
--////////////////////////////////////////////// 
	constant clk_period : time := 10 ns;
	constant filename   : string  := "rdmem.ram";
	
	constant slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"1000_0000_0000_0000";
	constant mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"1000";

	--Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';

 	--Outputs
	signal out_byte:  std_logic_vector(7 downto 0);
      
   -- Internal signals 
	signal irq_lines  : std_logic_vector((2 ** irq_num_width) - 1 downto 0) := (others=>'0');
   
	signal slvo: wb_slv_out_type :=  wbs_out_none;
	signal msto: wb_mst_out_type :=  wbm_out_none;

	signal core2mem	: core_imem;
	signal mem2core	: imem_core;
	
	signal irq2core	: irq_core;
	signal core2irq	: core_irq;
	
 
begin

   	corewrap_inst: corewrapper
	generic map(
		wbidx => CFG_LT16
	)
	port map(
		clk => clk,
        rst => rst,
		
		in_imem		=> mem2core,
		out_imem	=> core2mem, 
		
		in_proc		=> irq2core,
		out_proc	=> core2irq,
		
		hardfault	=> irq_lines(1),
		
		wmsti.dat		=> slvo.dat,
		wmsti.ack		=> slvo.ack,
		wmsto	=> msto
	);
	

	irqcontr_inst: irq_controller
	port map(
		clk			=>	clk,
		rst			=>	rst,
		in_proc		=>	core2irq,
		out_proc	=>	irq2core,
		irq_lines	=>	irq_lines
	);
	
	memwrap_inst: memwrapper
	generic map(
		memaddr		=> CFG_BADR_MEM, 
		addrmask	=> CFG_MADR_MEM,
		wbidx 		=> CFG_MEM,
		filename	=> filename,
		dmemsz		=> DMEMSZ,
		imemsz		=> IMEMSZ
	)
	port map(
		clk 		=> clk,
        rst 		=> rst,
		in_imem		=> core2mem,
		out_imem	=> mem2core, 
		
		fault		=> irq_lines(2),
		out_byte	=> out_byte,
		wslvi.adr 	=> msto.adr,
		wslvi.dat 	=> msto.dat,
		wslvi.we 	=> msto.we,
		wslvi.sel 	=> msto.sel,
		wslvi.stb 	=> msto.stb,
		wslvi.cyc 	=> msto.cyc,
		wslvo		=> slvo
	);
--//////////////////////////////////////////////

--//////////////////////////////////////////////
-- Process
--//////////////////////////////////////////////		
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
		wait;
	end process irq_stimuli;	
	

end;