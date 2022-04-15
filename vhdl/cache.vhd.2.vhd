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
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is
	TYPE CAC IS ARRAY(31 downto 0) OF STD_LOGIC_VECTOR(135 DOWNTO 0);
	SIGNAL direct_map_cache: CAC;
-- declare signals here
--VND means Valid and not dirty, VD means Valid but dirty
type State is (IDLE, VND, VD);

begin

-- make circuits here
process (clock, reset)
--variables declarations
variable idx	: integer range 0 to 31;	--block index
variable tag	: std_logic_vector (5 downto 0);
variable data	: std_logic_vector (127 downto 0);
variable dirty  : std_logic := '0';
variable valid	: std_logic;
variable addr	: integer range 0 to ram_size-1 := TO_INTEGER(unsigned(s_addr));
variable word   : integer range 0 to 3;	--word offset
variable byte_n : integer range 0 to 31 := 0; --byte offset
variable byte_n2: integer range 0 to 31 := 0; --byte offset
variable mr		: std_logic := '0';
variable mw		: std_logic := '0';
variable wreq   : std_logic := '1';
variable S		: State;
--begin process
begin
	if falling_edge (reset) then
    	S := IDLE;
        for i in 0 to 31 loop
        	direct_map_cache(i) (135) <= '0'; --clear all valid bit
        end loop;
        s_waitrequest <= '1';
    elsif rising_edge (clock) then
      idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
    if direct_map_cache(idx) (135) = '0' then
    	S := IDLE;
    elsif direct_map_cache(idx) (134) = '0' then
    	S := VND;
    else 
    	S := VD;
    end if;
    if wreq = '0' then
    	wreq := '1';
        s_waitrequest <= '1';
    else case S is 
        	--if the state is IDLE
        	When IDLE =>
            	--input: both s_read and s_write set
            	if s_read = '1' and s_write = '1' then
                	S := S;--State keeps at IDLE
                --input: s_read set
                elsif s_read = '1' then
                	--bring block from memory to cache
                	m_read <= '1';
                    s_waitrequest <= '1';
                    addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    tag := s_addr (14 downto 9);
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                    m_addr <= addr + byte_n;
                    if m_waitrequest = '0' then
                    	data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    	if byte_n /= 15 then
                        	byte_n := byte_n +1;
                            m_read <= '0';
						else
                        	byte_n := 0;
                    		m_read <= '0';
                    		valid := '1';
             		       	dirty := '0';
                    		word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    		direct_map_cache(idx) (135) <= valid;
                  		  	direct_map_cache(idx) (134) <= dirty;
                    		direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    		direct_map_cache(idx) (127 downto 0) <= data;
                    		--core reads data outof cache
                    		s_waitrequest <= '0';
                            wreq  := '0';
                    		s_readdata <= data(31+32*word downto 32*word);
                    		S := VND; --update state to VND   
                        end if;
                    end if;
                --input: s_write set
                elsif s_write = '1' then
                	--bring block from memory to cache
                	m_read <= '1';
                    s_waitrequest <= '1';
                    addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    tag := s_addr (14 downto 9);
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                    m_addr <= addr + byte_n;
                    if m_waitrequest = '0' then
                    	data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    	if byte_n /= 15 then
                        	byte_n := byte_n +1;
                            m_read <= '0';
						else
                        	byte_n := 0;
                    		m_read <= '0';
                    		valid := '1';
             		       	dirty := '1';
                    		word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    		direct_map_cache(idx) (135) <= valid;
                  		  	direct_map_cache(idx) (134) <= dirty;
                    		direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    		direct_map_cache(idx) (127 downto 0) <= data;
                    		--core writes to cache
                    		direct_map_cache(idx) (31+32*word downto 32*word) <= s_writedata;
                    		s_waitrequest <= '0';
                            wreq  := '0';
                    		S := VD; --update state to VD
                        end if;
                    end if;
  			    else --for other cases, just contine;
                	S := S;
                end if;
            -- if state is VND
            when VND =>
            	--temperarily store new block idx and tag
            	idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
            	tag := direct_map_cache(idx) (133 downto 128);
                --input: s_read set and tag matched
                if s_read = '1' and tag = s_addr (14 downto 9) then
                	--core reads data outof cache
					s_waitrequest <= '0';
                    wreq  := '0';
                    word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                	s_readdata <= direct_map_cache(idx) (31+32*word downto 32*word);
                --input: s_write set and tag matched
                elsif s_write = '1' and tag = s_addr (14 downto 9) then
                	--core writes data to cache
                	s_waitrequest <= '0';
                    wreq  := '0';
                    word := TO_INTEGER(unsigned(s_addr (3 downto 2)));
                    direct_map_cache(idx) (31+32*word downto 32*word) <= s_writedata;
                    dirty := '1';
                    direct_map_cache(idx) (134) <= dirty;
                    S := VD; --update state to VD
                --input: s_read set but tag mismatched   
           		elsif s_read = '1' and tag /= s_addr (14 downto 9) then
                	--bring block from memory to cache
                	m_read <= '1';
                    s_waitrequest <= '1';
                    addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    tag := s_addr (14 downto 9);
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                    m_addr <= addr + byte_n;
                    if m_waitrequest = '0' then
                    	data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    	if byte_n /= 15 then
                        	byte_n := byte_n +1;
                            m_read <= '0';
						else
                        	byte_n := 0;
                    		m_read <= '0';
                    		valid := '1';
             		       	dirty := '0';
                    		word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    		direct_map_cache(idx) (135) <= valid;
                  		  	direct_map_cache(idx) (134) <= dirty;
                    		direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    		direct_map_cache(idx) (127 downto 0) <= data;
                    		--core reads data outof cache
                    		s_waitrequest <= '0';
                            wreq  := '0';
                    		s_readdata <= data(31+32*word downto 32*word);
                        end if;
                    end if;
                --input: s_write set but tag mismatched
                elsif s_write = '1' and tag /= s_addr (14 downto 9) then
                	--bring block from memory to cache
                	m_read <= '1';
                    s_waitrequest <= '1';
                    addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    tag := s_addr (14 downto 9);
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                    m_addr <= addr + byte_n;
                    if m_waitrequest = '0' then
                    	data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    	if byte_n /= 15 then
                        	byte_n := byte_n +1;
                            m_read <= '0';
						else
                        	byte_n := 0;
                    		m_read <= '0';
                    		valid := '1';
             		       	dirty := '1';
                    		word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    		direct_map_cache(idx) (135) <= valid;
                  		  	direct_map_cache(idx) (134) <= dirty;
                    		direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    		direct_map_cache(idx) (127 downto 0) <= data;
                    		--core writes to cache
                    		direct_map_cache(idx) (31+32*word downto 32*word) <= s_writedata;
                    		s_waitrequest <= '0';
                            wreq  := '0';
                    		S := VD; --update state to VD
                        end if;
                    end if;
                --input: both s_read and s_write not set
                elsif s_read = '0' and s_write = '0' then
                	--rise s_waitrequest
                	s_waitrequest <= '1';
                else --for other cases, just continue
                	S := S;
                end if;
            --if state is VD
            when VD =>
            	--temperarily store new block idx and tag
            	idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
            	tag := direct_map_cache(idx) (133 downto 128);
                word:= TO_INTEGER(unsigned(s_addr(3 downto 2)));
                --input: s_read set and tag matched
                if s_read = '1' and tag = s_addr (14 downto 9) then
                	--core reads data outof cache
					s_waitrequest <= '0';
                    wreq  := '0';
                	s_readdata <= direct_map_cache(idx) (31+32*word downto 32*word);
                --input: s_write set and tag matched
                elsif s_write = '1' and tag = s_addr (14 downto 9) then
                	--core writes data to cache
                	s_waitrequest <= '0';
                    wreq  := '0';
                    direct_map_cache(idx) (31+32*word downto 32*word) <= s_writedata;
                --input: s_read set and tag mismatched
           		elsif s_read = '1' and tag /= s_addr (14 downto 9) then
                	--write data back to memory
                    s_waitrequest <= '1';
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
					tag := direct_map_cache(idx) (133 downto 128);
                    addr := TO_INTEGER(unsigned(std_logic_vector'(tag & std_logic_vector(TO_UNSIGNED(idx, 5)))))*16;
                	if mr /= '1' then 
                    	mw := '1';
                    	m_write <= mw;
                    	m_addr <= addr + byte_n2;
                    	m_writedata <= direct_map_cache(idx) (7+8*byte_n2 downto 8*byte_n2);
                    end if;
                    if m_waitrequest = '0' and byte_n2 /= 15 then
                    	byte_n2 := byte_n2 +1;
                        mw := '0';
                        m_write <= mw;
					elsif m_waitrequest = '0' and byte_n2 = 15 then
                      	--bring block form memory to cache
                        mr := '1';
                    	m_read <= mr;
                    	s_waitrequest <= '1';
                    	addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    	tag := s_addr (14 downto 9);
                    	idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                      	m_addr <= addr + byte_n;
                        if m_waitrequest = '0' and mw /= '1' then
                    		data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    		if byte_n /= 15 then
                        		byte_n := byte_n +1;
                                mr := '0';
                                m_read <= mr;
							else
                        		byte_n := 0;
                                byte_n2:= 0;
                              	mr := '0';
                                m_read <= mr;
                    			valid := '1';
             		       		dirty := '0';
                    			word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    			direct_map_cache(idx) (135) <= valid;
                  		  		direct_map_cache(idx) (134) <= dirty;
                    			direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    			direct_map_cache(idx) (127 downto 0) <= data;
                    			--core reads data outof cache
                    			s_waitrequest <= '0';
                                wreq  := '0';
                    			s_readdata <= data(31+32*word downto 32*word);
                    			S := VND; --update state to VND   
                        	end if;
                        else
                        	mw := '0';
                        	m_write <= mw;
                    	end if;
                    end if;
				--input: s_write set and tag mismatched
                elsif s_write = '1' and tag /= s_addr (14 downto 9) then
                	--write data back to memory
                	s_waitrequest <= '1';
                    idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
					tag := direct_map_cache(idx) (133 downto 128);
                    addr := TO_INTEGER(unsigned(std_logic_vector'(tag & std_logic_vector(TO_UNSIGNED(idx, 5)))))*16;
                	if mr /= '1' then 
                    	mw := '1';
                    	m_write <= mw;
                    	m_addr <= addr + byte_n2;
                    	m_writedata <= direct_map_cache(idx) (7+8*byte_n2 downto 8*byte_n2);
                    end if;
                    if m_waitrequest = '0' and byte_n2 /= 15 then
                    	byte_n2 := byte_n2 +1;
                        mw := '0';
                        m_write <= mw;
					elsif m_waitrequest = '0' and byte_n2 = 15 then
                    	--bring block form memory to cache
                    	mr := '1';
                    	m_read <= mr;
                    	s_waitrequest <= '1';
                    	addr := TO_INTEGER(unsigned(s_addr (31 downto 4)))*16;
                    	tag := s_addr (14 downto 9);
                    	idx := TO_INTEGER(unsigned(s_addr (8 downto 4)));
                    	m_addr <= addr + byte_n;
                    	if m_waitrequest = '0' and mw /= '1' then
                    		data (7+8*byte_n downto 8*byte_n) := m_readdata;
                    		if byte_n /= 15 then
                              byte_n := byte_n +1;
                              mr := '0';
                              m_read <= mr;
							else
                        		byte_n := 0;
                                byte_n2:= 0;
                    			mr := '0';
                                m_read <= mr;
                    			valid := '1';
             		       		dirty := '1';
                    			word  := TO_INTEGER(unsigned(s_addr(3 downto 2)));
                    			direct_map_cache(idx) (135) <= valid;
                              	direct_map_cache(idx) (134) <= dirty;
                    			direct_map_cache(idx) (133 downto 128) <= tag; --match tag
                    			direct_map_cache(idx) (127 downto 0) <= data;
                    			--core writes to cache
                    			direct_map_cache(idx) (31+32*word downto 32*word) <= s_writedata;
                    			s_waitrequest <= '0';
                                wreq  := '0';
                        	end if;
                        else
                        	mw := '0';
                        	m_write <= mw;
                    	end if; 
                    end if;
                --input: both s_read and s_write not set
                elsif s_read = '0' and s_write = '0' then
                	--rise s_waitrequest
                	s_waitrequest <= '1';
                --for other cases, just continue
                else
                	S := S;
                end if;   
          end case;
    end if;
    --for other cases, just continue
    else 
    	S := S;
    end if; 
end process;
end arch;