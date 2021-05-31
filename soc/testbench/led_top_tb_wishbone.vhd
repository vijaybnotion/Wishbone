library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

library work;
use work.wishbone.all;
use work.config.all;
use work.txt_util.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wb_tp.all;

entity wb_led_tb is
end wb_led_tb;

architecture tb of wb_led_tb is

    component lt16soc_top
		generic(
		programfilename : string := "../../programs/warmup3.ram"
		);
        port (clk      : in std_logic;
              rst      : in std_logic;
              led	   : out std_logic_vector(7 downto 0);
			  button   : in std_logic_vector (4 downto 0);
			  switches : in std_logic_vector (15 downto 0)
			  );
              --wslvi    : in wb_slv_in_type;
              --wslvo    : out wb_slv_out_type);
    end component;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '0';
	signal led 		: std_logic_vector(7 downto 0);
    --signal wslvi    : wb_slv_in_type;
    --signal wslvo    : wb_slv_out_type;
    signal button : std_logic_vector(4 downto 0) := "00000";
    signal switches : std_logic_vector(15 downto 0) := x"0000";
	signal data     : std_logic_vector(31 downto 0) := (others => '0');
    constant TbPeriod : time := 10 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';
    
begin

    dut : lt16soc_top
    port map (clk      => clk,
              rst      => rst,
              led 	   => led,
			  button => button,
			  switches => switches);
              --wslvi    => wslvi,
              --wslvo    => wslvo);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
    clk <= TbClock;
	
    stimuli : process
    begin
		rst <= '0';
		wait for 20ns;
		rst <= '1';
		wait for 10000*TbPeriod;
		assert false report "Simulation Terminated" severity failure;
    end process;

end tb;


