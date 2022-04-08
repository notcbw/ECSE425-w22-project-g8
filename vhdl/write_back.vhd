-- write back
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
	port(	clk	: in std_logic;
			mem_to_reg	: in std_logic;
			read_data	: in std_logic_vector(31 downto 0);
			alu_result	: in std_logic_vector(31 downto 0);
			write_data	: out std_logic_vector(31 downto 0));
end write_back;

architecture arch of write_back is

begin
	wb_process : process(clk)
	begin
		if clk'event and clk='1' then
			if mem_to_reg = '1' then
				write_data <= read_data;
			else
				write_data <= alu_result;
			end if;
		end if;
	end process;
end arch;