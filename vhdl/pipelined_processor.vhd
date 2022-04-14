
-- put all components together
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library work;
use work.mips_common.all;
use work.instruction_tools.all;

entity processor is 
	port(
    clock: in std_logic;
    initialise:in std_logic;
    reset: in std_logic;
    mem_in: in std_logic_vector(31 downto 0);
    
    
    );
    
    
    
architecture CPU of processor is
component data_memory is
		GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- data from memory goes to writeback and fetch s_data_inst
		waitrequest: OUT STD_LOGIC -- goes to s_waitrequest_inst
	);
END component;


component register_file is
	port(	clk: in std_logic;
			a1: in std_logic_vector(4 downto 0);
			a2: in std_logic_vector(4 downto 0);
			aw: in std_logic_vector(4 downto 0);	-- addr to write data into register
			dw: in std_logic_vector(31 downto 0);	-- write data
			we: in std_logic;						-- write enable
			rd1: out std_logic_vector(31 downto 0);
			rd2: out std_logic_vector(31 downto 0)
			);
end component;

component fetch is
	port(
		clk: in std_logic;
        reset: in std_logic := '0';
		stall: in std_logic := '0';
		branch_taken: in std_logic := '0'; -- Execute inbound
        branch_addr: in std_logic_vector(31 DOWNTO 0); --Execute inbound / new PC
		pc: out std_logic_vector(31 DOWNTO 0); -- PC, goes to everything until execute
		s_addr_inst: out std_logic_vector(31 downto 0); -- send address to mem (is PC)
		s_read_inst: out std_logic; -- send read signal to mem
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache/mem
		s_readdata_inst: in std_logic_vector(31 downto 0); -- get instruction from cache/mem

		
	);
    end component;
    
component decode is
	port(	clk: in std_logic;
			stall_d: in std_logic;						-- input to stall decode, active high
			inst: in std_logic_vector(31 downto 0); -- Instruction from fetch
			reg_dst: in std_logic;		-- from the control unit, 1 if writeback to Rd, 0 if Rt
			jump: in std_logic;			-- from the control unit, 1 if it's a jump instruction	
			sign_ext: in std_logic;		-- from the control unit. 1 if sign extend, 0 if zero extend
			reg_write_e: in std_logic;	
			write_reg_e: in std_logic_vector(4 downto 0);
			reg_write_m: in std_logic;
			write_reg_m: in std_logic_vector(4 downto 0);
			reg_write_w: in std_logic;
			write_reg_w: in std_logic_vector(4 downto 0);
			pc_in: in std_logic_vector(31 downto 0);
			pc_out: out std_logic_vector(31 downto 0);
			op: out std_logic_vector(5 downto 0);		-- opcode to control unit
			funct: out std_logic_vector(5 downto 0);	-- funct to control unit
			a1_out: out std_logic_vector(4 downto 0);	-- a1 to register file
			a2_out: out std_logic_vector(4 downto 0);	-- a2 to register file
			aw_out: out std_logic_vector(4 downto 0);	-- pass writeback address from write_reg_w to the register file
			we_out: out std_logic;						-- pass reg_write_w signal to write enable of the register file
			write_reg_out: out std_logic_vector(4 downto 0);	-- writeback register address
			stall_f: out std_logic;							-- signal to stall fetch
			imm_out: out std_logic_vector(31 downto 0); -- Immediate after sign extended
			fwd1_out: out std_logic;		-- switch to the muxes in the forwarding unit of decode stage
			fwd2_out: out std_logic
			);
end component;

    
component ctrl_unit is
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
				sign_ext: out std_logic;
				alu_mode: out alu_enum							-- enum output to set the mode of the ALU
				);
	end component;
	
	component fwd_decode is
		port(	rd1_in: in std_logic_vector(31 downto 0); -- incoming register value from reg file
				rd2_in: in std_logic_vector(31 downto 0); -- incoming value from reg file
				fwd_in: in std_logic_vector(31 downto 0); -- incoming forwarded value (if needed)
				fwd1: in std_logic; -- selectors for if forwarded is needed
				fwd2: in std_logic;
				eq: out std_logic; -- if they're equal (for branching)
				rd1_out: out std_logic_vector(31 downto 0); --outgoing values for execute
				rd2_out: out std_logic_vector(31 downto 0)
				);
	end component;
component execute is
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
    PC_out : out std_logic_vector(31 downto 0); -- pc if updated by Jump/ branch, goes to fetch
    old_PC: out std_logic_vector(31 downto 0)
    );
    constant zero : std_logic_vector(31 downto 0) := (others =>'0');
 end component;
 
 component mem is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --

        ALU_result_in : in std_logic_vector(63 downto 0);
        ALU_result_out : out std_logic_vector(63 downto 0);
        instruction_in : in INSTRUCTION; -- Use control signals to modify
        instruction_out : out INSTRUCTION;
        val_b : in std_logic_vector(31 downto 0);
        mem_data : out std_logic_vector(31 downto 0);



	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0); -- goes to fetch
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; -- goes to fetch
    
	m_addr : out integer range 0 to ram_size-1; -- go to memory
	m_read : out std_logic;
	m_readdata : in std_logic_vector (31 downto 0); -- comes from memory
	m_write : out std_logic; -- goes to memory
	m_writedata : out std_logic_vector (31 downto 0); -- goes to memory
	m_waitrequest : in std_logic -- go to fetch
);
end component;

