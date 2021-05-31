-- See the file "LICENSE" for the full license governing this code. --
--test bench
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

 
ENTITY corewbmem_tb IS
END corewbmem_tb;
 
ARCHITECTURE behavior OF corewbmem_tb IS 
--//////////////////////////////////////////////
-- component
--//////////////////////////////////////////////
component core
	port(clk       : in  std_logic;
		 rst       : in  std_logic;
		 stall     : in  std_logic;
		 in_dmem   : in  dmem_core;
		 out_dmem  : out core_dmem;
		 in_imem   : in  imem_core;
		 out_imem  : out core_imem;
		 in_irq    : in  irq_core;
		 out_irq   : out core_irq;
		 hardfault : out std_logic);
end component core;
	
component memdiv
--component memory
generic(
	filename     : in string  := "program.ram";
	size         : in integer := 256;
	imem_latency : in time    := 5 ns;
	dmem_latency : in time    := 5 ns;
	dmemsz		:	integer := DMEMSZ;
	imemsz		:	integer := IMEMSZ
);
port(
	clk      : in  std_logic;
	rst      : in  std_logic;

	in_dmem  : in  core_dmem;
	out_dmem : out dmem_core;

	in_imem  : in  core_imem;
	out_imem : out imem_core;

	fault    : out std_logic;
	out_byte : out std_logic_vector(7 downto 0));
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
	
component core2wb
	generic(
		wbidx: integer := 0
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_dmem   : out  dmem_core;
		out_dmem  : in core_dmem;
		
		-- wb master port
		wmsti	:	in	wb_mst_in_type;
		wmsto	:	out	wb_mst_out_type
	);
end component;

component mem2wb
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_MEM;
		addrmask	:	generic_mask_type := CFG_MADR_MEM;
		wbidx		:	integer := CFG_MEM
	);
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;
		
		in_dmem   : out core_dmem;
		out_dmem  : in 	dmem_core;
		
		wslvi	:	in	wb_slv_in_type;
		wslvo	:	out	wb_slv_out_type
	);
end component;
    
--//////////////////////////////////////////////
-- signal 
--//////////////////////////////////////////////
-- Clock period definitions
   constant clk_period : time := 10 ns;
   constant slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"1000_0000_0000_0000";
   constant mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"1000";
   
   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';

   	-- signals between instances
	
	signal core2dm_sc : core_dmem;
	signal core2dm_sm : core_dmem;
	signal dm2core_sc : dmem_core;
	signal dm2core_sm : dmem_core;
	
	signal imem_proc_signal : imem_core;
	signal proc_imem_signal : core_imem;
	
	signal irq_proc_signal  : irq_core;
	signal proc_irq_signal  : core_irq;
	signal irq_lines        : std_logic_vector((2 ** irq_num_width) - 1 downto 0);
	
	--signal slvi	:	wb_slv_in_type 	;--:= wbs_in_none;
	--signal msti	:	wb_mst_in_type 	;--:= wbm_in_none;
	
	signal slvo	:	wb_slv_out_type	:= wbs_out_none;
	signal msto	:	wb_mst_out_type	:= wbm_out_none;
	
	signal out_byte: std_logic_vector(7 downto 0);
	--signal hardfault: std_logic;
	--signal fault: 	std_logic;
	
BEGIN
 --//////////////////////////////////////////////
-- instantiation
--//////////////////////////////////////////////
----------
--core
----------
core_inst : component core
	port map(
	clk       => clk,
	 rst       => rst,
	 stall     => '0',
	 
	 in_dmem   => dm2core_sc,
	 out_dmem  => core2dm_sc,
	 
	 in_imem   => imem_proc_signal,
	 out_imem  => proc_imem_signal,
	 
	 in_irq    => irq_proc_signal,
	 out_irq   => proc_irq_signal,
	 hardfault => irq_lines(1)
);
----------
--memdiv
----------	
	mem_inst: memdiv
	--mem_inst: memory
	generic map(
		filename		=> "test_endianess2.ram",
		size			=>	DMEMSZ + IMEMSZ,
		imem_latency	=>	0 ns,
		dmem_latency	=>	0 ns,
		dmemsz			=>	DMEMSZ,
		imemsz			=>	IMEMSZ
	)
	port map(
		clk			=>	clk,
		rst			=>	rst,
		
		in_dmem		=>	core2dm_sm,
		out_dmem	=>	dm2core_sm,
		
		in_imem		=>	proc_imem_signal,
		out_imem	=>	imem_proc_signal,
		
		fault		=>	irq_lines(2),
		out_byte	=>	out_byte
	);	
----------
--irq
----------
	irqcontr_inst: irq_controller
	port map(
		clk			=>	clk,
		rst			=>	rst,
		in_proc		=>	proc_irq_signal,
		out_proc	=>	irq_proc_signal,
		irq_lines	=>	irq_lines
	);
	
----------
--core2wb
----------	
	core2wb0: core2wb
	generic map(
		wbidx => CFG_LT16
	)
	port map(
		clk		=> clk,
		rst    	=> rst,
		
		in_dmem		=> dm2core_sc,
		out_dmem 	=> core2dm_sc,
		
		--wmsti	=> msti,
		wmsti.dat => slvo.dat,
		wmsti.ack => slvo.ack,
		
		wmsto	=> msto
	);
	
----------
--mem2wb
----------		


mem2wb0: mem2wb
	generic map(
		memaddr		=> CFG_BADR_MEM,
		addrmask	=> CFG_MADR_MEM,
		wbidx 		=> CFG_MEM
		)
	port map(
		clk 		=> clk,
		rst			=> rst,
		
		in_dmem		=> core2dm_sm,
		out_dmem  	=> dm2core_sm,
		
		--wslvi		=> slvi,
		wslvi.adr  => msto.adr,
		wslvi.dat  => msto.dat,
		wslvi.we   => msto.we,
		wslvi.sel  => msto.sel,
		wslvi.stb  => msto.stb, 
		wslvi.cyc  => msto.cyc, 
		--
		wslvo		=> slvo
	);
	
	
   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
	-- reset stimuli
	reset : process is
	begin
		rst <= '1';
		wait for 3.5 * clk_period;
		rst <= '0';
		wait;
	end process reset;
	
	
	-- irq line stimuli
	irq_stimuli : process is
	begin
		irq_lines(irq_lines'high downto 3) <= (others => '0');
		irq_lines(0) <= '0';
		-- irq0 is reset
		-- irq1 is hardfault
		-- irq2 is memfault

		--		wait for 600 ns;
				
		--		wait until rising_edge(clk);
		--		irq_lines(3) <= '1';
		--		irq_lines(4) <= '1';
		--		wait until rising_edge(clk);
		--		irq_lines(3) <= '0';
		--		irq_lines(4) <= '0';

		wait;

	end process irq_stimuli;
	
	
	
--   -- Stimulus process
--   stim_proc: process
--   begin		
--
----      wait for clk_period*10;
--
----      	slvi.adr  <= msto.adr;
----		slvi.dat  <= msto.dat;
----		slvi.we   <= msto.we; 
----		slvi.sel  <= msto.sel;
----		slvi.stb  <= msto.stb; 
----		slvi.cyc  <= msto.cyc; 
----		
--		---
----		msti.dat <= slvo.dat;
----		msti.ack <= slvo.ack;
--
--      wait;
--   end process;

END;
