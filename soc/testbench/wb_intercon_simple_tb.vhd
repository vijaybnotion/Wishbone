-- See the file "LICENSE" for the full license governing this code. --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_textio.all;

library  std;
use      std.standard.all;
use      std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.wb_tp.all;
use work.txt_util.all;
use work.lt16soc_peripherals.all;
use work.lt16soc_memories.all;

ENTITY wb_intercon_simple_tb IS
END wb_intercon_simple_tb;

ARCHITECTURE behavior OF wb_intercon_simple_tb IS

    -- component Declaration for the Unit Under Test (UUT)

    component wb_intercon
	generic(
		slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"0000_0000_0000_0000";
		mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000"
	);
    port(
         clk  : in	std_logic;
         rst  : in	std_logic;
         msti : out	wb_mst_in_vector;
         msto : in	wb_mst_out_vector;
         slvi : out	wb_slv_in_vector;
         slvo : in	wb_slv_out_vector
        );
    end component;

	--Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	signal msto : wb_mst_out_vector;
	signal slvo : wb_slv_out_vector;

	--Outputs
	signal msti : wb_mst_in_vector;
	signal slvi : wb_slv_in_vector;
	signal led	: std_logic_vector(7 downto 0);

	signal data	: std_logic_vector(31 downto 0);

---------------------
-- constant
---------------------
	constant CLK_PERIOD	: time := 10 ns;

	constant slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"1110_0000_0000_0001";
	constant mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"1000";

begin
	-- Instantiate the Unit Under Test (UUT)
   uut: wb_intercon
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

	dmem : wb_dmem
	generic map(
		memaddr=>CFG_BADR_DMEM,
		addrmask=>CFG_MADR_DMEM)
	port map(clk,rst,slvi(CFG_DMEM),slvo(CFG_DMEM));

	leddev : wb_led
	generic map(
		CFG_BADR_LED,CFG_MADR_LED
	)
	port map(
		clk,rst,led,slvi(CFG_LED),slvo(CFG_LED)
	);

	clk_gen	: process
	begin
		clk <= '0';
		wait for CLK_PERIOD/2;
		clk <= '1';
		wait for CLK_PERIOD/2;
	end process;

	stimuli: process
	begin
		rst	<= '1';
		wait for CLK_PERIOD;
		rst	<= '0';

		data	<= x"EDAB3F5C";
		generate_sync_wb_burst_write(msto(0),slvo(CFG_DMEM),clk,data,4);
		data	<= not data;
--		generate_sync_wb_single_write(msto(0),slvo(CFG_DMEM),clk,data);

		wait for 2*CLK_PERIOD;
		generate_sync_wb_burst_read(msto(0),slvo(CFG_DMEM),clk,data,4);

		wait;
	end process stimuli;

END;
