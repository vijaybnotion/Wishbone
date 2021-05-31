library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.wishbone.all;
use std.textio.all;
use ieee.std_logic_textio.all;

package can_tp is

	type rx_check_result is (success, can_error, arbitration_lost, no_ack);
	
	constant wbs_in_default : wb_slv_in_type := ( 
		(others=>'-'), 		-- adr
		(others=>'-'),		-- dat
		'-',				-- we
		(others => '-'), 	-- sel
		'0', 				-- stb
		'0', 				-- cyc
		"000",				-- cti
		"00"				-- bte
	);

	procedure can_wb_write_reg(
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		constant addr : integer;
		constant data : in std_logic_vector(7 downto 0);
		signal 	  clk : in std_logic);
		
	procedure can_wb_read_reg(
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		constant addr : integer;
		signal 	  clk : in std_logic);
		
	procedure write_regs_from_file(
		constant filename : in string;
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		signal 	  clk : in std_logic);
		
	procedure read_regs_with_fileaddr(	
		constant filename : in string;
		constant out_filename : in string;
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		signal 	  clk : in std_logic);
		
	function canint2addr(
		constant intaddr : integer
		) return std_logic_vector;
	
	function canint2sel(
		constant intaddr : integer
		) return std_logic_vector;
		
	function data2canwb(
		constant data    : std_logic_vector(7 downto 0)
		) return std_logic_vector;
		
	function can_crc(
		constant stream_vector: in std_logic_vector(0 to 82);
		constant datasize: in integer)return std_logic_vector;
		
	function buildframe(
		constant id: in std_logic_vector(10 downto 0);
		constant data: in std_logic_vector(0 to 63);
		constant datasize: in integer) return std_logic_vector;
	
	function select_bit(
		constant tx_frame_pointer: in integer;
		constant datasize: in integer;
		constant tx_frame: in std_logic_vector(0 to 108)) return std_logic_vector;

	procedure set_bit(
		signal tx: out std_logic;
		constant tx_bit: in std_logic_vector(0 to 4);
		constant t_bit: in time;
		variable tx_history: inout std_logic_vector(3 downto 0));

	procedure simulate_can_transmission(
		constant id : in std_logic_vector(10 downto 0);
		constant data: in std_logic_vector (0 to 63);
		constant datasize: in integer;
		constant t_bit: in time;
		signal rx: in std_logic;
		signal tx: inout std_logic;
		signal test_result: out rx_check_result);
				
end can_tp;

package body can_tp is

	-- convertes the input register address to addr
	function canint2addr(
		constant intaddr : integer
		) return std_logic_vector is variable addr: std_logic_vector(7 downto 0);
	begin
		addr := std_logic_vector(to_unsigned(intaddr, 8));
		return addr;
	end canint2addr;
	
	-- convertes the input register address to select signal
	function canint2sel(
		constant intaddr : integer
		) return std_logic_vector is 
			variable sel: std_logic_vector(3 downto 0);
			variable addr : std_logic_vector(7 downto 0) := std_logic_vector(to_unsigned(intaddr, 8));
	begin
		
		case addr (1 downto 0) is
			when "00" => sel := "1000";
			when "01" => sel := "0100";
			when "10" => sel := "0010";
			when "11" => sel := "0001";
			when others => sel := "1000";
		end case;
		return sel;
	end canint2sel;
	
	--copies the input data to all four possible byte possitions
	function data2canwb(
		constant data    : std_logic_vector(7 downto 0)
		) return std_logic_vector is 
			variable wbcan_data: std_logic_vector(31 downto 0);
	begin
		wbcan_data(31 downto 24) := data;
		wbcan_data(23 downto 16) := data;
		wbcan_data(15 downto 8)  := data;
		wbcan_data(7 downto 0)   := data;
		return wbcan_data;
	end data2canwb;
	
	--does a asynchronous wb-single-write-handshake and writes to an register of the can controller 	
	procedure can_wb_write_reg(
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		constant addr : integer;
		constant data : in std_logic_vector(7 downto 0);
		signal 	  clk : in std_logic) is
	begin
		wbs_in.dat  <= data2canwb(data);
		wbs_in.sel <= canint2sel(addr);
		wbs_in.adr(7 downto 2) <= canint2addr(addr)(7 downto 2);
		wbs_in.stb	<= '1';
		wbs_in.cyc	<= '1';
		wbs_in.we	<= '1';
		
		wait until wbs_out.ack = '1'; --for 1 ps;
		wait until rising_edge(clk);
		
		wbs_in.cyc <= '0';
		wbs_in.stb <= '0';
		wbs_in.we  <= '-';
		wbs_in.sel <= (others=>'-');
		wbs_in.dat <= (others=>'-');
		wbs_in.adr <= (others=>'-');
		
	end can_wb_write_reg;
	
	
	procedure can_wb_read_reg(
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		constant addr : integer;
		signal 	  clk : in std_logic) is
	begin
		wbs_in.sel <= canint2sel(addr);
		wbs_in.adr(7 downto 2) <= canint2addr(addr)(7 downto 2);
		wbs_in.stb	<= '1';
		wbs_in.cyc	<= '1';
		wbs_in.we	<= '0';
		
		wait until wbs_out.ack = '1'; --for 1 ps;
		wait until rising_edge(clk);
		
		
		wbs_in.cyc <= '0';
		wbs_in.stb <= '0';
		wbs_in.we  <= '-';
		wbs_in.sel <= (others=>'-');
		wbs_in.dat <= (others=>'-');
		wbs_in.adr <= (others=>'-');
		
	end can_wb_read_reg; 
	
	
	procedure write_regs_from_file(	
		constant filename : in string;
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		signal 	  clk : in std_logic) is
		
		file sourcefile        : text open read_mode is filename;
		variable input_line     : line;
		variable data           : std_logic_vector(7 downto 0);
		variable addr     	: integer;
	begin
		while not endfile(sourcefile) loop
			readline(sourcefile, input_line);	 --read line
			read(input_line, addr);			 --read addr of register
			read(input_line, data); 		 --read data
			can_wb_write_reg(wbs_in, wbs_out, addr, data, clk);
			wait for 50 ns;
		end loop;
		file_close(sourcefile);
	end procedure write_regs_from_file;
	
	
	procedure read_regs_with_fileaddr(	
		constant filename : in string;
		constant out_filename : in string;
		signal wbs_in : out wb_slv_in_type;
		signal wbs_out : in wb_slv_out_type;
		signal 	  clk : in std_logic) is
		
		file sourcefile        : text open read_mode is filename;
		file targetfile        : text open write_mode is out_filename;
		variable input_line     : line;
		variable output_line     : line;
		variable addr     	: integer;
