-- test bench for decode
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;
library work;
use work.mips_common.all;

entity decode_tb is
end decode_tb;

architecture behaviour of decode_tb is
	
	component decode is 
		port(	clk: in std_logic;
				stall_d: in std_logic;						-- input to stall decode, active high
				inst: in std_logic_vector(31 downto 0);
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
				op: out std_logic_vector(5 downto 0);		-- opcode to control unit
				funct: out std_logic_vector(5 downto 0);	-- funct to control unit
				a1_out: out std_logic_vector(4 downto 0);	-- a1 to register file
				a2_out: out std_logic_vector(4 downto 0);	-- a2 to register file
				aw_out: out std_logic_vector(4 downto 0);	-- pass writeback address from write_reg_w to the register file
				we_out: out std_logic;						-- pass reg_write_w signal to write enable of the register file
				write_reg_out: out std_logic_vector(4 downto 0);	-- writeback register address
				stall_f: out std_logic;							-- signal to stall fetch
				imm_out: out std_logic_vector(31 downto 0);
				fwd1_out: out std_logic;		-- switch to the muxes in the forwarding unit of decode stage
				fwd2_out: out std_logic
			);
	end component;
	
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
		port(	rd1_in: in std_logic_vector(31 downto 0);
				rd2_in: in std_logic_vector(31 downto 0);
				fwd_in: in std_logic_vector(31 downto 0);
				fwd1: in std_logic;
				fwd2: in std_logic;
				eq: out std_logic;
				rd1_out: out std_logic_vector(31 downto 0);
				rd2_out: out std_logic_vector(31 downto 0)
				);
	end component;
	
	-- signals
	-- interconnections
	signal clk: std_logic;
	signal stall_d: std_logic := '0';
	signal inst: std_logic_vector(31 downto 0);
	signal reg_dst: std_logic;
	signal jump: std_logic;
	signal sign_ext: std_logic;	
	signal reg_write_e: std_logic := '0';
	signal write_reg_e: std_logic_vector(4 downto 0);
	signal reg_write_m: std_logic := '0';
	signal write_reg_m: std_logic_vector(4 downto 0);
	signal reg_write_w: std_logic := '0';
	signal write_reg_w: std_logic_vector(4 downto 0);
	signal op: std_logic_vector(5 downto 0);
	signal funct: std_logic_vector(5 downto 0);
	signal a1: std_logic_vector(4 downto 0);
	signal a2: std_logic_vector(4 downto 0);
	signal aw: std_logic_vector(4 downto 0);
	signal we: std_logic;
	signal write_reg_out: std_logic_vector(4 downto 0);
	signal stall_f: std_logic;	
	signal imm_out: std_logic_vector(31 downto 0);
	signal fwd1: std_logic;
	signal fwd2: std_logic;
	signal rd1_1: std_logic_vector(31 downto 0);
	signal rd2_1: std_logic_vector(31 downto 0);
	signal reg_eq: std_logic;
	-- test points
	signal dw: std_logic_vector(31 downto 0);
	signal rd1_2: std_logic_vector(31 downto 0);
	signal rd2_2: std_logic_vector(31 downto 0);
	signal fwd_in: std_logic_vector(31 downto 0);
	signal alu_src: std_logic;
	signal reg_write: std_logic;
	signal mem_to_reg: std_logic;
	signal mem_write: std_logic;
	signal branch: std_logic;
	signal link: std_logic;
	signal alu_mode: alu_enum;

