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
		s_addr_inst: out std_logic_vector(31 downto 0); -- send address to cache
		s_read_inst: out std_logic; -- send read signal to cache
		inst: out std_logic_vector(31 downto 0); --  send instruction to ID
		s_waitrequest_inst: in std_logic :='0'; -- get waitrequest signal from cache
		s_readdata_inst: in std_logic_vector(31 downto 0) -- get instruction from cache
        --mem_data_stall: in std_logic; 
		--ismiss: in std_logic := '0'
		
	);
    end fetch;

    architecture arch of fetch is
        --pc_internal used for calculations
        signal pc_internal: std_logic_vector(31 DOWNTO 0) := "00000000000000000000000000000000";
        signal pc_reset: unsigned(31 downto 0) := "00000000000000000000000000000000";
    begin

        process(clk, s_waitrequest_inst)
        begin
            if (rising_edge(clk)) then
                s_read_inst <= '0'; --reset the read signal
                if (reset = '1') then
                    pc_internal <= std_logic_vector(pc_reset);

                elsif (stall = '1') then
                    inst <= x"00000020"; -- stall by sending 0+0=0

                elsif (branch_taken = '1') then
                    pc_internal <= branch_addr;
                    --s_addr_inst <= branch_addr;
                    
                elsif (branch_taken = '0') and (stall = '0') and (s_waitrequest_inst = '0') then
                    s_addr_inst <= pc_internal;
                    s_read_inst <= '1';
                    pc_internal <= std_logic_vector(to_unsigned( to_integer(unsigned(pc_internal)) + 4,32));
                else
                    inst <= x"00000020"; -- stall by sending 0+0=0
                end if;
            end if;

            if (falling_edge(s_waitrequest_inst)) then --results from memory are ready
                inst <= s_readdata_inst;
            end if;
            pc <= pc_internal;
        end process;
    end arch;