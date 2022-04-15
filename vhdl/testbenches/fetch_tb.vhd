-- test bench for fetch
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library std;
use std.env.all;

entity fetch_tb is
end fetch_tb;

architecture behaviour of fetch_tb is
	
    component fetch is
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
        	);
   	end component;
	
	
	-- signals
	-- interconnections
	signal clk: std_logic;
	signal reset: std_logic := '0';
	signal stall: std_logic := '0';
    signal branch_taken: std_logic := '0';
    signal branch_addr:  std_logic_vector(31 DOWNTO 0);
    signal pc: std_logic_vector(31 DOWNTO 0);
    signal s_addr_inst: std_logic_vector(31 downto 0); -- send address to cache
    signal s_read_inst: std_logic; -- send read signal to cache
    signal inst: std_logic_vector(31 downto 0); --  send instruction to ID
    signal s_waitrequest_inst: std_logic :='0'; -- get waitrequest signal from cache
    signal s_readdata_inst: std_logic_vector(31 downto 0); -- get instruction from cache

begin
	
	dut: fetch
	port map(
		clk => clk,
		reset => reset,
		stall => stall,
		branch_taken => branch_taken,
		branch_addr => branch_addr,
		pc => pc,
		s_addr_inst => s_addr_inst,
		s_read_inst => s_read_inst,
		inst => inst,
		s_waitrequest_inst => s_waitrequest_inst,
		s_readdata_inst => s_readdata_inst
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
		-- Test 01: normal fetch with no stall and 1cc memory delay
		stall <= '0';
        s_readdata_inst <= x"deadbeef";
        s_waitrequest_inst <= '1';
        wait until rising_edge(clk);
        s_waitrequest_inst <= '0';
        wait until rising_edge(clk);
        -- check the instruction output and pc
        assert inst = x"deadbeef" report "Fetch test 01 failed, instruction output incorrect" severity error;
        assert pc = x"4" report "Fetch test 01 failed, PC output incorrect" severity error;
		
        -- Test 02: normal fetch with no stall and 10cc memory delay
		stall <= '0';
        s_readdata_inst <= x"beefdead";
        s_waitrequest_inst <= '1';
        wait until rising_edge(clk);
        s_waitrequest_inst <= '0';
        wait until rising_edge(clk);
        -- check the instruction output and pc
        assert inst = x"beefdead" report "Fetch test 02 failed, instruction output incorrect" severity error;
        assert pc = x"8" report "Fetch test 02 failed, PC output incorrect" severity error;
        
        -- Test 03: branch with no stall and 1cc memory delay
		stall <= '0';
        branch_taken <= '1';
        branch_addr <= x''
        s_waitrequest_inst <= '1';
        wait until rising_edge(clk);
        s_waitrequest_inst <= '0';
        wait until rising_edge(clk);
        -- check the instruction output and pc
        assert inst = x"beefdead" report "Fetch test 02 failed, instruction output incorrect" severity error;
        assert pc = x"8" report "Fetch test 02 failed, PC output incorrect" severity error;

		-- automatically terminate test.
		wait until rising_edge(clk);
		stop;
	end process;
end;