library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer := 0;
	m_read : out std_logic := '0';
	m_readdata : in std_logic_vector (31 downto 0);
	m_write : out std_logic := '0';
	m_writedata : out std_logic_vector (31 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is

	-- States
	type state_type is (hit_check, write_back, read_mem, read_return, cache_write);
	signal current_state: state_type;
	
	-- dblock: data block of 4 of 32-bit words
	type dblock is array(3 downto 0) of std_logic_vector(31 downto 0);

	-- cell: each cell of the cache. Consisting a valid bit, a 6-bit tag and a 128-bit data block
	type line is record
		valid	: std_logic;
		dirty	: std_logic;
		tag		: std_logic_vector(5 downto 0);	-- 6-bit tag
		data	: dblock;	-- 128-bit block
	end record;
	
	-- cache_array: the caches with 32 lines, matryoshka style
	type cache_array is array(31 downto 0) of line;
	signal cache_body: cache_array;

	-- buffers
	signal buf_s_addr: std_logic_vector(31 downto 0);
	signal buf_s_data: std_logic_vector(31 downto 0);
	signal addr_buf: std_logic_vector(31 downto 0);
	
	-- flags
	signal flag_write: std_logic := '0';
	signal mem_read_ready: std_logic := '1';
	signal loop_counter: integer range 0 to 3;

begin

	addr_buf(3 downto 2) <= std_logic_vector(to_unsigned(loop_counter, 2));
	addr_buf(1 downto 0) <= "00";

-- state machine of cache
cache_logic: process (clock, reset, m_waitrequest)
begin
	if reset'event and reset = '0' then
		-- reset wait request on the falling edge of reset
		s_waitrequest <= '1';
	elsif reset'event and reset = '1' then
		-- assert wait request
		s_waitrequest <= '0';
		-- reset state
		current_state <= hit_check;
		flag_write <= '0';
		mem_read_ready <= '1';

	elsif m_waitrequest'event and m_waitrequest = '1' then
		-- To unset write signal in write_back state
		if flag_write = '1' then
			m_write <= '0';

		-- Retrieve data and count down the counter for read_mem state
		elsif mem_read_ready = '0' then
			m_read <= '0';
			cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).data(loop_counter) <= m_readdata;
			mem_read_ready <= '1';
				
			if loop_counter = 0 then
				-- reading complete, write tag
				cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).tag <= buf_s_addr(14 downto 9);
				-- set valid flag
				cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).valid <= '1';
				-- unset dirty flag
				cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).dirty <= '0';
				-- change state
				if s_read = '1' then
					current_state <= read_return;
				elsif s_write = '1' then
					current_state <= cache_write;
				end if;
			else
				loop_counter <= loop_counter - 1;
			end if;
		end if;
	end if;

	--------------------------------
	-- Actual state machine stuff --
	--------------------------------
	if clock'event and clock = '1' then
	
		case current_state is 
		when hit_check =>	-- default state
		
			if s_read = '1' or s_write = '1' then
				s_waitrequest <= '0';

				-- store address and data onto buffer, just to be safe
				buf_s_addr <= s_addr;
				buf_s_data <= s_writedata;
				
				-- addr_buf is used to access a block of memory. The least significant 4 bits are changed to access the next byte in each loop
				addr_buf(31 downto 4) <= s_addr(31 downto 4);
			
				-- compare tag and check valid bit
				if s_addr(14 downto 9) = cache_body(to_integer(unsigned(s_addr(8 downto 4)))).tag then
					if cache_body(to_integer(unsigned(s_addr(8 downto 4)))).valid = '1' then
						-- hit!
						if s_read = '1' then
							current_state <= read_return;	-- read & hit, return data

						elsif s_write = '1' then
							current_state <= cache_write;	-- write & hit

						end if;
						
					else
						-- same tag, invalid -> read from memory
						m_write <= '0';
						m_read <= '0';
						loop_counter <= 3;
						mem_read_ready <= '1';
						current_state <= read_mem;
						
					end if;
					
				else -- different tag
					if cache_body(to_integer(unsigned(s_addr(8 downto 4)))).valid = '1' and
					cache_body(to_integer(unsigned(s_addr(8 downto 4)))).dirty = '1'then
						-- if valid&dirty, writeback
						-- write the address of the line to write back into the buffer
						addr_buf(14 downto 9) <= cache_body(to_integer(unsigned(s_addr(8 downto 4)))).tag;
						m_write <= '0';
						m_read <= '0';
						loop_counter <= 3;
						flag_write <= '1';
						current_state <= write_back;
						
					else
						-- invalid, retrieve from memory
						m_write <= '0';
						m_read <= '0';
						loop_counter <= 3;
						mem_read_ready <= '1';
						current_state <= read_mem;
						
					end if;

				end if;
			end if;
			
		when write_back =>	-- dirty line -> write back
			-- count down if countdown flag is set
			if flag_write = '1' then
				if loop_counter = 0 then
					flag_write <= '0';
				else
					loop_counter <= loop_counter - 1;
				end if;
			end if;

			-- writing in progress & memory is not busy -> write one byte
			if flag_write = '1' and m_waitrequest = '1' then
				m_addr <= to_integer(unsigned(addr_buf(31 downto 0)));	-- m_addr takes a integer
				m_writedata <= cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).data(loop_counter);
				m_write <= '1';
				
			-- flag is unset -> transition to the next state
			elsif flag_write = '0' then
				m_write <= '0';
				-- reset stuff about looping
				loop_counter <= 3;
				-- write the correct address into othe address buffer
				addr_buf(14 downto 9) <= buf_s_addr(14 downto 9);
				-- transition to read_mem
				current_state <= read_mem;
			
			end if;
			
		when read_mem =>
			-- If the memory is ready to be accessed, read next byte
			if m_waitrequest = '1' and mem_read_ready = '1' then
				m_addr <= to_integer(unsigned(addr_buf(31 downto 0)));
				m_read <= '1';
				mem_read_ready <= '0';
			end if;
		
		when read_return =>
			-- put data on bus
			s_readdata <= cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).data(to_integer(unsigned(buf_s_addr(3 downto 2))));
		
			-- pull wait request high
			s_waitrequest <= '1';

			-- change state back to hit_check
			current_state <= hit_check;
			
		when cache_write =>
			-- write data into cache block
			cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).data(to_integer(unsigned(buf_s_addr(3 downto 2)))) <= buf_s_data;
			-- mark cache block as dirty
			cache_body(to_integer(unsigned(buf_s_addr(8 downto 4)))).dirty <= '1';
		
			-- pull wait request high
			s_waitrequest <= '1';
			
			-- change state back to hit_check
			current_state <= hit_check;
			
		end case;
	end if;
end process;
		
end arch;