--		variable data		: std_logic_vector(7 downto 0);
	begin
		while not endfile(sourcefile) loop
			readline(sourcefile, input_line);	 --read line
			read(input_line, addr);			 --read addr of register
			can_wb_read_reg(wbs_in, wbs_out, addr, clk);
			wait for 1 ns;
			write(output_line,addr);
			write(output_line, ' ' );
			write(output_line,wbs_out.dat);
			writeline(targetfile,output_line);
			wait for 49 ns;
		end loop;
		file_close(sourcefile);
		file_close(targetfile);
	end procedure read_regs_with_fileaddr;
	
	function can_crc(
		constant stream_vector: in std_logic_vector(0 to 82);--(0 to (0 to 19+datasize*8-1);
		constant datasize: in integer)return std_logic_vector is
		
		variable crc: std_logic_vector(14 downto 0) := (others=>'0');
		variable crc_tmp: std_logic_vector(14 downto 0);
	begin
		for i in 0 to 19+datasize*8 - 1 loop
			crc_tmp(14 downto 1) := crc(13 downto 0);
			crc_tmp(0) := '0';
			if (stream_vector(i) xor crc(14)) = '1' then
				crc := crc_tmp xor "100010110011001";--x"4599";
			else
				crc := crc_tmp; --110110001111111
			end if;
		end loop;
		return crc;
	end function can_crc;
	
	
	function buildframe(
		constant id: in std_logic_vector(10 downto 0);
		constant data: in std_logic_vector(0 to 63);
		constant datasize: in integer) return std_logic_vector is
		
		variable tx_frame: std_logic_vector(0 to 108);
		variable tmp_stream: std_logic_vector(0 to 82) := (others=>'0');
	begin
		tx_frame(0) 			:= '0'; --start of frame 
		tx_frame(1 to 11) 		:= id(10 downto 0);
		tx_frame(12) 			:= '0'; -- RTR bit (dominant for dataframes)
		tx_frame(13 to 14) 		:= "00"; --reseserved/extended bits
		--error if datasize is to big
		tx_frame(15 to 18)		:= std_logic_vector(to_unsigned(datasize,4)); -- # of bytes to be transmitted (DLC)
		tx_frame(19 to 19+datasize*8-1)	:= data(0 to datasize*8-1);
		tmp_stream(0 to 19+datasize*8-1) := tx_frame(0 to 19+datasize*8-1); -- setup stream for crc calculation
		tx_frame(20+datasize*8-1 to 34+datasize*8-1) := can_crc(tmp_stream, datasize); 
		tx_frame(35+datasize*8-1)	:= '1'; --CRC delimiter (must be recessiv)
		tx_frame(36+datasize*8-1 to 37+datasize*8-1) := "11"; -- ACK and delemiter: ack must be sent as recessiv bit
		tx_frame(38+datasize*8-1 to 44+datasize*8-1) := "1111111"; -- end of frame(EOF): 7 recessiv bits
		--tx_frame(45+datasize*8 to 110) := (others=>X); -- 
		return tx_frame;
	end function buildframe;
	
	
	function select_bit(
		constant tx_frame_pointer: in integer;
		constant datasize: in integer;
		constant tx_frame: in std_logic_vector(0 to 108)) return std_logic_vector is
	
		variable tx_bit: std_logic_vector(0 to 4);
	begin
		tx_bit(0) := tx_frame(tx_frame_pointer); --actual bit to be sent
		if ((tx_frame_pointer <= 11) and (tx_frame_pointer /= 0)) then -- arbitration flag 
			tx_bit(1) := '1';
		else
			tx_bit(1) := '0';
		end if;
		
		if (tx_frame_pointer <= 34+datasize*8-1) then -- stuffing flag is set, if bitstuffing is enabled in this part of the frame
			tx_bit(2) := '1';
		else
			tx_bit(2) := '0';
		end if;
		
		if (tx_frame_pointer = 36+datasize*8-1) then -- ack flag is set if the ack bit in the frame is reached
			tx_bit(3) := '1';
		else
			tx_bit(3) := '0';
		end if;
		
		if (tx_frame_pointer = 44+datasize*8-1) then -- last bit flag is set when the last bit is reached
			tx_bit(4) := '1';
		else
			tx_bit(4) := '0';
		end if;
		
		return tx_bit;
	end function select_bit;
	
	
	procedure set_bit(
		signal tx: out std_logic;
		constant tx_bit: in std_logic_vector(0 to 4);
		constant t_bit: in time;
		variable tx_history: inout std_logic_vector(3 downto 0)) is
	begin
		--bit stuffing is enabled when flag is set
		tx <= tx_bit(0);
		wait for t_bit/2;
		
		if (tx_bit(2) = '1') and (tx_history(0) = tx_history(1)) and (tx_history(1) = tx_history(2)) and (tx_history(2) = tx_history(3)) and (tx_history(3) = tx_bit(0)) then
			
			tx_history(0) := tx_history(1);
			tx_history(1) := tx_history(2);
			tx_history(2) := tx_history(3);
			tx_history(3) := tx_bit(0);
			
			wait for t_bit/2;
			report "stuffing now";
			tx <= not(tx_bit(0));
			wait for t_bit/2;
			
			tx_history(0) := tx_history(1);
			tx_history(1) := tx_history(2);
			tx_history(2) := tx_history(3);
			tx_history(3) := not(tx_bit(0));
		else
			tx_history(0) := tx_history(1);
			tx_history(1) := tx_history(2);
			tx_history(2) := tx_history(3);
			tx_history(3) := tx_bit(0);
		end if;
		
		--report "tx_history(0) " & std_logic'image(tx_history(0));
		--report "tx_history(1) " & std_logic'image(tx_history(1));
		--report "tx_history(2) " & std_logic'image(tx_history(2));
		--report "tx_history(3) " & std_logic'image(tx_history(3));
		
			
	end procedure set_bit;
	
	
	procedure simulate_can_transmission(
		constant id : in std_logic_vector(10 downto 0);
		constant data: in std_logic_vector (0 to 63);
		constant datasize: in integer;
		constant t_bit: in time;
		signal rx: in std_logic;
		signal tx: inout std_logic;
		signal test_result: out rx_check_result) is
		
		variable tx_frame: std_logic_vector(0 to 108);
		variable tx_bit: std_logic_vector(0 to 4):= "00000"; --0: actualmachine bit, 1: arbitration flag, 2: stuffing flag, 3: ack flag, 4:last bit flag
		variable tx_frame_pointer: integer := 0;
		variable tx_history: std_logic_vector(3 downto 0);
		--variable rx_history: std_logic_vector(5 downto 0);
	begin
		tx_frame := buildframe(id, data, datasize);
		while tx_bit(4) = '0' loop --while last bit is not yet reached
			tx_bit := select_bit(tx_frame_pointer, datasize, tx_frame); --selects next bit to be sent and sets flags
			--report "txbit " & std_logic'image(tx_bit(2));
			set_bit(tx, tx_bit, t_bit, tx_history); --handles bit stuffing and tx signal interaction
			--check if arbitration is lostmachine
			if tx_bit(1) = '1' and rx /= tx then 
				test_result <= arbitration_lost;
				return;
			end if;
			-- check if ack is sent by the receiver
			if tx_bit(3) = '1' and rx /= '0' then
				test_result <= no_ack;
				return;
			end if;
			--check if rx = tx if not: error; ausnahmen: arbitration lost, ack 
			if tx_bit(1) = '0' and tx_bit(3) = '0' and rx /= tx then
				test_result <= can_error;
				return;
			end if;
			
			wait for t_bit/2;
		
			tx_frame_pointer := tx_frame_pointer + 1;
		end loop;
		test_result <= success;
		
	end procedure simulate_can_transmission;
	--TODO:
end can_tp;