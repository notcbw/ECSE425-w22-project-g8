-- memory stage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is 
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
		m_addr : out integer := 0;
		m_read : out std_logic;
		m_readdata : in std_logic_vector (31 downto 0);
		m_write : out std_logic;
		m_writedata : out std_logic_vector (31 downto 0);
		m_waitrequest : in std_logic
		);
end memory;
	
architecture rtl of memory is
	signal alu_buf: std_logic_vector(31 downto 0);
	signal write_data_buf: std_logic_vector(31 downto 0);
	-- state
	type state_type is (default_state, wait_for_read, wait_for_write);
	signal cur_state: state_type;
begin
	stall <= '0' when cur_state=default_state else '1';
	process(clk)
	begin
		if clk'event and clk='1' then
			case cur_state is
				when default_state =>
					-- pass the signals out
					reg_write_out <= reg_write_in;
					mem_to_reg_out <= mem_to_reg_in;
					write_reg_out <= write_reg_in;
					alu_out <= alu_in;
					alu_buf <= alu_in;
					write_data_buf <= write_data;
			
					if mem_to_reg_in='1' then
						-- load instruction, read mem
						m_addr <= to_integer(unsigned(alu_in));
						m_read <= '1';
						cur_state <= wait_for_read;
					end if;
			
					if mem_write_in='1' then
						-- store instruction, write mem
						m_addr <= to_integer(unsigned(alu_in));
						m_writedata <= write_data;
						m_write <= '1';
						cur_state <= wait_for_write;
					end if;
					
				when wait_for_read =>
					if m_waitrequest='1' then
						-- read complete
						m_read <= '0';
						data_out <= m_readdata;
						cur_state <= default_state;
					end if;
				
				when wait_for_write =>
					if m_waitrequest='1' then
						-- write complete
						m_write <= '0';
						cur_state <= default_state;
					end if;
						
			end case;
		end if;
	end process;
	
end rtl;