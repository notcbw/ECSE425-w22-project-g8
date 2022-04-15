-- fetch
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity fetch is
	port(
		clk: in std_logic;
        reset: in std_logic := '0';
		stall: in std_logic := '0';
		branch_taken: in std_logic := '0';
        branch_addr: in std_logic_vector(31 DOWNTO 0);
		pc: out std_logic_vector(31 DOWNTO 0);
		s_addr_inst: out integer := 0; -- send address to memory
		s_read_inst: out std_logic; -- send read signal to memory
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from memory
		s_readdata_inst: in std_logic_vector(31 downto 0) -- get instruction from memory
		
	);
    end fetch;

    architecture arch of fetch is
        --pc_internal used for calculations
        signal pc_internal: std_logic_vector(31 DOWNTO 0) := "00000000000000000000000000000000";
        signal pc_reset: unsigned(31 downto 0) := "00000000000000000000000000000000";
        signal state: std_logic := '0';
    begin
		pc <= pc_internal;
		
        process(clk, branch_taken, s_waitrequest_inst)
        begin
			if branch_taken'event and branch_taken='1' then
				pc_internal <= branch_addr;
			end if;
			
            if clk'event and clk='1' then
                if (reset = '1') then
                    pc_internal <= std_logic_vector(pc_reset);
                end if;
                
                if state='0' then
					if (stall = '1') then
						 inst <= x"00000020"; -- stall by sending 0+0=0
					elsif (stall = '0') and (s_waitrequest_inst = '1') then
						s_addr_inst <= to_integer(unsigned(pc_internal));
						s_read_inst <= '1';
						pc_internal <= std_logic_vector(to_unsigned( to_integer(unsigned(pc_internal)) + 4,32));
						state <= '1';
					else
						inst <= x"00000020"; -- stall by sending 0+0=0
					end if;
				else 
					inst <= x"00000020";
				end if;
            end if;

            if s_waitrequest_inst'event and s_waitrequest_inst='1' then --results from memory are ready
                if state='1' then
					s_read_inst <= '0';
					inst <= s_readdata_inst;
					state <= '0';
				end if;
            end if;
        end process;
    end arch;
