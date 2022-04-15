-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mips_common.all;

entity ALU is
	port(
    	var1: in std_logic_vector(31 downto 0);
    	var2: in std_logic_vector(31 downto 0);
    	alu_mode: in alu_enum;
    	alu_result: out std_logic_vector(31 downto 0)
    );
end ALU;

architecture rtl of ALU is
	signal hi,lo:std_logic_vector(31 downto 0);
	constant zero : std_logic_vector(31 downto 0) := (others =>'0');
begin
	
	process(var1, var2, alu_mode)
		variable full: std_logic_vector(63 downto 0);
	begin
		alu_result <= zero;
		case alu_mode is
			when add =>
				alu_result <= std_logic_vector(signed(var1) + signed(var2));

			when sub =>
				alu_result <= std_logic_vector(signed(var1) - signed(var2));

			when multiply =>
				full := std_logic_vector(signed(var1) * signed(var2)); -- use of := for immediate assignemnt
				
			when divide =>
				--full := (std_logic_vector(signed(var1) / signed(var2)) & std_logic_vector(signed(var1) mod signed(var2)));
				full := (std_logic_vector(signed(var1) mod signed(var2)) & std_logic_vector(signed(var1) / signed(var2)));

			when slt =>
				if(signed(var1) < signed(var2)) then
					alu_result <= std_logic_vector(signed(zero)+1);
				else
					alu_result <= zero;
				end if;

			when alu_and =>
				alu_result <= (var1 and var2);

			when alu_or =>
				alu_result <= (var1 or var2);

			when alu_nor =>
				alu_result <= (var1 nor var2);

			when alu_xor =>
				alu_result <= (var1 xor var2);

			when mfhi =>
				alu_result <= hi;

			when mflo =>
				alu_result <= lo;

			when alu_sll =>
				alu_result <= std_logic_vector(shift_left(unsigned(var1), to_integer(unsigned(var2))));

			when alu_srl =>
				alu_result <= std_logic_vector(shift_right(unsigned(var1), to_integer(unsigned(var2))));

			when alu_sra =>
				alu_result <= std_logic_vector(shift_right(signed(var1), to_integer(unsigned(var2))));

			when lui =>
				alu_result <= std_logic_vector(SHIFT_LEFT(signed(var2),16));

			when nop =>
				alu_result <= zero;

		end case;
		hi <= full(63 downto 32);
		lo <= full(31 downto 0);
	end process;
end architecture;
