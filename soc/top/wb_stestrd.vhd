-- See the file "LICENSE" for the full license governing this code. --
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use ieee.std_logic_arith.all;

library work;
use work.wishbone.all;
use work.config.all;

entity wb_stestrd is
	generic(
		memaddr :	generic_addr_type := 0;
		addrmask :  generic_mask_type :=	16#3fffff#;
		wbidx: integer := 0
	);
	port(
		clk              	: in  std_logic;
		rst              	: in  std_logic;
		slvi    				: in  wb_slv_in_type;
		slvo    				: out wb_slv_out_type;
		test_rddat				: in 	std_logic_vector(31 downto 0)
	);
end entity wb_stestrd;

architecture RTL of wb_stestrd is
	type STATE_TYPE IS (IDLE, RDREQ);
	signal state: STATE_TYPE;
	signal wbslvo : wb_slv_out_type;-- := wbs_out_none;
	
begin

	nxts: process(clk, rst) 
	begin
		if rst = '1' then
			state <= IDLE;
		elsif(rising_edge(clk)) then
			if slvi.cyc='1' and slvi.stb='1' and slvi.we = '0' then -- need to check cyc ?
				state <= RDREQ;
			else
				state <= IDLE;
			end if;
		end if;
		
	end process;
	--**************************************
	ocl: process(state)
	begin
		--wbslvo.wbcfg  <= wb_membar(memaddr, addrmask);
		--wbslvo.wbidx  <= wbidx;
		
		----if (state=RDREQ and slvi.we = '0' and slvi.stb='1') then
		if (state=RDREQ) then
			wbslvo.dat    <= test_rddat; -- test_data
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

end architecture RTL;
