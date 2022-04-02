-- forwarding logic of decode stage
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fwd_decode is
	port(	rd1_in: in std_logic_vector(31 downto 0);
			rd2_in: in std_logic_vector(31 downto 0);
			fwd_in: in std_logic_vector(31 downto 0);
			fwd1: in std_logic;
			fwd2: in std_logic;
			eq: out std_logic;
			rd1_out: out std_logic_vector(31 downto 0);
			rd2_out: out std_logic_vector(31 downto 0)
			);
end fwd_decode;

architecture rtl of fwd_decode is
begin
	-- signal whether tro outputs are equal, used for branching. Requires VHDL-2008 support
	eq <= and (rd1_out xnor rd2_out);
	
	-- mux to select fd1 between the forwarded value and the value from the control unit
	with fwd1 select
	rd1_out <=	fwd_in when '1',
			rd1_in when others;
	
	-- mux to select fd2 between the forwarded value and the value from the control unit
	with fwd2 select
	rd2_out <=	fwd_in when '1',
			rd2_in when others;
	
end rtl;