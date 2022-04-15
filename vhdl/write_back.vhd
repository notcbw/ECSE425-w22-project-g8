-- write back
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity write_back is
	port(	clk				: in std_logic;
			mem_to_reg		: in std_logic;
			reg_write_in	: in std_logic;
			write_reg_in	: in std_logic_vector(4 downto 0);
			read_data		: in std_logic_vector(31 downto 0);
			alu_result		: in std_logic_vector(31 downto 0);
			write_data		: out std_logic_vector(31 downto 0);
			write_reg_out	: out std_logic_vector(4 downto 0);
			reg_write_out	: out std_logic
			);
end write_back;

architecture rtl of write_back is

begin
	wb_process : process(clk)
	begin
		if clk'event and clk='1' then
			reg_write_out <= reg_write_in;
			write_reg_out <= write_reg_in;
			
			if mem_to_reg = '1' then
				write_data <= read_data;
			else
				write_data <= alu_result;
			end if;
		end if;
	end process;
end rtl;