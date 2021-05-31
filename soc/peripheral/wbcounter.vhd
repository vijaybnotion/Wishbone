library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;


entity wb_timer is
	generic(
		memaddr		:	generic_addr_type := CFG_BADR_TIMER;
		addrmask	:	generic_mask_type := CFG_MADR_TIMER
	);
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		wslvi		: in  wb_slv_in_type;
		wslvo		: out wb_slv_out_type;
		irq_out		: out std_logic
	);
end wb_timer;

architecture Behavioral of wb_timer is

	signal data : std_logic;
	signal ack	: std_logic;
	signal tarv : std_logic_vector(31 downto 0); -- target counter value
	signal cntf : std_logic_vector(31 downto 0) := (others => '0'); -- control flags, en, rpt, rst
	signal interrupt : std_logic := '0'; -- interrupt signal
	
begin

	process(clk) is
	
	variable int_count : integer := 0;
	variable en : std_logic := '0';
	variable rpt : std_logic := '0';
	variable rst : std_logic := '0';
	
	begin
		if clk'event and clk='1' then
			if rst = '1' then
				ack		<= '0';
				data	<= '0';
				int_count := 0;
				 en := '0';
				 rpt := '0';
				 rst := '0';
				 interrupt <= '0';
				 cntf <= (others => '0');

			else
				
					if wslvi.stb = '1' and wslvi.cyc = '1' then
						if wslvi.we='1' then
						
						if (wslvi.adr(2)='0') then -- for target value counter register, 2nd bit 0 for 8
								tarv	<= dec_wb_dat(wslvi.sel,wslvi.dat)(31 downto 0);
								
							elsif(wslvi.adr(2)='1') then -- for control flag register, 2nd bit 0 for C
								cntf	<= dec_wb_dat(wslvi.sel,wslvi.dat)(31 downto 0);
								en := cntf(2);
								rpt := cntf(1);
								rst := cntf(0);
							end if;
							
						end if;
						if ack = '0' then
							ack	<= '1';
						else
							ack	<= '0';
						end if;
					else
						ack <= '0';
					end if;
					
				interrupt <= '0';	
				
		           if (en = '1' and int_count /= to_integer(unsigned(tarv))) then --incrementing counter if en is 1 and counter value not reached 
						int_count := int_count + 1;			
						interrupt <= '0';
						
			    elsif (en = '1' and int_count = to_integer(unsigned(tarv)) ) then -- generate interrrupt when counter values reached
							interrupt <= '1';
							if (rpt = '0') then -- if repeat set to 0
								en := '0';
								int_count := 0;	
								
							else
								en := '1'; -- if repeat set to 1, restart counter by enabling countret flag
								int_count := 0;							
							end if;
			    else
						interrupt <= '0';
					end if;
					if (rst = '1') then   -- reset the counter
						interrupt <= '0';
						int_count := 0;
						rst := '0';
					end if;
					
			end if; 
		end if;
	end process;


	wslvo.dat(31 downto 0)	<= (others=>'0');
	--led <= data;
	irq_out <= interrupt;
	wslvo.ack	<= ack;
	wslvo.wbcfg	<= wb_membar(memaddr, addrmask);

end Behavioral;


