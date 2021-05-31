-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the decoder_32bit decodes all 32bit instructions and is fully combinatoric
entity decoder_32bit is
	port(
		-- input signals from decoder finite state machine
		input  : in  fsm_dec32;
		-- output signals to control path (or decoder mux)
		output : out dec_cp
	);
end entity decoder_32bit;

architecture RTL of decoder_32bit is
begin

	-- currently, there are no 32bit instructions, so output is
	-- always nop and hardfault
	output.s1 <= get_default_dec_cp_s1;
	output.s2 <= get_default_dec_cp_s2;
	output.s3 <= get_default_dec_cp_s3;
	output.hardfault <= '1';

end architecture RTL;
