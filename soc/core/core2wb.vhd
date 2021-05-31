-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;
use work.lt16x32_global.all;
use work.wishbone.all;
use work.config.all;

entity core2wb is
	port(
		clk       : in  std_logic;
		rst       : in  std_logic;

		in_dmem   : out  dmem_core;
		out_dmem  : in core_dmem;

		-- wb master port
		wmsti	:	in	wb_mst_in_type;
		wmsto	:	out	wb_mst_out_type
	);
end core2wb;

architecture Behavioral of core2wb is
	signal msto	:	wb_mst_out_type := wbm_out_none;

	type STATE_TYPE IS (ONEACC, SIMACCWR, SIMACCRD);
	signal state, nstate: STATE_TYPE;


begin

	reg: process(clk)
	begin
		if rst = '1' then
			state <= ONEACC;
			in_dmem.read_data	<= (others => '0');
		elsif rising_edge(clk) then
			state <= nstate;
			if wmsti.ack = '1' then
				in_dmem.read_data 	<= dec_wb_dat(msto.sel, wmsti.dat);
			end if;
		end if;
	end process;

	nscl: process(state, out_dmem, wmsti.ack)
	begin
		case state is
			when ONEACC =>
				if out_dmem.read_en = '1' and out_dmem.write_en = '1' then
					nstate <= SIMACCWR;
				else
					nstate 	<= state;
				end if;
			when SIMACCWR =>
				if wmsti.ack = '1' then
					nstate <= SIMACCRD;
				else
					nstate <= state; -- wait til get ack from wr request
				end if;
			when SIMACCRD =>
				if wmsti.ack = '1' then -- read_ack
					nstate <= ONEACC;
				else
					nstate <= state; -- feed the old read value from previous sim request
				end if;
		end case;
	end process;

	ocl: process(state, out_dmem, wmsti.ack)
	begin
		msto.dat	<= (others => '0');
		case state is
		when ONEACC =>
			if(out_dmem.write_en = '1') then
				msto.we		<= '1';
				msto.stb 	<= '1';
				msto.cyc 	<= '1';
				msto.adr	<= out_dmem.write_addr(memory_width - 1 downto WB_ADR_BOUND);
				msto.sel	<= gen_select(out_dmem.write_addr(1 downto 0), out_dmem.write_size);
				msto.dat	<= enc_wb_dat(out_dmem.write_addr(1 downto 0), out_dmem.write_size, out_dmem.write_data);
			elsif(out_dmem.read_en = '1' and out_dmem.write_en = '0') then
				msto.we		<= '0';
				msto.stb 	<= '1';
				msto.cyc 	<= '1';
				msto.adr	<= out_dmem.read_addr(memory_width - 1 downto WB_ADR_BOUND);
				msto.sel	<= gen_select(out_dmem.read_addr(1 downto 0), out_dmem.read_size);
			else
				msto <= wbm_out_none;
			end if;
		when SIMACCRD =>  -- using previous address from sim request, no need since core will keep holding the value
				msto.we		<= '0';
				msto.stb 	<= '1';
				msto.cyc 	<= '1';
				msto.adr	<= out_dmem.read_addr(memory_width - 1 downto WB_ADR_BOUND);
				msto.sel	<= gen_select(out_dmem.read_addr(1 downto 0), out_dmem.read_size);
		when SIMACCWR =>
				msto.we		<= '1';
				msto.stb 	<= '1';
				msto.cyc 	<= '1';
				msto.adr	<= out_dmem.write_addr(memory_width - 1 downto WB_ADR_BOUND);
				msto.sel	<= gen_select(out_dmem.write_addr(1 downto 0), out_dmem.write_size);
				msto.dat	<= enc_wb_dat(out_dmem.write_addr(1 downto 0), out_dmem.write_size, out_dmem.write_data);
		end case;
	end process;
	wmsto <= msto;

	-----------------------------
	-- wbmi 2 core
	-----------------------------
	wb2core_reg: process(wmsti, state, out_dmem)
	begin
		in_dmem.ready	<= '0';
			if state = SIMACCWR then
				in_dmem.ready <= '0';
			elsif state = SIMACCRD then
				in_dmem.ready <= wmsti.ack;
			elsif state = ONEACC then
				if (out_dmem.write_en xor out_dmem.read_en)='1' then
					in_dmem.ready <= wmsti.ack;
				--elsif out_dmem.write_en='0' and out_dmem.read_en='0' then
				--	indmem.ready <= '1';
				--elsif out_dmem.write_en='1' and out_dmem.read_en='1' then
				--	indmem.ready <= '0';
				else --instead of the fancy stuff above:
					in_dmem.ready <= out_dmem.write_en nand out_dmem.read_en;
				end if;
			end if;
	end process;

end Behavioral;
