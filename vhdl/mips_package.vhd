-- custom package used to pass enums between stages
library ieee;
use ieee.std_logic_1164.all;

package mips_common is
	-- enum used to pass the mode of the ALU from decode stage to execution stage
	type alu_enum is (add, multiply, divide, slt, alu_and, alu_or, alu_nor, alu_xor, mfhi, mflo, alu_sll, alu_srl, alu_sra);
	
end mips_common;