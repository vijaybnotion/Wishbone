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

ENTITY top_tb IS
END top_tb;
 
ARCHITECTURE behavior OF top_tb IS 
--//////////////////////////////////////////////
--
-- component
--
--//////////////////////////////////////////////
--    COMPONENT lt16soc_top
--    PORT(
--         clk : IN  std_logic;
--         rst : IN  std_logic;
--         led : OUT  std_logic_vector(7 downto 0)
--        );
--    END COMPONENT;
   --////////////////////////////////////////////	
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
	--///////////////////////////////////////////////
	component wb_stestrd
		generic(
			memaddr  : generic_addr_type :=0;
			addrmask : generic_mask_type :=CFG_MADR_FULL;
			wbidx: integer := 0
		);
		port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    			: in  wb_slv_in_type;
		slvo    			: out wb_slv_out_type;
		test_rddat			: in	std_logic_vector(31 downto 0)
	);
	end component;
	
	component wb_stestwr
	generic(
		memaddr  : generic_addr_type :=0;
		addrmask : generic_mask_type :=CFG_MADR_FULL;
		wbidx: integer := 0
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    			: in  wb_slv_in_type;
		slvo    			: out wb_slv_out_type;
		led					: out std_logic_vector (7 downto 0)
	);
	end component;
--//////////////////////////////////////////////
-- Signals & constants
--////////////////////////////////////////////// 
	constant clk_period : time := 10 ns;
	constant slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"1110_0000_0000_0000";
	constant mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"1000";

	--base adr
	constant CFG_BADR_TSTS1		: generic_addr_type := 16#28400000#; -- 30bits (32b = A1000000)
	constant CFG_BADR_TSTS2		: generic_addr_type := 16#28800000#; -- 30bits (32b = A2000000)
	
	
	
   --Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';

 	--Outputs
	signal led : std_logic_vector(7 downto 0);
	signal out_byte:  std_logic_vector(7 downto 0);
      
   -- Internal signals 
	signal irq_lines  : std_logic_vector((2 ** irq_num_width) - 1 downto 0) := (others=>'0');
   
	signal slvo	: wb_slv_out_vector := (others=> wbs_out_none);
	signal msto	: wb_mst_out_vector := (others=> wbm_out_none);

	signal slvi	: wb_slv_in_vector := (others=> wbs_in_none);
	signal msti	: wb_mst_in_vector := (others=> wbm_in_none);

	signal core2mem	: core_imem;
	signal mem2core	: imem_core;
	
	signal irq2core	: irq_core;
	signal core2irq	: core_irq;
	
	signal testslave1_o, testslave2_o: wb_slv_out_type := wbs_out_none;
	signal test_rddat: std_logic_vector(31 downto 0) := (others=>'0');
 
begin
--//////////////////////////////////////////////
-- Instantiate
--////////////////////////////////////////////// 
--   uut: lt16soc_top 
--   port map(
--	  clk => clk,
--	  rst => rst,
--	  led => led
--   );

	wbicn_inst: wb_intercon 
	generic map(
		slv_mask_vector => slv_mask_vector,
		mst_mask_vector => mst_mask_vector
	)
	port map(
          clk => clk,
          rst => rst,
          msti => msti,
          msto => msto,
          slvi => slvi,
          slvo => slvo
	);
	
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
		
		wmsti		=> msti(CFG_LT16),
		wmsto		=> msto(CFG_LT16)	  
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
		filename	=> "sample-programs\rawhztest.ram",
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
		
		wslvi		=> slvi(CFG_MEM),
		wslvo		=> slvo(CFG_MEM)
	);
	
	srd01: wb_stestrd
	generic map(
		memaddr	=> CFG_BADR_TSTS1,
		addrmask => CFG_MADR_ZERO,
		wbidx => 1
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave1_o,
		slvi.adr => slvi(1).adr,
		slvi.dat => slvi(1).dat,
		slvi.we  => slvi(1).we,
		slvi.sel => slvi(1).sel,
		slvi.stb => slvi(1).stb,
		slvi.cyc => slvi(1).cyc,
		test_rddat => test_rddat
	);	

	swr02: wb_stestwr
	generic map(
		memaddr => CFG_BADR_TSTS2,
		addrmask => CFG_MADR_ZERO,
		wbidx => 2
	)
	port map(
		clk   => clk, 
		rst   => rst, 
		slvo  => testslave2_o,
		slvi.adr => slvi(2).adr,
		slvi.dat => slvi(2).dat,
		slvi.we  => slvi(2).we,
		slvi.sel => slvi(2).sel,
		slvi.stb => slvi(2).stb,
		slvi.cyc => slvi(2).cyc,
		led => led
	);	 

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
	
--   -- Stimulus process
--   stim_proc: process
--   begin		
--      -- hold reset state for 100 ns.
--      wait for 100 ns;	
--
--      wait for clk_period*10;
--
--      -- insert stimulus here 
--	
--
--      wait;
--   end process;
   
    

end;