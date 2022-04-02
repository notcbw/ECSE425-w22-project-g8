-- register file
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file is
	port(	clk: in std_logic;
			a1: in std_logic_vector(4 downto 0);
			a2: in std_logic_vector(4 downto 0);
			aw: in std_logic_vector(4 downto 0);	-- addr to write data into register
			dw: in std_logic_vector(31 downto 0);	-- write data
			we: in std_logic;						-- write enable
			rd1: out std_logic_vector(31 downto 0);
			rd2: out std_logic_vector(31 downto 0)
			);
end register_file;

architecture rtl of register_file is 
-- define register file structure
	type reg_file is array (31 downto 0) of std_logic_vector(31 downto 0);
	signal reg: reg_file := (others => (others => '0'));	-- register file signal, set all registers to 0
	
begin
	rd1 <= reg(to_integer(unsigned(a1)));
	rd2 <= reg(to_integer(unsigned(a2)));
	
	process(clk)
	begin
		if clk'event and clk='1' then
			-- at rising edge, if write enabled, writeback to the register
			-- TBD: test if it writes in time. Might need to make it asynchronous.
			if we = '1' then
				if aw /= "00000" then		-- do not change R0
					reg(to_integer(unsigned(aw))) <= dw;
				end if;
			end if;
		end if;
	end process;
	
end rtl;