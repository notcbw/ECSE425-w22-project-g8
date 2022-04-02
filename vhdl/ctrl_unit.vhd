-- control unit
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mips_common.all;

entity ctrl_unit is
	port(	clk : in std_logic;
			op: in std_logic_vector(5 downto 0);			-- 6-bit opcode
			funct: in std_logic_vector(5 downto 0);			-- 6-bit funct
			reg_eq: in std_logic;							-- set if rd1=rd2, conencted to eq output of fwd_decode
			alu_src: out std_logic;							-- the flag is set if the operation uses an immediate value as an operand
			reg_write: out std_logic;						-- set if register writeback is needed
			mem_to_reg: out std_logic;						-- set if loading
			mem_write: out std_logic;						-- set if writing result to memory
			reg_dst: out std_logic;							-- 0 if Rt, 1 if Rd
			branch: out std_logic;						
			jump: out std_logic;							-- if set, PC is updated with imm sll 2
			link: out std_logic;
			sign_ext: out std_logic;						-- if set, sign extend imm, else zero extend imm
			alu_mode: out alu_enum							-- enum output to set the mode of the ALU
			);
end ctrl_unit;

architecture rtl of ctrl_unit is
	signal beq: std_logic := '0';
	signal bne: std_logic := '0'; 
begin
	-- control logic, asynchoronus
	-- alu control signal
	alu_mode <=	add when (op="000000") and (funct="100000") else	-- add
				add when (op="001000") else	-- addi
				add when (op="100011") else	-- lw
				add when (op="101011") else	-- sw
				sub when (op="000000") and (funct="100010") else	-- sub
				multiply when (op="000000") and (funct="011000") else	-- mult
				divide when (op="000000") and (funct="011010") else		-- div
				slt when (op="001010") else	-- slti
				slt when (op="000000") and (funct="101010") else	-- slt
				alu_and when (op="001100") else	-- andi
				alu_and when (op="000000") and (funct="100100") else	-- and
				alu_or when (op="001101") else	-- ori
				alu_or when (op="000000") and (funct="100101") else	-- or
				alu_nor when (op="000000") and (funct="100111") else	-- nor
				alu_xor when (op="001110") else	-- xori
				alu_xor when (op="000000") and (funct="100110") else	-- xor
				mfhi when (op="000000") and (funct="010000") else	-- mfhi
				mflo when (op="000000") and (funct="010010") else	-- mflo
				alu_sll when (op="000000") and (funct="000000") else	-- sll
				alu_srl when (op="000000") and (funct="000010") else	-- srl
				alu_sra when (op="000000") and (funct="000011") else	-- sra
				lui when (op="001111") else	-- lui
				nop;
				
	-- jump --
	with op select
	jump <=	'1' when "000010",	-- j
			'1' when "000011",	-- jal
			'0' when others;
			
	-- branch
	branch <= (beq and reg_eq) xor (bne and (not reg_eq));
	with op select beq <= '1' when "000100", '0' when others;
	with op select bne <= '1' when "000101", '0' when others;
	
	-- register destination
	with op select
	reg_dst <=	'1' when "000000",	-- assume Rd for all instructions when opcode=0
				'0' when others;
				
	-- alu_src, set if using immediate; applies to all I type instructions
	with op select
	alu_src <=	'0' when "000000",	-- no opcode=0 instructions use imm
				'0' when "000010",	-- j
				'0' when "000011",	-- jal
				'1' when others;
				
	-- reg_write, instructions that need writeback
	with op select
	reg_write <=	'1' when "000000",
					'1' when "001000",	-- addi
					'1' when "001010",	-- slti
					'1' when "001100",	-- andi
					'1' when "001101",	-- ori
					'1' when "001110",	-- xori
					'1' when "001111",	-- lui
					'1' when "100011",	-- lw
					'0' when others;
					
	-- mem_to_reg, for all load instructions
	with op select
	mem_to_reg <=	'1' when "100011",	-- only lw implemented
					'0' when others;
					
	-- mem_write, for all store instructions
	with op select
	mem_write <=	'1' when "101011",	-- only sw implemented
					'0' when others;
					
	-- link, for link operations
	with op select
	link <=	'1' when "000011",	-- jal
			'0' when others;
			
	-- sign_ext, selecting between sign extending and zero extending
	with op select
	sign_ext <=	'0' when "001100",	-- andi
				'0' when "001101",	-- ori
				'0' when "001110",	-- xori
				'0' when "001111",	-- lui
				'1' when others;
			
end rtl;
		