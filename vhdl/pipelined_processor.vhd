-- put all components together
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
library work;
use work.mips_common.all;

entity processor is 
generic(
	ram_size : INTEGER := 32768
);
port(
	clk: in std_logic;
	initialise: in std_logic;
	reset: in std_logic;
	write_to_text: in std_logic
    );
end processor;
    
architecture behaviour of processor is

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
		s_addr_inst: out integer; -- send address to mem (is PC)
		s_read_inst: out std_logic; -- send read signal to mem
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache/mem
		s_readdata_inst: in std_logic_vector(31 downto 0) -- get instruction from cache/mem
	);
    end component;
    
component decode is
	port(	
		clk: in std_logic;
		stall_d: in std_logic;						-- input to stall decode, active high
		inst: in std_logic_vector(31 downto 0); -- Instruction from fetch
		reg_dst: in std_logic;		-- from the control unit, 1 if writeback to Rd, 0 if Rt
		jump: in std_logic;			-- from the control unit, 1 if it's a jump instruction	
		link: in std_logic;
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
	port(	
		clk : in std_logic;
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
	port(	
		rd1_in: in std_logic_vector(31 downto 0); -- incoming register value from reg file
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
	    branch: in std_logic;
	    jump: in std_logic;
		link: in std_logic;
		stall: in std_logic;
		reg_write: in std_logic;
	    Mem2Reg: in std_logic; -- read data from main memory
	    MemWrite: in std_logic; -- write data from register to memory
	    immUse: in std_logic; -- use the immediate value
	    PC:in std_logic_vector(31 downto 0); -- PC of instruction
    
		stall_out: out std_logic;
		reg_write_out: out std_logic;
	    Mem2Reg_out: out std_logic; -- outputs read
	    MemWrite_out: out std_logic; -- outputs write
	    WB_register_out: out std_logic_vector(4 downto 0); -- outputs reg number
	    write_data_out: out std_logic_vector(31 downto 0);
	    alu_result_out: out std_logic_vector(31 downto 0);
		pc_write: out std_logic;
	    PC_out : out std_logic_vector(31 downto 0)
	    );
 end component;
 
component memory is
	port(	clk: in std_logic;
		
			reg_write_in: in std_logic;
			mem_to_reg_in: in std_logic;
			mem_write_in: in std_logic;
			write_reg_in: in std_logic_vector(4 downto 0);
		
			alu_in: in std_logic_vector(31 downto 0);	-- address for writing
			write_data: in std_logic_vector(31 downto 0);	-- data to write
		
			reg_write_out: out std_logic;
			mem_to_reg_out: out std_logic;
			write_reg_out: out std_logic_vector(4 downto 0);
		
			data_out: out std_logic_vector(31 downto 0);
			alu_out: out std_logic_vector(31 downto 0);
			stall: out std_logic;
		
			-- avalon interface to memory or cache
			m_addr : out integer;
			m_read : out std_logic;
			m_readdata : in std_logic_vector (31 downto 0);
			m_write : out std_logic;
			m_writedata : out std_logic_vector (31 downto 0);
			m_waitrequest : in std_logic
			);
end component;

component write_back is
	port(	clk				: in std_logic;
			mem_to_reg		: in std_logic;
			reg_write_in	: in std_logic;
			write_reg_in	: in std_logic_vector(4 downto 0);
			read_data		: in std_logic_vector(31 downto 0);
			alu_result		: in std_logic_vector(31 downto 0);
			write_data		: out std_logic_vector(31 downto 0);
			write_reg_out	: out std_logic_vector(4 downto 0);
			reg_write_out	: out std_logic
			);
end component;

component inst_memory is
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
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

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
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC;
		
		write_to_text: in std_logic	-- set this high to write memory to file
	);
end component;
		
-- signals
-- generic
signal alu_mode: alu_enum;

-- hazard/forwarding
signal reg_write_e: std_logic;
signal write_reg_e: std_logic_vector(4 downto 0);
signal reg_write_m: std_logic;
signal write_reg_m: std_logic_vector(4 downto 0);
signal reg_write_w: std_logic;
signal write_reg_w: std_logic_vector(4 downto 0);

-- instruction memory avalon interface
signal i_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal i_address: INTEGER RANGE 0 TO ram_size-1;
signal i_memwrite: STD_LOGIC;
signal i_memread: STD_LOGIC;
signal i_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal i_waitrequest: STD_LOGIC;

-- data memory avalon interface
signal d_writedata: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal d_address: INTEGER RANGE 0 TO ram_size-1;
signal d_memwrite: STD_LOGIC;
signal d_memread: STD_LOGIC;
signal d_readdata: STD_LOGIC_VECTOR (31 DOWNTO 0);
signal d_waitrequest: STD_LOGIC;

-- fetch
signal stall_f: std_logic;	
signal branch_taken: std_logic;
signal branch_addr: std_logic_vector(31 downto 0);
signal pc_if_to_id: std_logic_vector(31 downto 0);
signal s_addr_inst: std_logic_vector(31 downto 0);
signal s_read_inst: std_logic;
signal inst: std_logic_vector(31 downto 0);
signal s_waitrequest_inst: std_logic;
signal s_readdata_inst: std_logic_vector(31 downto 0);

-- decode
signal stall_d: std_logic;
signal reg_dst: std_logic;
signal jump: std_logic;
signal sign_ext: std_logic;	
signal op: std_logic_vector(5 downto 0);
signal funct: std_logic_vector(5 downto 0);
signal a1: std_logic_vector(4 downto 0);
signal a2: std_logic_vector(4 downto 0);
signal aw: std_logic_vector(4 downto 0);
signal we: std_logic;
signal write_reg_out: std_logic_vector(4 downto 0);
signal imm_out: std_logic_vector(31 downto 0);
signal fwd1: std_logic;
signal fwd2: std_logic;
signal rd1_1: std_logic_vector(31 downto 0);
signal rd2_1: std_logic_vector(31 downto 0);
signal reg_eq: std_logic;
signal dw: std_logic_vector(31 downto 0);
signal rd1_2: std_logic_vector(31 downto 0);	-- actual data output of the decode stage
signal rd2_2: std_logic_vector(31 downto 0);	-- actual data output of the decode stage
signal alu_src: std_logic;
signal reg_write: std_logic;
signal mem_to_reg: std_logic;
signal mem_write: std_logic;
signal branch: std_logic;
signal link: std_logic;
signal pc_id_to_ex: std_logic_vector(31 downto 0);

-- execute
signal stall_e: std_logic;
signal mem_to_reg_ex: std_logic;
signal mem_write_ex: std_logic;
signal write_data_ex: std_logic_vector(31 downto 0);
signal alu_result: std_logic_vector(31 downto 0);
signal pc_ex_to_if: std_logic_vector(31 downto 0);

-- memory
signal mem_to_reg_m: std_logic;
signal data_m: std_logic_vector(31 downto 0);
signal alu_out_m: std_logic_vector(31 downto 0);

begin
	fet:fetch
	port map(
		clk => clk,
		reset => reset,
		stall => stall_f,
		branch_taken => branch_taken,
		branch_addr => pc_ex_to_if,
		pc => pc_if_to_id,
		s_addr_inst => i_address,
		s_read_inst => i_memread,
		inst => inst,
		s_waitrequest_inst => i_waitrequest,
		s_readdata_inst => i_readdata
		);
	
	id: decode
	port map(
		clk => clk,
		stall_d => stall_d,
		inst => inst,
		reg_dst => reg_dst,
		jump => jump,
		link => link,
		sign_ext => sign_ext,
		reg_write_e => reg_write_e,
		write_reg_e => write_reg_e,
		reg_write_m => reg_write_m,
		write_reg_m => write_reg_m,
		reg_write_w => reg_write_w,
		write_reg_w => write_reg_w,
		pc_in => pc_if_to_id,
		pc_out => pc_id_to_ex,
		
		op => op,
		funct => funct,
		a1_out => a1,
		a2_out => a2,
		aw_out => aw,
		we_out => we,
		write_reg_out => write_reg_out,
		stall_f => stall_f,
		imm_out => imm_out,
		fwd1_out => fwd1,
		fwd2_out => fwd2
		);
		
	reg: register_file
	port map(
		clk => clk,
		a1 => a1,
		a2 => a2,
		aw => aw,
		dw => dw,
		we => we,
		rd1 => rd1_1,
		rd2 => rd2_1
		);
		
	fwd: fwd_decode
	port map(
		rd1_in => rd1_1,
		rd2_in => rd2_1,
		fwd_in => alu_out_m,
		fwd1 => fwd1,
		fwd2 => fwd2,
		eq => reg_eq,
		rd1_out => rd1_2,
		rd2_out => rd2_2
		);
		
	ctl: ctrl_unit
	port map(
		clk => clk,
		op => op,
		funct => funct,
		reg_eq => reg_eq,
		alu_src => alu_src,
		reg_write => reg_write,
		mem_to_reg => mem_to_reg,
		mem_write => mem_write,
		reg_dst => reg_dst,
		branch => branch,
		jump => jump,
		link => link,
		sign_ext => sign_ext,
		alu_mode => alu_mode
		);
		
	ex: execute
	port map(
		clk => clk,
		alu_mode => alu_mode,
		r1 => rd1_2,
		r2 => rd2_2,
		immEx => imm_out,
		WB_register => write_reg_out,
		branch => branch,
		jump => jump,
		link => link,
		stall => stall_e,
		reg_write => reg_write,
		Mem2Reg => mem_to_reg,
		MemWrite => mem_write,
		immUse => alu_src,
		PC => pc_id_to_ex,
		stall_out => stall_d,
		reg_write_out => reg_write_e,
		Mem2Reg_out => mem_to_reg_ex,
		MemWrite_out => mem_write_ex,
		WB_register_out => write_reg_e,
		write_data_out => write_data_ex,
		alu_result_out => alu_result,
		pc_write => branch_taken,
		PC_out => pc_ex_to_if
		);	
		
	mem: memory
	port map(
		clk => clk,
		reg_write_in => reg_write_e,
		mem_to_reg_in => mem_to_reg_ex,
		mem_write_in => mem_write_ex,
		write_reg_in => write_reg_e,
		alu_in => alu_result,
		write_data => write_data_ex,
		reg_write_out => reg_write_m,
		mem_to_reg_out => mem_to_reg_m,
		write_reg_out => write_reg_m,
		data_out => data_m,
		alu_out => alu_out_m,
		stall => stall_e,
		m_addr => d_address,
		m_read => d_memread,
		m_readdata => d_readdata,
		m_write => d_memwrite,
		m_writedata => d_writedata,
		m_waitrequest => d_waitrequest
		);
		
	wb: write_back
	port map(
		clk => clk,
		mem_to_reg => mem_to_reg_m,
		reg_write_in => reg_write_m,
		write_reg_in => write_reg_m,
		read_data => data_m,
		alu_result => alu_out_m,
		write_data => dw,
		write_reg_out => write_reg_w,
		reg_write_out => reg_write_w
		);
		
	ins: inst_memory
	port map(
		clock => clk,
		writedata => i_writedata,
		address => i_address,
		memwrite => i_memwrite,
		memread => i_memread,
		readdata => i_readdata,
		waitrequest => i_waitrequest
		);
		
	dat: data_memory
	port map(
		clock => clk,
		writedata => d_writedata,
		address => d_address,
		memwrite => d_memwrite,
		memread => d_memread,
		readdata => d_readdata,
		waitrequest => d_waitrequest,
		write_to_text => write_to_text
		);

end behaviour;
