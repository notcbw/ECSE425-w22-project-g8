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
 end entity;
 
architecture rtl of execute is
component ALU is
	port(
    var1: in std_logic_vector(31 downto 0);
    var2: in std_logic_vector(31 downto 0);
    alu_mode: in alu_enum;
    alu_result: out std_logic_vector(31 downto 0)
    );
end component;

signal v1: std_logic_vector(31 downto 0);
signal v2: std_logic_vector(31 downto 0);
signal mode: alu_enum;
signal result: std_logic_vector(31 downto 0);
signal pc_plus_8: std_logic_vector(31 downto 0);
signal link_buf: std_logic := '0';
constant zero : std_logic_vector(31 downto 0) := (others =>'0');

begin
	a: ALU port map(v1,v2,mode,result);
	
	-- if jump with link, alu result is pc+8 value that will be calculated below
	alu_result_out <= pc_plus_8 when link_buf='1' else result;
 
	process(clk)
	begin
		if clk'event and clk='1' then
			stall_out <= stall;
			reg_write_out <= reg_write;
			Mem2Reg_out <= Mem2Reg;
			MemWrite_out <= MemWrite;
			WB_register_out <= WB_register;
			write_data_out <= r2;
			mode <= alu_mode;
			v1 <= r1;
			link_buf <= link;
		
			-- switch between immediate and register file output 2
			if immUse='1' then
				v2 <= immEx;
			else
				v2 <= r2;
			end if;
		
			-- pc related operations
			if branch='1' then
				-- branch, new_pc = pc+imm<2
				pc_write <= '1';
				PC_out <= std_logic_vector(to_unsigned(to_integer(unsigned(PC)) + to_integer(shift_left(signed(immEx), 2)), 32));
			elsif jump='1' then
				-- jump, new_pc = imm<2
				pc_write <= '1';
				PC_out <= std_logic_vector(shift_left(unsigned(immEx), 2));
			else
			pc_write <= '0';
			end if;
			
			-- link operation
			if link='1' then
				-- link, output pc+8 to alu out port
				pc_plus_8 <= std_logic_vector(unsigned(PC) + to_unsigned(8, 32));
			end if;
			
			
		
		end if;
	end process;

end rtl;
