-- Code your testbench here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mips_common.all;
 entity tb is
 end tb;
 
 architecture test of tb is
 component ALU is 
 port(
    	var1: in std_logic_vector(31 downto 0);
    	var2: in std_logic_vector(31 downto 0);
    	alu_mode: in alu_enum;
    	alu_result: out std_logic_vector(31 downto 0) 	
 );
 end component;
 
signal var1: std_logic_vector(31 downto 0);
signal var2: std_logic_vector(31 downto 0);
signal alu_mode : alu_enum;
signal alu_result: std_logic_vector(31 downto 0);

begin

dut: ALU port map( 
		var1 => var1,
        var2 => var2,
        alu_mode => alu_mode,
        alu_result => alu_result
		);
        
test_process: process
begin

-- Test adding opeartions

var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= add;
wait for 2 ns;
assert alu_result = x"00000011" report "ALU add test failed, not good end value" severity error;
wait for 10 ns;
-- Test subbing operations
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= sub;
wait for 2 ns;
assert alu_result = x"00000001" report "ALU sub test failed, not good end value" severity error;
wait for 10 ns;
-- Test multiplying operations
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= multiply;
wait for 2 ns;
assert alu_result = x"00000000" report "ALU multiply test failed, not good end value" severity error;
wait for 10 ns;
-- Test dividing operations
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= divide;
wait for 2 ns;
assert alu_result = x"00000000" report "ALU divide test failed, not good end value" severity error;
wait for 10 ns;
-- Test slt
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= slt;
wait for 2 ns;
assert alu_result = x"00000000" report "ALU set less than test failed, not good end value" severity error;
wait for 10 ns;

-- Test AND
var1 <= x"00000008";
var2 <= x"00000009";
alu_mode <= alu_and;
wait for 2 ns;
assert alu_result = (var1 and var2) report "ALU AND test failed, not good end value" severity error;
wait for 10 ns;
-- Test Or
var1 <= x"00000008";
var2 <= x"00000009";
alu_mode <= alu_or;
wait for 2 ns;
assert alu_result = (var1 or var2) report "ALU OR test failed, not good end value" severity error;
wait for 10 ns;
-- Test nor
var1 <= x"00000008";
var2 <= x"00000009";
alu_mode <= alu_nor;
wait for 2 ns;
assert alu_result = (var1 nor var2) report "ALU NOR test failed, not good end value" severity error;
wait for 10 ns;
-- Test XOR
var1 <= x"00000008";
var2 <= x"00000009";
alu_mode <= alu_xor;
wait for 2 ns;
assert alu_result = (var1 xor var2) report "ALU XOR test failed, not good end value" severity error;
wait for 10 ns;
-- Test MFHI
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= multiply;
wait for 10 ns;
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= mfhi;
wait for 2 ns;
assert alu_result = x"00000000" report "ALU move from hi test failed, not good end value" severity error;
wait for 10 ns;
-- Test MFLO
var1 <= x"00000009";
var2 <= x"00000008";
alu_mode <= mflo;
wait for 2 ns;
assert alu_result = x"00000048" report "ALU move from lo test failed, not good end value" severity error;
wait for 10 ns; 
-- Test SLL
var1 <= x"00000001";
var2 <= x"00000002";
alu_mode <= alu_sll;
wait for 2 ns;
assert alu_result = x"00000004" report "ALU shift left test failed, not good end value" severity error;
wait for 10 ns;
-- Test SRL
var1 <= x"00000004";
var2 <= x"00000002";
alu_mode <= alu_srl;
wait for 2 ns;
assert alu_result = x"00000001" report "ALU shift right test failed, not good end value" severity error;
wait for 10 ns;
-- Test SRA
var1<= b"1000_0000_0000_0000_0000_0000_0001_0011";
var2 <= x"00000001";
alu_mode <= alu_sra;
wait for 2 ns;
assert alu_result = b"1100_0000_0000_0000_0000_0000_0000_1001" report "ALU shift right arithmetic failed, not good end value" severity error;
wait for 10 ns;
-- Test LUI
var1<= x"00000000";
var2 <= x"00000001";
alu_mode <= lui;
wait for 2 ns;
assert alu_result = x"00010000" report "ALU lui failed, not good end value" severity error;
wait for 10 ns;
-- Test void op
var1 <= x"01010101";
var2 <= x"01100110";
alu_mode <= nop;
wait for 2 ns;
assert alu_result = x"00000000" report "ALU nope operation failed, not good end value";
wait for 10 ns;
var1 <= x"00000004";
var2 <= x"00000002";
wait;
end process;
end architecture;
