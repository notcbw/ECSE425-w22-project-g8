-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.mips_common.all;

entity execute is
port(
	clk : in std_logic; -- clock
    alu_mode: in alu_enum; --mode of the ALU
    r1: in std_logic_vector(31 downto 0); --register 1
    r2: in std_logic_vector(31 downto 0); -- register 2
    immEx: in std_logic_vector(31 downto 0); -- extended Immediate
    WB_register: in std_logic_vector(4 downto 0); -- register number of changed one
    branch: in std_logic_vector(1 downto 0); --tells what kind of branch to do
    jump: in std_logic_vector(1 downto 0); -- what kind of jump required
    Mem2Reg: in std_logic; -- read data from main memory
    MemWrite: in std_logic; -- write data from register to memory
    immUse: in std_logic -- use the immediate value
    PC:in std_logic_vector(31 downto 0); -- PC of instruction
    
    Mem2Reg_out: out std_logic; -- outputs read
    MemWrite_out: out std_logic; -- outputs write
    WB_register_out: out std_logic_vector(4 downto 0); -- outputs reg number
    Var_out: out std_logic_vector(31 downto 0) -- outputs an unused but useful variable to check?
    alu_result_out: out std_logic_vector(31 downto 0);
    PC_out : out std_logic_vector(31 downto 0);
    old_PC: out std_logic_vector(31 downto 0)
    );
    constant zero : std_logic_vector(31 downto 0) := (others =>'0');
 end entity;
 
architecture arch of execute is
component ALU is
	port(
    clk:in std_logic;
    var1: in std_logic_vector(31 downto 0);
    var2: in std_logic_vector(31 downto 0);
    alu_mode: in alu_enum;
    
    alu_result: out std_logic_vector(31 downto 0);

    );
end component;

signal clock : std_logic;
signal v1: std_logic_vector(31 downto 0);
signal v2: std_logic_vector(31 downto 0);
signal mode: alu_enum;
signal result: std_logic_vector(31 downto 0);


 begin
 ALU: ALU port map (clock,v1,v2,mode,result);
 
 process
 begin
Mem2Reg_out <= Mem2Reg;
MemWrite_out <= MemWrite;
WBregister_out <= WB_register;
old_PC <= PC;
PC_out <= zero;

if(branch /= '00') then
if(branch = '01) then -- BEQ
if(r1 = r2) then
v1 <= PC;
v2 <= immEx;
mode <= add;
PC_out <= result;
alu_result_out <= zero;
end if;

if(branch = '10') then -- BNE
if(r1 /= r2) then 
v1 <= PC;
v2 <= immEx;
mode <= add;
PC_out <= result;
alu_result_out <= zero;
end if;
end if;

if(jump /= '00') then
if(jump = '01' or jump ='11') then -- Jump/JAL
PC_out <= immEx;
alu_result_out <= zero;
end if;

if(jump ='10') then -- Jump Register
PC_out <= r1;
alu_result_out <= zero;
end if;
end if;

if(immUse ='1') then
v1 <= r1;
v2 <= immEx;
mode <= alu_mode;
alu_result_out <= result;

else

v1 <= r1;
v2 <= r2
mode <= alu_mode;
alu_result_out <= result;
end if;
end process;

end arch;









































    