begin
	
	dut: decode
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
		fwd_in => fwd_in,
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
		-- Register file: test reading / writing to the register file
		
		-- write 0xdeadbeef to R3
		wait until rising_edge(clk);
		dw <= x"deadbeef";
		write_reg_w <= "00011";
		reg_write_w <= '1';
		wait until rising_edge(clk);
		reg_write_w <= '0';
		inst <= "000000" & "00011" & "00011" & "00011" & "00000" & "100000";	-- add r3, r3, r3
		wait until rising_edge(clk);
		-- decode stage of add r3, r3, r3
		wait until rising_edge(clk);
		-- check result at the register output
		assert rd1_2 = x"deadbeef" report "Decode test 01 failed, write unsuccessful to register file." severity error;
		
		-- Decoder: test immediate extension
		
		-- signed extension, negative
		inst <= "001000" & "00010" & "00011" & x"ffc0";	-- addi r2, r3, #-64
		wait until rising_edge(clk);
		-- decode stage of addi r2, r3, #-64
		wait until rising_edge(clk);
		assert imm_out = x"ffffffc0" report "Decode test 02 failed, wrong sign extended value of negative integer." severity error;
		
		-- signed extension, positive
		inst <= "001000" & "00010" & "00011" & x"0100";	-- addi r2, r3, #64
		wait until rising_edge(clk);
		-- decode stage of addi r2, r3, #64
		wait until rising_edge(clk);
		assert imm_out = x"00000100" report "Decode test 03 failed, wrong sign extended value of positive integer." severity error;
		
		-- zero extension
		inst <= "001100" & "00010" & "00011" & x"ffc0";	-- andi r2, r3, #-64
		wait until rising_edge(clk);
		-- decode stage of andi r2, r3, #-64
		wait until rising_edge(clk);
		assert imm_out = x"0000ffc0" report "Decode test 04 failed, wrong zero extended value of integer." severity error;
		
		-- jump extension
		inst <= "000010" & "10" & x"0d2af0";	-- 0x020d2af0
		wait until rising_edge(clk);
		-- decode stage of j
		wait until rising_edge(clk);
		assert imm_out = x"020d2af0" report "Decode test 05 failed, wrong extended jump address." severity error;
		
		-- mux for forwarding logic
		
		-- eq signal
		dw <= x"12345678";	-- write 0x12345678 to R4
		write_reg_w <= "00100";
		reg_write_w <= '1';
		wait until rising_edge(clk);
		reg_write_w <= '0';
		inst <= "000000" & "00011" & "00011" & "00011" & "00000" & "100000";	-- add r3, r3, r3
		wait until rising_edge(clk);
		-- decode stage of add r3, r3, r3
		wait until rising_edge(clk);
		-- check result at the register output
		assert reg_eq = '1' report "Decode test 06 failed, eq not asserted when two operands are equal" severity error;
		inst <= "000000" & "00100" & "00011" & "00011" & "00000" & "100000";	-- add r4, r3, r3
		wait until rising_edge(clk);
		--decode stage of add r4, r3, r3
		wait until rising_edge(clk);
		assert reg_eq = '0' report "Decode test 07 failed, eq asserted when two operands are not equal" severity error;
		
		-- forwarding mux: switch between register values and forwarded value
		inst <= "000000" & "00011" & "00100" & "00011" & "00000" & "100000";	-- add r3, r3, r4
		fwd_in <= x"abbbbbbb";
		-- simulate forwarding from memory stage
		wait until rising_edge(clk);
		reg_write_m <= '1';
		write_reg_m <= "00011";
		wait until rising_edge(clk);
		assert rd1_2 = x"abbbbbbb" report "Decode test 08 failed, rd1 output is not the forwarded value." severity error;
		assert rd2_2 = x"12345678" report "Decode test 09 failed, rd2 output is not the value from the register" severity error;
		-- simulate forwarding from memory stage
		wait until rising_edge(clk);
		write_reg_m <= "00100";
		wait until rising_edge(clk);
		assert rd1_2 = x"deadbeef" report "Decode test 10 failed, rd1 output is not the value from the register" severity error;
		assert rd2_2 = x"abbbbbbb" report "Decode test 11 failed, rd2 output is not the forwarded value." severity error;
		reg_write_m <= '0';
		
		-- detection for data dependencies
		inst <= "000000" & "00011" & "00100" & "00011" & "00000" & "100000";	-- add r3, r3, r4
		wait until rising_edge(clk);
		reg_write_e <= '1';
		write_reg_e <= "00011";
		wait until rising_edge(clk);
		assert stall_f = '1' report "Decode test 12 failed, pipeline is not stalled when there is a data dependency." severity error;
		
		-- automatically terminate test.
		wait until rising_edge(clk);
		stop;
	end process;
end;
