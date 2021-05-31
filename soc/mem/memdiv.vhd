-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use std.textio.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_global.all;
use work.config.all;

-- the memory handles all memory transactions from the processor
-- it could be extended to have bus accesses to communicate to the outside world.
-- also, artificial latency can be inserted for simulation purposes.
entity memdiv is
	generic(
		-- name of file for initialization, formatted as lines of 32 ones or zeroes, each describing one word.
		filename     : in string  := "program.ram";
		-- size in words (32bit)
		size         : in integer := IMEMSZ;
		-- latency of the instruction memory interface
		imem_latency : in time    := 5 ns;
		-- latency of the data memory interface
		dmem_latency : in time    := 5 ns
	);
	port(
		-- clock signal
		clk      : in  std_logic;
		-- reset signal, active high, synchronous
		rst      : in  std_logic;

		-- dmem signals from the processor
		in_dmem  : in  core_dmem;
		-- dmem signals to the processor
		out_dmem : out dmem_core;

		-- imem signals from the processor
		in_imem  : in  core_imem;
		-- imem signals to the processor
		out_imem : out imem_core;

		-- fault signal, active high
		fault    : out std_logic
	);
end entity memdiv;

architecture RTL of memdiv is
	constant width : integer := 32;

	-- construct to have in_simulation and in_synthesis for generates in this module
	constant in_simulation : boolean := false
	-- synthesis translate_off
	or true
	-- synthesis translate_on
	;
	constant in_synthesis : boolean := not in_simulation;

	-- type for the memory signal
	type memory_type is array (0 to size - 1) of std_logic_vector(width - 1 downto 0);
	-- type for dmem_write fsm
	type write_states is (read_old, write_new);
	
	-- this function initializes an array of memory_type with the contents of a given file
	-- function from http://myfpgablog.blogspot.de/2011/12/memory-initialization-methods.html
	--      and from http://www.stefanvhdl.com/vhdl/html/file_read.html
	--      and from http://www.ee.sunysb.edu/~jochoa/vhd_writefile_tutorial.htm
	impure function init_mem(mif_file_name : in string) return memory_type is
		-- input file
		file mif_file : text open read_mode is mif_file_name;
		-- input file read line
		variable mif_line : line;

		-- temporary bit vector for data read from file
		variable temp_bv  : bit_vector(width - 1 downto 0);
		-- temporary memory array
		variable temp_mem : memory_type;
		-- read function success value
		variable good     : boolean;
	begin
		for i in memory_type'range loop
			if not endfile(mif_file) then
				-- if no end of input file, read next line
				readline(mif_file, mif_line);
				-- match line into bit vector
				read(mif_line, temp_bv, good);

				-- synthesis translate_off
				assert good report ("Non-good word in memory location " & integer'image(i)) severity warning; --! give a warning when readline is no good -TF 2014-05-20
				-- synthesis translate_on

				-- copy temporary bit vector into temporary memory array
				temp_mem(i) := to_stdlogicvector(temp_bv);
			else
				-- EOF but memory not yet full, fill up with zeros
				temp_mem(i) := (others => '0');
			end if;
		end loop;

		-- check if program fit into memory
		if not endfile(mif_file) then
			assert false report "memory not large enough for loaded program." severity failure;
		end if;

		-- give back filled array
		return temp_mem;
	end function;

	-- memory array
	signal memory : memory_type := init_mem(filename);

	-- internal data signals for use with ready signals in simulation
	signal imem_data : std_logic_vector(width - 1 downto 0);
	signal dmem_data : std_logic_vector(width - 1 downto 0);

	-- fault signal for dmem read fault
	signal dmem_read_fault  : std_logic;
	-- fault signal for dmem write fault
	signal dmem_write_fault : std_logic;
	-- fault signal for imem read faults
	signal imem_read_fault  : std_logic;
	
	signal old_word		: std_logic_vector(width - 1 downto 0);
	signal in_dmem_reg	: core_dmem;
	signal mem_ready	: std_logic;
	signal write_state	: write_states;
begin

	-- fault logic
	fault <= dmem_read_fault or dmem_write_fault or imem_read_fault;

	-- imem read
	imem_read : process(clk) is
		-- calculated word address
		variable wordaddress : integer;
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- in reset zero output and no fault
				imem_data       <= (others => '0');
				imem_read_fault <= '0';

			elsif (in_imem.read_en = '1') then
				-- if read enabled

				-- standard output
				imem_read_fault <= '0';

				-- word address calculation
				wordaddress := to_integer(unsigned(in_imem.read_addr(in_imem.read_addr'high downto 2))); -- always 32bit aligned

				-- read data
				if (wordaddress < size) then
					-- always return full word
					imem_data <= memory(wordaddress)(width - 1 downto 0);
				else
					-- memory access out of bounds
					imem_read_fault <= '1';
					imem_data       <= (others => 'X');
				end if;
			end if;
		end if;
	end process imem_read;

	-- dmem read
	dmem_read : process(clk) is
		-- calculated word address
		variable wordaddress : integer;
		-- calculated byte address inside of word
		variable byteaddress : std_logic_vector(1 downto 0);
		-- read full word
		variable word        : std_logic_vector(width - 1 downto 0);
	begin
		if (rising_edge(clk)) then
			if (rst = '1') then
				-- in reset zero output and no fault
				dmem_data       <= (others => '0');
				dmem_read_fault <= '0';
			else
				-- standard output
				dmem_read_fault <= '0';

				if (in_dmem.read_en = '1') then
					-- if read enabled, otherwise keep up old data

					-- calculate word address and address of byte inside of word
					wordaddress := to_integer(unsigned(in_dmem.read_addr(in_dmem.read_addr'high downto 2)));
					byteaddress := in_dmem.read_addr(1 downto 0);

					if (wordaddress = 0) then
						dmem_data <= (others => '0');
						
					elsif (wordaddress < size) then  -- data can be accessed full range of address
						-- in memory range

						-- read word from memory array
						word := memory(wordaddress);

						-- get correct bits from full word
						case in_dmem.read_size is
							when "00" => -- byte access
								-- clear non-byte bits
								dmem_data(width - 1 downto 8) <= (others => '0');

								-- fill last byte of output word with read data
								case byteaddress is
									when "00" =>
										dmem_data(7 downto 0) <= word(31 downto 24);
									when "01" =>
										dmem_data(7 downto 0) <= word(23 downto 16);
									when "10" =>
										dmem_data(7 downto 0) <= word(15 downto 8);
									when "11" =>
										dmem_data(7 downto 0) <= word(7 downto 0);
									when others =>
										-- will not happen in synthesis, but might in simulation
										dmem_data(7 downto 0) <= (others => 'X');
								end case;

							when "01" => -- halfword access
								-- clear non-halfword bits
								dmem_data(width - 1 downto 16) <= (others => '0');

								-- fill last halfword of output word with read data
								case byteaddress is
									when "00" =>
										dmem_data(15 downto 0) <= word(31 downto 16);
									when "01" =>
										--alignment to lower half word
										dmem_data(15 downto 0) <= word(31 downto 16);
									when "10" =>
										dmem_data(15 downto 0) <= word(15 downto 0);
									when "11" =>
										--alignment to lower half word
										dmem_data(15 downto 0) <= word(15 downto 0);
									when others =>
										-- memory access exceeds word boundaries
										dmem_read_fault <= '1';
										-- synthesis translate_off
										assert false report "memory access exceeds word boundaries (16bit dmem read at " & integer'image(to_integer(unsigned(in_dmem.read_addr))) & ")" severity error;
										-- synthesis translate_on
								end case;

							when "10" => -- word access
								-- fill all bits of output word with read data
								if (byteaddress = "00") then
									dmem_data <= word;
								else
									-- memory access exceeds word boundaries
									dmem_read_fault <= '1';
									-- synthesis translate_off
									assert false report "memory access exceeds word boundaries (32bit dmem read at " & integer'image(to_integer(unsigned(in_dmem.read_addr))) & ")" severity error;
									-- synthesis translate_on
								end if;
							when others =>
								-- memory size not implemented
								dmem_read_fault <= '1';
								-- synthesis translate_off
								assert false report "memory size not implemented" severity error;
								-- synthesis translate_on
						end case;

					else                -- (wordaddress >= size)
						-- memory access out of bounds
						dmem_read_fault <= '1';
						dmem_data       <= (others => 'X');
						-- synthesis translate_off
						assert false report "memory access out of bounds (dmem read at " & integer'image(to_integer(unsigned(in_dmem.read_addr))) & ")" severity error;
						-- synthesis translate_on

					end if;
				end if;
			end if;
		end if;
	end process dmem_read;

	-- dmem write
	dmem_write : process(clk) is
		-- calculated word address
		variable wordaddress : integer;
		-- calculated byte address inside of word
		variable byteaddress : std_logic_vector(1 downto 0);
		-- read full word
		variable word        : std_logic_vector(width - 1 downto 0);
	begin
		if rising_edge(clk) then
			if rst = '1' then
				dmem_write_fault <= '0';
				dmem_write_fault <= '0';
				write_state		 <= read_old;
				old_word		 <= (others => '0');
				mem_ready		 <= '1';
			else
				case write_state is
					when read_old =>
						wordaddress		 := to_integer(unsigned(in_dmem.write_addr(in_dmem.write_addr'high downto 2)));
						if (wordaddress < size) then -- in memory range and no special word					
							in_dmem_reg <= in_dmem;
							mem_ready <= '1';
							if (in_dmem.write_en = '1') then
								write_state <= write_new;
								mem_ready <= '0';
								-- read old word
								old_word 	<= memory(wordaddress)(31 downto 0);
							end if;
						else
							dmem_write_fault <= '1';
							-- synthesis translate_off
							assert false report "memory access out of bounds (dmem write at " & integer'image(to_integer(unsigned(in_dmem.write_addr))) & ")" severity error;
					-- synthesis translate_on
						end if;
					when write_new =>
						wordaddress	:= to_integer(unsigned(in_dmem_reg.write_addr(in_dmem.write_addr'high downto 2)));
						byteaddress	:= in_dmem_reg.write_addr(1 downto 0);
						word 		:= old_word;
						write_state <= read_old;
						mem_ready	<= '1';
						case in_dmem_reg.write_size is
							when "00" =>    -- byte access 
								case byteaddress is
									when "00" =>
										word(31 downto 24) := in_dmem_reg.write_data(7 downto 0);
									when "01" =>
										word(23 downto 16) := in_dmem_reg.write_data(7 downto 0);
									when "10" =>
										word(15 downto 8) := in_dmem_reg.write_data(7 downto 0);
									when "11" =>
										word(7 downto 0) := in_dmem_reg.write_data(7 downto 0);
									when others =>
										-- will not happen in synthesis, but might in simulation
										word(7 downto 0) := (others => 'X');
								end case;
							when "01" =>    -- halfword access
								case byteaddress is
									when "00" =>
										word(31 downto 16) := in_dmem_reg.write_data(15 downto 0);
									when "01" =>
										word(23 downto 8) := in_dmem_reg.write_data(15 downto 0);
									when "10" =>
										word(15 downto 0) := in_dmem_reg.write_data(15 downto 0);
									when others =>
										-- memory access exceeds word boundaries
										dmem_write_fault <= '1';
										-- synthesis translate_off
										assert false report "memory access exceeds word boundaries (16bit dmem write at " & integer'image(to_integer(unsigned(in_dmem.write_addr))) & ")" severity error;
										-- synthesis translate_on
								end case;
							when "10" =>
								if (byteaddress = "00") then
									word := in_dmem_reg.write_data;
								else
									-- memory access exceeds word boundaries
									dmem_write_fault <= '1';
									-- synthesis translate_off
									assert false report "memory access exceeds word boundaries (32bit dmem write at " & integer'image(to_integer(unsigned(in_dmem.write_addr))) & ")" severity error;
									-- synthesis translate_on
								end if;

							when others =>
								-- memory size not implemented
								dmem_write_fault <= '1';
								-- synthesis translate_off
								assert false report "memory size not implemented" severity error;
								-- synthesis translate_on
						end case;
						memory(wordaddress) <= word;
				end case;
				
			end if;
		end if;
	end process dmem_write;

	-- in synthesis, data is always valid in next clock cycle
	synthesis_only : if (in_synthesis) generate
		out_imem.read_data <= imem_data;
-- 		out_imem.ready     <= '1';
		out_imem.ready		<= mem_ready;
		out_dmem.read_data	<= dmem_data;
-- 		out_dmem.ready     <= '1';
		out_dmem.ready		<= mem_ready;
	end generate synthesis_only;

	-- add latency in simulation only

	-- synthesis translate_off
	simulation_only : if (in_simulation) generate
		-- instruction memory latency
		
		out_imem.read_data <= imem_data;
		out_imem.ready		<= mem_ready;
		out_dmem.read_data	<= dmem_data;
		out_dmem.ready		<= mem_ready;
		
-- 		imem_delay : process is
-- 		begin
-- 			wait until imem_data'event;
-- 
-- 			-- wait artificial delay
-- 			if (imem_latency > 0 ns) then
-- 				-- show not ready-yet data as XX
-- 				out_imem.ready     <= '0';
-- 				out_imem.read_data <= (others => 'X');
-- 				wait for imem_latency;
-- 			end if;
-- 
-- 			-- output data
-- 			out_imem.read_data <= imem_data;
-- 
-- 			-- now we're ready
-- -- 			out_imem.ready <= '1';
-- 			out_dmem.ready		<= mem_ready;
-- 		end process imem_delay;
-- 
-- 		-- data memory latency
-- 		dmem_delay : process  is
-- 		begin
-- 			wait until dmem_data'event;
-- 
-- 			-- wait artificial delay
-- 			if (dmem_latency > 0 ns) then
-- 				-- show not ready-yet data as XX
-- 				out_dmem.ready     <= '0';
-- 				out_dmem.read_data <= (others => 'X');
-- 				wait for dmem_latency;
-- 			end if;
-- 
-- 			-- output data
-- 			out_dmem.read_data <= dmem_data;
-- 
-- 			-- now we're ready
-- -- 			out_dmem.ready <= '1';
-- 			out_dmem.ready		<= mem_ready;
-- 		end process dmem_delay;

	end generate simulation_only;
-- synthesis translate_on

end architecture RTL;