component write_back is
	port(	clk	: in std_logic;
			mem_to_reg	: in std_logic; -- if need to write to register file
			read_data	: in std_logic_vector(31 downto 0); -- read data from memory
			alu_result	: in std_logic_vector(31 downto 0); -- result from alu if this needs to be stored
			write_data	: out std_logic_vector(31 downto 0)); -- sends data to register file
end component;
		
    -- SIGNALS NEEDED    
        clock_data: IN STD_LOGIC;
		writedata_data: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address_data: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite_data: IN STD_LOGIC;
		memread_data: IN STD_LOGIC;
		readdata_data: OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- data from memory goes to writeback and fetch s_data_inst
		waitrequest_data: OUT STD_LOGIC -- goes to s_waitrequest_inst
		
        clock_inst: IN STD_LOGIC;
		writedata_inst: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address_inst: IN INTEGER RANGE 0 TO ram_size-1;
		memwrite_inst: IN STD_LOGIC;
		memread_inst: IN STD_LOGIC;
		readdata_inst: OUT STD_LOGIC_VECTOR (31 DOWNTO 0); -- data from memory goes to writeback and fetch s_data_inst
		waitrequest_inst: OUT STD_LOGIC -- goes to s_waitrequest_inst
    
 			clk_reg
			a1_reg: in std_logic_vector(4 downto 0);
			a2_reg: in std_logic_vector(4 downto 0);
			aw_reg: in std_logic_vector(4 downto 0);	-- addr to write data into register
			dw_reg: in std_logic_vector(31 downto 0);	-- write data
			we_reg: in std_logic;						-- write enable
			rd1_reg: out std_logic_vector(31 downto 0);
			rd2_reg: out std_logic_vector(31 downto 0)

	clk_fe: in std_logic;
    reset_fe: in std_logic := '0';
	stall_fe: in std_logic := '0';
	branch_taken_fe: in std_logic := '0'; -- Execute inbound
    branch_addr_fe: in std_logic_vector(31 DOWNTO 0); --Execute inbound / new PC
	pc_fe: out std_logic_vector(31 DOWNTO 0); -- PC, goes to everything until execute
	s_addr_inst_fe: out std_logic_vector(31 downto 0); -- send address to mem (is PC)
	s_read_inst_fe: out std_logic; -- send read signal to mem
	inst_fe: out std_logic_vector(31 downto 0); --  send instruction to ID
	s_waitrequest_inst_fe: in std_logic :='0'; -- get waitrequest signal from cache/mem
	_readdata_inst_fe: in std_logic_vector(31 downto 0); -- get instruction from cache/mem


	clk_dec: in std_logic;
	stall_d_dec: in std_logic;						-- input to stall decode, active high
	inst_dec: in std_logic_vector(31 downto 0); -- Instruction from fetch
	reg_dst_dec: in std_logic;		-- from the control unit, 1 if writeback to Rd, 0 if Rt
	jump_dec: in std_logic;			-- from the control unit, 1 if it's a jump instruction	
	sign_ext_dec: in std_logic;		-- from the control unit. 1 if sign extend, 0 if zero extend
	reg_write_e_dec: in std_logic;	
	write_reg_e_dec: in std_logic_vector(4 downto 0);
	reg_write_m_dec: in std_logic;
	write_reg_m_dec: in std_logic_vector(4 downto 0);
	reg_write_w_dec: in std_logic;
	write_reg_w_dec: in std_logic_vector(4 downto 0);
	pc_in_dec: in std_logic_vector(31 downto 0);
	pc_out_dec: out std_logic_vector(31 downto 0);
	op_dec: out std_logic_vector(5 downto 0);		-- opcode to control unit
	funct_dec: out std_logic_vector(5 downto 0);	-- funct to control unit
	a1_out_dec: out std_logic_vector(4 downto 0);	-- a1 to register file
	a2_out_dec: out std_logic_vector(4 downto 0);	-- a2 to register file
	aw_out_dec: out std_logic_vector(4 downto 0);	-- pass writeback address from write_reg_w to the register file
	we_out_dec: out std_logic;						-- pass reg_write_w signal to write enable of the register file
	write_reg_out_dec: out std_logic_vector(4 downto 0);	-- writeback register address
	stall_f_dec: out std_logic;							-- signal to stall fetch
	imm_out_dec: out std_logic_vector(31 downto 0); -- Immediate after sign extended
	fwd1_out_dec: out std_logic;		-- switch to the muxes in the forwarding unit of decode stage
	fwd2_out_dec: out std_logic

    clk_ctr : in std_logic;
	op_ctr: in std_logic_vector(5 downto 0);			-- 6-bit opcode
	funct_ctr: in std_logic_vector(5 downto 0);			-- 6-bit funct
	reg_eq_ctr: in std_logic;							-- set if rd1=rd2, conencted to eq output of fwd_decode
	alu_src_ctr: out std_logic;							-- the flag is set if the operation uses an immediate value as an operand
	reg_write_ctr: out std_logic;						-- set if register writeback is needed
	mem_to_reg_ctr: out std_logic;						-- set if loading
	mem_write_ctr: out std_logic;						-- set if writing result to memory
	reg_dst_ctr: out std_logic;							-- 0 if Rt, 1 if Rd
	branch_ctr: out std_logic;						
	jump_ctr: out std_logic;							-- if set, PC is updated with imm sll 2
	link_ctr: out std_logic;
	sign_ext_ctr: out std_logic;
	alu_mode_ctr: out alu_enum
    
	rd1_in_fwd: in std_logic_vector(31 downto 0); -- incoming register value from reg file
	rd2_in_fwd: in std_logic_vector(31 downto 0); -- incoming value from reg file
	fwd_in_fwd: in std_logic_vector(31 downto 0); -- incoming forwarded value (if needed)
	fwd1_fwd: in std_logic; -- selectors for if forwarded is needed
	fwd2_fwd: in std_logic;
	eq_fwd: out std_logic; -- if they're equal (for branching)
	rd1_out_fwd: out std_logic_vector(31 downto 0); --outgoing values for execute
	rd2_out_fwd: out std_logic_vector(31 downto 0)    
    
    alu_mode_ex: in alu_enum; --mode of the ALU
    r1_ex: in std_logic_vector(31 downto 0); --register 1
    r2_ex: in std_logic_vector(31 downto 0); -- register 2
    immEx_ex: in std_logic_vector(31 downto 0); -- extended Immediate
    WB_register_ex: in std_logic_vector(4 downto 0); -- register number of changed one
    branch_ex: in std_logic_vector(1 downto 0); --tells what kind of branch to do
    jump_ex: in std_logic_vector(1 downto 0); -- what kind of jump required
    Mem2Reg_ex: in std_logic; -- read data from main memory
    MemWrite_ex: in std_logic; -- write data from register to memory
    immUse_ex: in std_logic -- use the immediate value
    PC_ex:in std_logic_vector(31 downto 0); -- PC of instruction
    
    Mem2Reg_out_ex: out std_logic; -- outputs read
    MemWrite_out_ex: out std_logic; -- outputs write
    WB_register_out_ex: out std_logic_vector(4 downto 0); -- outputs reg number
    Var_out_ex: out std_logic_vector(31 downto 0) -- outputs an unused but useful variable to check?
    alu_result_out_ex: out std_logic_vector(31 downto 0);
    PC_out_ex : out std_logic_vector(31 downto 0); -- pc if updated by Jump/ branch, goes to fetch
    old_PC_ex: out std_logic_vector(31 downto 0)




 	reset_mem : in std_logic;
	
	-- Avalon interface --

        ALU_result_in_mem : in std_logic_vector(63 downto 0);
        ALU_result_out_mem : out std_logic_vector(63 downto 0);
        instruction_in_mem : in INSTRUCTION; -- Use control signals to modify
        instruction_out_mem : out INSTRUCTION;
        val_b_mem : in std_logic_vector(31 downto 0);
        mem_data_mem : out std_logic_vector(31 downto 0);



	s_addr_mem : in std_logic_vector (31 downto 0);
	s_read_mem : in std_logic;
	s_readdata_mem : out std_logic_vector (31 downto 0); -- goes to fetch
	s_write_mem : in std_logic;
	s_writedata_mem : in std_logic_vector (31 downto 0);
	s_waitrequest_mem : out std_logic; -- goes to fetch
    
	m_addr_mem : out integer range 0 to ram_size-1; -- go to memory
	m_read_mem : out std_logic;
	m_readdata_mem : in std_logic_vector (31 downto 0); -- comes from memory
	m_write_mem : out std_logic; -- goes to memory
	m_writedata_mem : out std_logic_vector (31 downto 0); -- goes to memory
	m_waitrequest_mem : in std_logic -- go to fetch           
            
            
    mem_to_reg_wb	: in std_logic; -- if need to write to register file
	read_data_wb	: in std_logic_vector(31 downto 0); -- read data from memory
	alu_result_wb	: in std_logic_vector(31 downto 0); -- result from alu if this needs to be stored
	write_data_wb	: out std_logic_vector(31 downto 0)); -- sends data to register file
 
 begin
 data_memory: memory port map
 inst_memory:memory port map
 reg_file: register_file port map
 fetch:fetch port map
 decode:decode port map
 ctrl: ctrl_unit port map
 execute: execute port map
 mem: mem port map
 wb: write_back port map
