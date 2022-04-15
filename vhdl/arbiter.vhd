-- cache arbiter
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity arbiter is
	generic(
	ram_size : INTEGER := 32768
	);
	port(
		clk: in std_logic;

        i_writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		i_address: IN INTEGER;
		i_memwrite: IN STD_LOGIC;
		i_memread: IN STD_LOGIC;
		i_readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		i_waitrequest: OUT STD_LOGIC := '1';

        d_writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		d_address: IN INTEGER;
		d_memwrite: IN STD_LOGIC;
		d_memread: IN STD_LOGIC;
		d_readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		d_waitrequest: OUT STD_LOGIC := '1';

        m_writedata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		m_address: OUT INTEGER range 0 to ram_size-1;
		m_memwrite: OUT STD_LOGIC := '0';
		m_memread: OUT STD_LOGIC := '0';
		m_readdata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		m_waitrequest: IN STD_LOGIC
	);
    end arbiter;

architecture behaviour of arbiter is
    	-- states
	type state_type is (default_state, wait_for_instruction_read, wait_for_data_read, wait_for_data_write, wait_for_both, wait_cycle);
	signal cur_state: state_type := default_state;
    begin
    
    	
    
        process(clk, m_waitrequest, i_memread, d_memwrite, d_memread)
            begin
                if clk'event and clk='1' then
                    case cur_state is
                        when default_state =>
                            if i_memread = '1' and d_memwrite = '0' and d_memread = '0' then
                                i_waitrequest <= '0';
                                m_address <= i_address;
                                m_memread <= '1';
                                cur_state <= wait_for_instruction_read;
                            elsif i_memread = '0' and d_memwrite = '1' and d_memread = '0' then
                                d_waitrequest <= '0';
                                m_address <= d_address;
                                m_writedata <= d_writedata;
                                m_memwrite <= '1';
                                cur_state <= wait_for_data_write;
                            elsif i_memread = '0' and d_memwrite = '0' and d_memread = '1' then
                                d_waitrequest <= '0';
                                m_address <= d_address;
                                m_memread <= '1';
                                cur_state <= wait_for_data_read;
                            elsif i_memread = '1' and d_memwrite = '1' and d_memread = '0' then
                                -- service data first
                                d_waitrequest <= '0';
                                i_waitrequest <= '0';
                                m_address <= d_address;
                                m_writedata <= d_writedata;
                                m_memwrite <= '1';
                                cur_state <= wait_for_both;
                            elsif i_memread = '1' and d_memwrite = '0' and d_memread = '1' then
                                -- service data first
                                d_waitrequest <= '0';
                                i_waitrequest <= '0';
                                m_address <= d_address;
                                m_memread <= '1';
                                cur_state <= wait_for_both;
                            end if;
                        when wait_for_instruction_read =>
                            --do nothing
                        when wait_for_data_read =>
                            --do nothing
                        when wait_for_data_write =>
                            --do nothing
                        when wait_for_both =>
                            --do nothing
                        when wait_cycle =>
                        	-- wait a clock cycle then proceed to instruction read
                        	m_memread <= '1';
                        	m_address <= i_address;
                        	-- i_waitrequest <= '0';
                        	cur_state <= wait_for_instruction_read;
                    end case;
                end if;

                if m_waitrequest'event and m_waitrequest='1' then
                    m_memread <= '0';
                    m_memwrite <= '0';
                    case cur_state is
                    	 when default_state =>
                    	 -- do nothing
                    	 
                        when wait_for_instruction_read =>
                            i_waitrequest <= '1';
                            i_readdata <= m_readdata;
                            cur_state <= default_state;

                        when wait_for_data_read =>
                            d_waitrequest <= '1';
                            d_readdata <= m_readdata;
                            cur_state <= default_state;

                        when wait_for_data_write =>
                            d_waitrequest <= '1';
                            cur_state <= default_state;    

                        when wait_for_both =>
                            -- if write_data first then send the data out
                            if d_memread = '1' then
                                d_readdata <= m_readdata;
                            end if;
                            d_waitrequest <= '1';
                            m_memread <= '0';
                            m_memwrite <= '0';
                            cur_state <= wait_cycle;
                            
                        when wait_cycle =>
                        	-- do nothing
                    end case;
                end if;
        end process;
end architecture;
        
