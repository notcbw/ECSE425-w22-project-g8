library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.instruction_tools.all;

entity mem is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --

        ALU_result_in : in std_logic_vector(63 downto 0);
        ALU_result_out : out std_logic_vector(63 downto 0);
        instruction_in : in INSTRUCTION;
        instruction_out : out INSTRUCTION;
        val_b : in std_logic_vector(31 downto 0);
        mem_data : out std_logic_vector(31 downto 0);



	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (31 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (31 downto 0);
	m_waitrequest : in std_logic
);
end mem;

architecture arch of mem is

begin
    instruction_out <= instruction_in;
    ALU_result_out <= ALU_result_in;

    mem_process : process(instruction_in, m_waitrequest)
    BEGIN
        CASE instruction_in.INSTRUCTION_TYPE IS
            WHEN load_word =>
               m_read <= '1';
                m_addr <= to_integer(unsigned(ALU_result_in(31 downto 0)));
                mem_data <= m_readdata;
            WHEN store_word =>
                m_write <= '1';
                m_addr <= to_integer(unsigned(ALU_result_in(31 downto 0)));
                m_write_data <= val_b;
            WHEN others =>
                    end case;

    end process;

end architecture'
