-- See the file "LICENSE" for the full license governing this code. --

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.math_real.all;

library work;
use work.wishbone.all;
use work.config.all;

ENTITY wb_intercon IS
	generic(
		slv_mask_vector : std_logic_vector(0 to NWBSLV-1) := b"0000_0000_0000_0000";
		mst_mask_vector : std_logic_vector(0 to NWBMST-1) := b"0000"
	);
	port(
		clk		: in  std_logic;
		rst		: in  std_logic;
		msti	: out wb_mst_in_vector;
		msto	: in  wb_mst_out_vector;
		slvi	: out wb_slv_in_vector;
		slvo	: in  wb_slv_out_vector
	);
END ENTITY wb_intercon;

ARCHITECTURE RTL OF wb_intercon IS
--selected slv
signal tmpslvo	: wb_slv_out_vector; -- := (others=> wbs_out_none);
--granted mst
signal tmpmsto	: wb_mst_out_vector; -- := (others=> wbm_out_none);

signal mgnt_idx		:  integer range 0 to NWBMST-1;
signal mgnt			:  std_logic_vector(0 to NWBMST-1) := (others=>'0');

signal ssel_idx		:  integer range 0 to NWBSLV-1;
signal ssel			:  std_logic_vector(0 to NWBSLV-1) := (others=>'0');


BEGIN
-----------------------------------------------
-- Master Arbiter: To output which master is granted
-----------------------------------------------
	mstarb: for i in 0 to NWBMST-1 generate
		onemst: if (i = 0) generate
			onemst_exist: if(mst_mask_vector(i)='1') generate
				tmpmsto(i)	<= msto(i) when (msto(i).cyc='1') else
							wbm_out_none;
			end generate onemst_exist;

			onemst_dne: if(mst_mask_vector(i)='0') generate
				tmpmsto(i)	<= wbm_out_none;
			end generate onemst_dne;
		end generate onemst;

		mulmst: if (i > 0) generate
			mulmst_exist:  if(mst_mask_vector(i)='1') generate
				tmpmsto(i)	<= msto(i) when (msto(i).cyc='1') else
							tmpmsto(i-1);
			end generate mulmst_exist;

			mulmst_dne:if(mst_mask_vector(i)='0') generate
				tmpmsto(i) <= tmpmsto(i-1);
			end generate mulmst_dne;
		end generate mulmst;

	end generate mstarb;

	--
	selslv: process(tmpmsto(NWBMST-1) ,slvo, mgnt_idx)
	begin
		slvi	<= (others=> wbs_in_none); --init slave_input
		ssel_idx <= 0;
		for i in 0 to NWBSLV-1 loop
			if (slv_mask_vector(i)='1') then
				--slave active and m_req_adr maps to the slave
				if(slvadrmap(slvo(i).wbcfg, tmpmsto(NWBMST-1).adr) and mst_mask_vector(mgnt_idx) = '1') then
					ssel 		<= (others=>'0'); -- clear gnt for previous grant of lower priority master
					ssel_idx 	<= i;
					ssel(i) 	<= '1';

					slvi(i).dat <= tmpmsto(NWBMST-1).dat;
					slvi(i).sel <= tmpmsto(NWBMST-1).sel;
					slvi(i).adr <= tmpmsto(NWBMST-1).adr;
					slvi(i).cyc <= tmpmsto(NWBMST-1).cyc;
					slvi(i).stb <= tmpmsto(NWBMST-1).stb;
					slvi(i).we  <= tmpmsto(NWBMST-1).we;
					slvi(i).cti	<= tmpmsto(NWBMST-1).cti;
					slvi(i).bte	<= tmpmsto(NWBMST-1).bte;
				end if;
			end if;
		end loop;
	end process;

-----------------------------------
--slave decoding:
-----------------------------------
	gen_slvmux: for i in 0 to NWBSLV-1 generate
			-- One slave exists
			oneslv: if (i = 0) generate
				oneslv_exist: if(slv_mask_vector(i)='1') generate
					tmpslvo(i)	<= slvo(i) when slvadrmap(slvo(i).wbcfg, tmpmsto(NWBMST-1).adr) else
								wbs_out_none;
				end generate oneslv_exist;

				oneslv_dne: if(slv_mask_vector(i)='0') generate
					tmpslvo(i)<=wbs_out_none;
				end generate oneslv_dne;
			end generate oneslv;

			-- Multiple slaves exists
			mulslv: if (i > 0) generate
				mulslv_exist: if(slv_mask_vector(i)='1') generate
					tmpslvo(i)	<= slvo(i) when slvadrmap(slvo(i).wbcfg, tmpmsto(NWBMST-1).adr) else
								tmpslvo(i-1);
				end generate mulslv_exist;

				mulslv_dne: if(slv_mask_vector(i)='0') generate
					tmpslvo(i) <= tmpslvo(i-1);
				end generate mulslv_dne;
			end generate mulslv;
	end generate gen_slvmux;


	gntmst: process(msto)
	begin
		mgnt <= (others=>'0');
		mgnt_idx <= 0;
		for i in 0 to NWBMST-1 loop
			if (mst_mask_vector(i)='1') then
				if(msto(i).cyc='1') then -- check if master still get the bus
					mgnt <= (others=>'0'); -- clear gnt for previous grant of lower priority master
					mgnt_idx <= i;
					mgnt(i) 	<= '1';
				end if;
			end if;
		end loop;
	end process;

	process(mgnt_idx,tmpslvo(NWBSLV-1).ack,tmpslvo(NWBSLV-1).dat)
	begin
		msti <= (others=> wbm_in_none); --init master_input
		for i in 0 to NWBMST-1 loop
			if mgnt_idx=i then
				msti(i).ack <= tmpslvo(NWBSLV-1).ack;
			else
				msti(i).ack <= '0';
			end if;
			msti(i).dat <= tmpslvo(NWBSLV-1).dat;
		end loop;
	end process;

END ARCHITECTURE RTL;
