library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity writeback_tb is
end writeback_tb;

architecture arch of writeback_tb is

    constant clk_period : time := 1 ns;

    component write_back is
        port(    
                clk				: in std_logic;
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

    signal clk : std_logic;
    signal mem_to_reg : std_logic;
    signal reg_write_in : std_logic;
    signal write_reg_in : std_logic_vector(4 downto 0);
    signal read_data : std_logic_vector(31 downto 0);
    signal alu_result : std_logic_vector(31 downto 0);
    signal write_data : std_logic_vector(31 downto 0);
    signal write_reg_out : std_logic_vector(4 downto 0);
    signal reg_write_out : std_logic;

begin

    dut : write_back 
    port map (
        clk,
        mem_to_reg,
        reg_write_in,
        write_reg_in,
        read_data,
        alu_result,
        write_data,
        write_reg_out,
        reg_write_out
    );

    -- Clock generation
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    test_process : process
    begin
        -- Initialize to '0'
        reg_write_in <= '0';
        write_reg_in <= "00000";
        wait for 1*clk_period;

        
        reg_write_in <= '1';
        wait for 1*clk_period;
        assert (reg_write_out = '1') report "Value not transferred" severity failure;

        write_reg_in <= "01110";
        wait for 1*clk_period;
        assert (write_reg_out = "01110") report "Value not transferred" severity failure;

        alu_result <= x"0000AAAA";
        read_data <= x"FFFFBBBB";
        
        mem_to_reg <= '0';
        wait for 1*clk_period;
        assert(write_data = x"0000AAAA") report "Alu value not passed via mux" severity failure;

        mem_to_reg <= '1';
        wait for 1*clk_period;
        assert(write_data = x"FFFFBBBB") report "Mem data not passed via mux" severity failure;

        report "All writeback test completed";

    end process;

end arch;