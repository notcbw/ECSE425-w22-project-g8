-- decode and hazard detection
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
	port(	clk: in std_logic;
			stall_d: in std_logic;						-- input to stall decode, active high
			inst: in std_logic_vector(31 downto 0);
			reg_dst: in std_logic;		-- from the control unit, 1 if writeback to Rd, 0 if Rt
			jump: in std_logic;			-- from the control unit, 1 if it's a jump instruction	
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
			fwd1_out: out std_logic := '0';		-- switch to the muxes in the forwarding unit of decode stage
			fwd2_out: out std_logic := '0'
			);
end decode;

architecture rtl of decode is
	signal wait_dd: std_logic := '0';
begin
	-- stall fetch if either decode is waiting for data dependency, or the next stages are stopped
	stall_f <= wait_dd or stall_d;
	aw_out <= write_reg_w;
	we_out <= reg_write_w;
	
	-- asynchronous process to switch between sign extended imm and zero extended imm
	extend: process(jump,sign_ext)
	begin
		if sign_ext'event or jump'event then
			if jump='1' then
				-- jump instruction, extend 26 bit address to immediate output
				imm_out(25 downto 0) <= inst(25 downto 0);
				imm_out(31 downto 26) <= "000000";
			else
				if sign_ext='1' then
					-- sign extend
					imm_out <= std_logic_vector(resize(signed(inst(15 downto 0)), 32));
				else
					-- zero extend
					imm_out(15 downto 0) <= inst(15 downto 0);
					imm_out(31 downto 16) <= x"0000";
				end if;
			end if;
		end if;
	end process;
	
	-- asynchronous process for switching between two writeback addresses
	write_reg_mux: process(reg_dst)
	begin
		if reg_dst'event then
			if reg_dst='1' then
				-- wb to Rd
				write_reg_out <= inst(15 downto 11);
			else
				-- wb to Rt
				write_reg_out <= inst(20 downto 16);
			end if;
		end if;
	end process;
	
	-- main synchronous decoding process
	decode: process(clk)
	begin
		if clk'event and clk='1' then
			-- instruction decoding logic, affected by stalling
			if (wait_dd='0') and (stall_d='0') then
				-- simple decoding
				op <= inst(31 downto 26);
				funct <= inst(5 downto 0);
				a1_out <= inst(25 downto 21);
				a2_out <= inst(20 downto 16);
			end if;
			
			-- hazard detection, not affected by the stall
			if (inst(31 downto 26)="000010") nor (inst(31 downto 26)="000011") then
				-- if not a jump instruction
				-- if there is a data hazard, stall
				if reg_write_e='1' then
					-- check for data dependency
					if (write_reg_e=inst(25 downto 21)) or (write_reg_e=inst(20 downto 16)) then
						-- data dependency detected, wait
						wait_dd <= '1';
					else
						wait_dd <= '0';
					end if;
				end if;
				
				-- resolving the data hazard, resume pipeline
				if reg_write_m='1' then
					-- forwarding for rd1
					if (write_reg_m=inst(25 downto 21)) then
						-- change rd1 mux output and stop waiting
						fwd1_out <= '1';
						wait_dd <= '0';
					else
						fwd1_out <= '0';
					end if;
					-- forwarding for rd2
					if (write_reg_m=inst(20 downto 16)) then
						-- change rd2 mux output and stop waiting
						fwd2_out <= '1';
						wait_dd <= '0';
					else
						fwd2_out <= '0';
					end if;
				end if;
				
			end if;
			
		end if;
	end process;
	
end rtl;