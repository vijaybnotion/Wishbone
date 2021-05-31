Library Ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;


USE work.lt16x32_global.ALL;
USE work.wishbone.ALL;
USE work.config.ALL;

entity led_buffer is
	port(
		clk 		 : in std_logic;
		rst 		 : in std_logic;
		buffer_clear : in std_logic;
		buffer_write : in std_logic;
		buffer_data  : in std_logic_vector(7 downto 0);
		next_pattern : in std_logic;
		led_pattern  : out std_logic_vector(7 downto 0)
	);
end led_buffer;


architecture rtl of led_buffer is

constant addr_w : integer := 4;
constant data_w : integer := 8;
constant buff_l : integer := 16;

-- Creating the pointers
type reg_file_type is array (0 to (2 ** ADDR_W) - 1) of std_logic_vector(data_w-1 downto 0);

-- Memory array and pointers
signal mem_array : reg_file_type;
signal ptr_write : integer range 0 to buff_l -1;
signal ptr_read : integer range 0 to buff_l -1; 
signal ptr_last : integer range -1 to buff_l -1;
signal fillcount : integer := 0;
begin

	readbuffer: process(rst, next_pattern)
	begin
		if rst = '1' or buffer_clear = '1' then
			ptr_read  <=  0;
		elsif rising_edge(next_pattern) then
			if ptr_last /= -1 then
				
                
                if ptr_read <= ptr_last then
               		fillcount <= ptr_last - ptr_read;
                else
                	fillcount <= ptr_last - ptr_read + buff_l;
                end if;

                
                if fillcount >= 0 then
                    if (ptr_read /= buff_l - 1) and (ptr_read < ptr_last) then
				        ptr_read <= ptr_read + 1; 
				    elsif (ptr_read /= buff_l - 1) and (ptr_read >= ptr_last) then
				        ptr_read <= 0;
    				elsif ptr_read = buff_l -1 then 
	       			    ptr_read <= 0;
				    end if;
                end if;
                
			else
				led_pattern <= (others => '0');
			end if;
			led_pattern <= mem_array(ptr_read);
          end if;
	end process;
	
	writebuffer : process(rst, buffer_write, buffer_clear)
	begin
		if rst = '1' or buffer_clear = '1' then
		    ptr_write <=  0;
            ptr_last  <= -1;
            for i in 0 to mem_array'LENGTH - 1 loop
                mem_array(i) <= x"00";
            end loop;
		elsif buffer_write = '1' then
			mem_array(ptr_write) <= buffer_data;
			ptr_last <= ptr_write;
			if ptr_write /= buff_l -1 then
			     ptr_write <= ptr_write + 1; 
			else 
			     ptr_write <= 0;
			end if;
		end if;
	end process;
end architecture;