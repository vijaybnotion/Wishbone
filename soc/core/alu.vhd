-- See the file "LICENSE" for the full license governing this code. --

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lt16x32_internal.all;

-- the ALU offers various two-input arithmetic and logic operations and is fully combinatoric
entity alu is
	port(
		-- Data Input
		in_a     : in  signed(reg_width - 1 downto 0);
		in_b     : in  signed(reg_width - 1 downto 0);

		-- Truth Flag
		t_out    : out std_logic;

		-- Overflow Flag
		ovf_out  : out std_logic;

		-- Mode of Operation
		mode     : in  alu_mode_type;

		-- Data Output
		data_out : out signed(reg_width - 1 downto 0)
	);
end entity alu;

architecture RTL of alu is
begin

	-- calculate the result
	calc_out : process(in_a, in_b, mode) is
		-- used to store the result temporarily (e.g. if needed for flag calculation)
		variable result : signed(reg_width - 1 downto 0);
	begin
		-- default outputs
		data_out <= (others => '0');
		ovf_out  <= '0';
		t_out    <= '0';

		-- different result for each mode
		case mode is
			-- arithmetic modes

			when alu_add =>             -- addition
				result := in_a + in_b;

				data_out <= result;
				ovf_out  <= (in_a(reg_width - 1) AND in_b(reg_width - 1) AND not result(reg_width - 1)) OR (not in_a(reg_width - 1) AND not in_b(reg_width - 1) AND result(reg_width - 1));

			when alu_sub =>             -- subtraction
				result := in_a - in_b;

				data_out <= result;
				ovf_out  <= (in_a(reg_width - 1) AND not in_b(reg_width - 1) AND not result(reg_width - 1)) OR (not in_a(reg_width - 1) AND in_b(reg_width - 1) AND result(reg_width - 1));

			when alu_and =>             -- bitwise and
				data_out <= in_a and in_b;

			when alu_or =>              -- bitwise or 
				data_out <= in_a or in_b;

			when alu_xor =>             -- bitwise xor
				data_out <= in_a xor in_b;

			when alu_lsh =>             -- logic left shift 
				data_out <= in_a sll (to_integer(unsigned(in_b(3 downto 0))) + 1);

			when alu_rsh =>             -- logic right shift
				data_out <= in_a srl (to_integer(unsigned(in_b(3 downto 0))) + 1);

			-- compare modes
			when alu_cmp_eq =>          -- compare for A = B
				if (in_a = in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_neq =>         -- compare for not equal
				if (in_a /= in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_ge =>          -- compare for greater than or equal
				if (in_a >= in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_gg =>          -- compare for greater than
				if (in_a > in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_le =>          -- compare for less than or equal
				if (in_a <= in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_ll =>          -- compare for less than
				if (in_a < in_b) then
					t_out <= '1';
				else
					t_out <= '0';
				end if;

			when alu_cmp_true =>        -- always set truth-flag
				t_out <= '1';

			when alu_cmp_false =>       -- always reset truth-flag
				t_out <= '0';
		end case;
	end process calc_out;

end architecture RTL;
