-- See the file "LICENSE" for the full license governing this code. --
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use ieee.std_logic_arith.all;

library work;
use work.wishbone.all;
use work.config.all;

entity wb_stestwr is
	generic(
		memaddr  	:generic_addr_type :=0;
		addrmask 	:generic_mask_type :=16#3fffff#;
		wbidx		:integer := 0
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    			: in  wb_slv_in_type;
		slvo    			: out wb_slv_out_type;
		led					: out std_logic_vector (7 downto 0)
	);
end entity wb_stestwr;

architecture RTL of wb_stestwr is
	type STATE_TYPE IS (IDLE, WRREQ);
	signal state: STATE_TYPE;
	signal wbslvo : wb_slv_out_type;-- := wbs_out_none;
	
begin

	nxts: process(clk, rst) 
	begin
		if rst = '1' then
			state <= IDLE;
		elsif(rising_edge(clk)) then
			if slvi.cyc='1' and slvi.stb='1' and slvi.we = '1' then 
				state <= WRREQ;
			else
				state <= IDLE;
			end if;
		end if;
		
	end process;
	--**************************************
	ocl: process(state)
	begin
		----if (state=WRREQ and slvi.we = '1' and slvi.stb='1') then
		if (state=WRREQ) then
			wbslvo.dat    <= slvi.dat;
			wbslvo.ack    <= '1';
			--wbslvo.tagn <= ;
			--wbslvo.stall<= ;
			--wbslvo.err  <= ;
			--wbslvo.rty  <= ;
			--wbslvo.wbcfg  <= wb_membar(memaddr, addrmask);
			--wbslvo.wbidx  <= wbidx;
		else
			wbslvo <= wbs_out_none;
		end if;
	end process;
	
	--slvo <= wbslvo;
	slvo.dat  	<=	wbslvo.dat;  
	slvo.ack    <=	wbslvo.ack; 
--   slvo.tagn   <= wbslvo.tagn;
--   slvo.stall  <= wbslvo.stall;
--   slvo.err    <= wbslvo.err;  
--   slvo.rty    <= wbslvo.rty;  

-- wbcfg and wbidx should be assigned directly otw will be delay
   slvo.wbcfg	<=	wb_membar(memaddr, addrmask);  			
   
	--led  <= wbslvo.dat( 7 downto  0);
	-- big/ little endian ?? (suppose to handle in wb_intercon) !!
	led  <=	  wbslvo.dat( 7 downto  0) when slvi.sel(0) = '1' else
			  wbslvo.dat(15 downto  8) when slvi.sel(1) = '1' else
			  wbslvo.dat(23 downto 16) when slvi.sel(2) = '1' else
			  wbslvo.dat(31 downto 24) when slvi.sel(3) = '1' else
			  wbslvo.dat( 7 downto  0);
			  
end architecture RTL;
