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
 
ENTITY memdiv_tb IS
END memdiv_tb;
 
ARCHITECTURE behavior OF memdiv_tb IS 
 

    COMPONENT memdiv
	generic(
		filename     : in string  := "program.ram";
		size         : in integer := 256;
		imem_latency : in time    := 5 ns;
		dmem_latency : in time    := 5 ns
	);
    PORT(
		clk      : in  std_logic;
		rst      : in  std_logic;
		in_dmem  : in  core_dmem;
		out_dmem : out dmem_core;
		in_imem  : in  core_imem;
		out_imem : out imem_core;
		fault    : out std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal in_dmem : core_dmem;
   signal in_imem : core_imem;

 	--Outputs
   signal out_dmem 	: dmem_core;
   signal out_imem 	: imem_core;
   signal fault 	: std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   
	
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: memdiv 
 	generic map (
		filename		=>	"sample-programs\dummy.ram",
		--size			=>	IMEMSZ,
		imem_latency	=>	0 ns,
		dmem_latency	=>	0 ns
	)
   PORT MAP (
          clk 		=> clk,
          rst 		=> rst,
          in_dmem 	=> in_dmem,
          out_dmem 	=> out_dmem,
          in_imem 	=> in_imem,
          out_imem	=> out_imem,
          fault 	=> fault
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
	end process;
	
   -- Stimulus process
   stim_proc: process
	
   begin		
   		--init
		in_imem.read_en 	<= '0';
		in_imem.read_addr <= (others=>'0');
		--
		in_dmem.read_en	<= '0';
		in_dmem.read_addr	<= (others=>'0');
		in_dmem.read_size <= "00";
		--
		in_dmem.write_en	<= '0';
		in_dmem.write_addr<= (others=>'0');
		in_dmem.write_size <= "00";
		in_dmem.write_data<= (others=>'0');
		--end init
		
      -- hold reset state for 100 ns.
		wait for 100 ns;	
		wait for clk_period*10;

--		in_imem.read_en 	<= '1'; 
		
		
--		in_imem.read_addr   <= x"00000000"; wait for clk_period; -- wait until out_imem.ready = '1'; 
--		assert out_imem.read_data = x"C4050000"
--		report "E-00: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--
--		in_imem.read_addr   <= x"00000004"; wait for clk_period;
--		assert out_imem.read_data = x"C0000000"
--		report "E-01: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		in_imem.read_addr   <= x"00000008"; wait for clk_period;
--		assert out_imem.read_data = x"C0000000"
--		report "E-02: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--				
--		in_imem.read_addr   <= x"0000000C"; wait for clk_period;
--		assert out_imem.read_data = x"00000111"
--		report "E-03: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		in_imem.read_addr   <= x"00000010"; wait for clk_period;
--		assert out_imem.read_data = x"02220333"
--		report "E-04: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		in_imem.read_addr   <= x"00000014"; wait for clk_period;
--		assert out_imem.read_data = x"04447055"
--		report "E-05: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		
--		in_imem.read_addr   <= x"00000018"; wait for clk_period;
--		assert out_imem.read_data = x"0100720A"
--		report "E-06: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--				
--		
--		in_imem.read_addr   <= x"0000001C"; wait for clk_period;
--		assert out_imem.read_data = x"532F533B"
--		report "E-07: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		in_imem.read_addr   <= x"00000020"; wait for clk_period;
--		assert out_imem.read_data = x"A403BA43"
--		report "E-08: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		
--		in_imem.read_addr   <= x"00000024"; wait for clk_period;
--		assert out_imem.read_data = x"C4FF0000"
--		report "E-09: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;
--		
--		
--		in_imem.read_addr   <= x"00000028"; wait for clk_period;
--		assert out_imem.read_data = x"000003C0"
--		report "E-10: RD req addr: " & hstr(in_imem.read_addr) & ", Return read_data: " & hstr(out_imem.read_data)
--		severity error;

--//////////////////////////////////////////////////////////
-------------------------------------------------------
-- Test case 00: dmem_read only, read byte
-- Read size = 00 (8 bits)
-- Address: 0000_000C
--			wordaddress = 0x03
--			byteaddress = 00 - 11
-- word value at address: 0000_0000C = I003
-------------------------------------------------------
		in_dmem.read_en		<= '1';
		in_dmem.read_size	<= "00";
		--
		in_dmem.write_en	<= '0';
		in_dmem.write_addr	<= (others=>'0');
		in_dmem.write_size 	<= "00";
		in_dmem.write_data	<= (others=>'0');
		--
		in_dmem.read_addr	<= x"0000000C";	wait for clk_period; -- wadr = 0x03, badr = B0
		assert out_dmem.read_data = x"00000049" -- (ascii) val = I 
		report "E-D00: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000D";	wait for clk_period; -- wadr = 0x03, badr = B1
		assert out_dmem.read_data = x"00000030" -- (ascii) val = 0
		report "E-D01: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000E";	wait for clk_period; -- wadr = 0x03, badr = B2
		assert out_dmem.read_data = x"00000030" -- (ascii) val = 0
		report "E-D02: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000F";	wait for clk_period; -- wadr = 0x03, badr = B3
		assert out_dmem.read_data = x"00000033" -- (ascii) val = 3
		report "E-D03: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		wait for clk_period;
-------------------------------------------------------
-- Test case 01: dmem_write only, write byte
-- write size = 00 (8 bits)
-- Address: 0000_0011
--			wordaddress = 0x04
--			byteaddress = 00 - 11
-- org word value at address: 4930_3034 = I004
-- new word value at address: 4934_3034 = I404
-------------------------------------------------------
		in_dmem.read_size	<= "00";
		--
		in_dmem.write_en	<= '1';
		in_dmem.write_size 	<= "00";
		--
		--Read org value before write
		in_dmem.read_en		<= '1'; in_dmem.read_addr	<= x"00000011";	wait for clk_period;
		report "RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity note;
		
		--write
		in_dmem.read_en		<= '0'; 
		in_dmem.write_addr	<= x"00000011";	in_dmem.write_data	<= x"00000034"; -- (ascii) val = 4
		wait for clk_period; -- wadr = 0x04, badr = B1
		
		assert out_dmem.ready = '1'
		report "E-D10: WR req addr: " & hstr(in_dmem.write_addr) & ", No Return ack "
		severity error;
		
		--Read  writtem value after write
		in_dmem.read_en		<= '1'; in_dmem.read_addr	<= x"00000011";	wait for clk_period;
		assert out_dmem.read_data = x"00000034" -- (ascii) val = 4
		report "E-D11: Check written value: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
-------------------------------------------------------
-- Test case 02: simultaneous read and write with different address
-- read / write size = 00 (8 bits)
-- Read Address: 0000_000C
--			wordaddress = 0x03
--			byteaddress = 00 - 11
-- word value at address: 0000_0000C = I003
--
-- Write Address: 0000_0015
--			wordaddress = 0x05
--			byteaddress = 00 - 11
-- org word value at address: 4930_3035 = I005
-- new word value at address: 4935_3035 = I505
-------------------------------------------------------
		in_dmem.read_en		<= '1';
		in_dmem.read_size	<= "00";
		--
		in_dmem.write_en	<= '1';
		in_dmem.write_size 	<= "00";
		
		--Read org value before write
		in_dmem.read_addr	<= x"00000015";	wait for clk_period;
		report "RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity note;
		
		--start
		wait for clk_period;
		in_dmem.read_addr	<= x"0000000C";	
		in_dmem.write_addr	<= x"00000015";	in_dmem.write_data	<= x"00000035"; -- (ascii) val = 5
		
				
		wait for clk_period; -- wadr = 0x03, badr = B0
		--assert for read
		assert out_dmem.read_data = x"00000049" -- (ascii) val = I 
		report "E-D20: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		--assert for write_ack
		assert out_dmem.ready = '1'
		report "E-D20: WR req addr: " & hstr(in_dmem.write_addr) & ", No Return ack "
		severity error;
		
		--asesert for write data
		--Read  written value after write
		in_dmem.read_en		<= '1'; in_dmem.read_addr	<= x"00000015";	wait for clk_period;
		assert out_dmem.read_data = x"00000035" -- (ascii) val = 5
		report "E-D21: Check written value: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000D";	wait for clk_period; -- wadr = 0x03, badr = B1
		assert out_dmem.read_data = x"00000030" -- (ascii) val = 0
		report "E-D22: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000E";	wait for clk_period; -- wadr = 0x03, badr = B2
		assert out_dmem.read_data = x"00000030" -- (ascii) val = 0
		report "E-D23: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		in_dmem.read_addr	<= x"0000000F";	wait for clk_period; -- wadr = 0x03, badr = B3
		assert out_dmem.read_data = x"00000033" -- (ascii) val = 3
		report "E-D24: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;

-------------------------------------------------------
-- Test case 03: simultaneous read and write with same address
-- read / write size = 00 (8 bits)
-- Read/Write Address: 0000_001D
--			wordaddress = 0x07
--			byteaddress = 00 - 11
-- word value at address: 4930_3037 = I007
--
-- org word value at address: 4930_3037 = I007
-- new word value at address: 4935_3037 = I707
--
-- Result:
-- it reads before write i.e. obtaining old value
-------------------------------------------------------
		
		in_dmem.read_en		<= '1';
		in_dmem.read_addr	<= x"0000001D";
		in_dmem.read_size	<= "00";
		--
		in_dmem.write_en	<= '1';
		in_dmem.write_addr	<= x"0000001D";
		in_dmem.write_size 	<= "00";
		in_dmem.write_data	<= x"00000037"; -- (ascii) val = 7
		wait for clk_period;

		--Fail if assuming read after write, the new value should be read
		assert out_dmem.read_data = x"00000037" -- (ascii) val = 7
		report "E-D30: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		
		--assert for write ack
		assert out_dmem.ready = '1'
		report "E-D31: WR req addr: " & hstr(in_dmem.write_addr) & ", No Return ack "
		severity error;
		
		
		wait for clk_period;
		assert out_dmem.read_data = x"00000037" -- (ascii) val = 7
		report "E-D32: RD req addr: " & hstr(in_dmem.read_addr) & ", Return read_data: " & hstr(out_dmem.read_data)
		severity error;
		

	  --/////////////////////////////////////////
	  assert false
	  report ">>>> Simulation beendet!"
      severity failure;
      --wait;
   end process;

END;
