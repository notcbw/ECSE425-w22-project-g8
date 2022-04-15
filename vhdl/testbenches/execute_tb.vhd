-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mips_common.all;

entity tb is
end tb;

architecture exe_tb of tb is

component execute is
port(
		clk : in std_logic; -- clock
	    alu_mode: in alu_enum; --mode of the ALU
	    r1: in std_logic_vector(31 downto 0); --register 1
	    r2: in std_logic_vector(31 downto 0); -- register 2
	    immEx: in std_logic_vector(31 downto 0); -- extended Immediate
	    WB_register: in std_logic_vector(4 downto 0); -- register number of changed one
	    branch: in std_logic;
	    jump: in std_logic;
		link: in std_logic;
		stall: in std_logic;
		reg_write: in std_logic;
	    Mem2Reg: in std_logic; -- read data from main memory
	    MemWrite: in std_logic; -- write data from register to memory
	    immUse: in std_logic; -- use the immediate value
	    PC: in std_logic_vector(31 downto 0); -- PC of instruction
    
		stall_out: out std_logic;
		reg_write_out: out std_logic;
	    Mem2Reg_out: out std_logic; -- outputs read
	    MemWrite_out: out std_logic; -- outputs write
	    WB_register_out: out std_logic_vector(4 downto 0); -- outputs reg number
	    write_data_out: out std_logic_vector(31 downto 0);
	    alu_result_out: out std_logic_vector(31 downto 0);
		pc_write: out std_logic := '0';
	    PC_out : out std_logic_vector(31 downto 0)
	    );
 end component;
 
 signal clk: std_logic;
 signal alu_mode: alu_enum;
signal r1: std_logic_vector(31 downto 0); 
signal r2: std_logic_vector(31 downto 0); 
signal immEx: std_logic_vector(31 downto 0); 
signal WB_register: std_logic_vector(4 downto 0); 
signal branch:  std_logic;
signal jump: std_logic;
signal link: std_logic;
signal stall: std_logic;
signal reg_write: std_logic;
signal Mem2Reg: std_logic; 
signal MemWrite: std_logic; 
signal immUse: std_logic; 
signal PC:  std_logic_vector(31 downto 0); 
signal stall_out: std_logic;
signal reg_write_out: std_logic;
signal Mem2Reg_out: std_logic; 
signal MemWrite_out: std_logic; 
signal WB_register_out: std_logic_vector(4 downto 0); 
signal write_data_out: std_logic_vector(31 downto 0);
signal alu_result_out: std_logic_vector(31 downto 0);
signal pc_write: std_logic := '0';
signal PC_out : std_logic_vector(31 downto 0);

begin
dut : execute port map(
		clk => clk,
        alu_mode => alu_mode,
        r1 => r1,
        r2 => r2,
        immEx=> immEx,
        WB_register => WB_register,
        branch => branch,
        jump => jump,
        link => link,
        stall => stall,
        reg_write => reg_write,
        Mem2Reg => Mem2Reg,
        MemWrite => MemWrite,
        immUse => immUse,
        PC => PC,
        stall_out => stall_out,
        reg_write_out => reg_write_out,
        Mem2Reg_out => Mem2Reg_out,
        MemWrite_out => MemWrite_out,
        WB_register_out => WB_register_out,
        write_data_out => write_data_out,
        alu_result_out => alu_result_out,
        pc_write => pc_write,
        PC_out => PC_out
);
	clk_process: process
	begin
		-- 1 GHz
		clk <= '0';
		wait for 0.5 ns;
		clk <= '1';
		wait for 0.5 ns;
	end process;
    test_process: process
    begin
-- Testing branching

alu_mode <= nop;
r1 <= x"00000020";
r2 <= x"00000010";
immEx <= x"00000030";
WB_register <= b"0_0000";
branch <= '1';
jump <= '0';
link <= '0';
stall <= '0';
reg_write <= '0';
Mem2Reg <= '0';
MemWrite <= '0';
immUse <= '0';
PC <= x"00000010";

wait for 2 ns;
assert PC_out = x"000000d0" report "Branching failed to deliver correct value" severity error;
wait for 10 ns;



-- Testing Jumping
alu_mode <= nop;
r1 <= x"00000020";
r2 <= x"00000010";
immEx <= x"00000030";
WB_register <= b"0_0000";
branch <= '0';
jump <= '1';
link <= '0';
stall <= '0';
reg_write <= '0';
Mem2Reg <= '0';
MemWrite <= '0';
immUse <= '0';
PC <= x"00000010";
wait for 2 ns;
assert PC_out = x"000000c0" report "Jumping failed to deliver proper updated PC" severity error;
wait for 10 ns;

-- Testing Jump and Link
alu_mode <= nop;
r1 <= x"00000020";
r2 <= x"00000010";
immEx <= x"00000030";
WB_register <= b"0_0000";
branch <= '0';
jump <= '1';
link <= '1';
stall <= '0';
reg_write <= '0';
Mem2Reg <= '0';
MemWrite <= '0';
immUse <= '0';
PC <= x"00000010";
wait for 2 ns;
assert (PC_out =x"000000c0" and alu_result_out = x"00000018") report "Jump and Link unsuccesful" severity error; 
wait for 10 ns;

-- Testing Use of Immediate in ALU vs register
alu_mode <= add;
r1 <= x"00000020";
r2 <= x"00000010";
immEx <= x"00000030";
WB_register <= b"0_0000";
branch <= '0';
jump <= '0';
link <= '0';
stall <= '0';
reg_write <= '0';
Mem2Reg <= '0';
MemWrite <= '0';
immUse <= '1';
PC <= x"00000010";
wait for 2 ns;
assert alu_result_out = x"00000050" report "Didnt use proper value for additon" severity error;
wait for 10 ns;

--Sub Test, LUI result
alu_mode <= lui;
r1 <= x"00000020";
r2 <= x"00000010";
immEx <= x"00000010";
WB_register <= b"0_0000";
branch <= '0';
jump <= '0';
link <= '0';
stall <= '0';
reg_write <= '0';
Mem2Reg <= '0';
MemWrite <= '0';
immUse <= '1';
PC <= x"00000010";
wait for 2 ns;
assert alu_result_out = x"00100000" report "LUI didnt perform correctly" severity error;
wait for 10 ns;

r1 <= x"00000020"; -- For EPWave
r2 <= x"00000010"; -- For EPWave
wait for 10 ns;
wait;
end process;
end architecture;
