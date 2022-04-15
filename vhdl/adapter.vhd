-- for the cache
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adapter is
    port(
        addr_vec: out std_logic_vector(31 downto 0);
        addr_int: in integer
        );
    end entity;

architecture rtl of adapter is
begin
    addr_vec <= std_logic_vector(to_unsigned(addr_int, 32));
end architecture;
