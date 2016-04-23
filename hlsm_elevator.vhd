library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity hlsm_elevator is

port (clk, DrC: inout bit; rst: in bit; T, B : inout bit; Fo, Fc, MS, TMR: in bit; Up, Dn, Fl : in bit_vector (2 downto 0); LE, Q: inout bit_vector (2 downto 0));
end hlsm_elevator;

architecture beh of hlsm_elevator is 
	signal clk_half_period:time:=20ns;
	type statetype is (init, waitState, openState,close, Acc, Const, Dec, stop);
	signal currentstate, nextstate : statetype;
	
begin
	p1:process(clk)
	begin
		clk<=not(clk) after clk_half_period;
	end process p1;

 	statereg: process(clk, rst)
	begin
		if (rst='1') then
	currentstate <= init; -- initial state
		 elsif (rising_edge(clk)) then
		 currentstate <= nextstate;
		end if;
	end process statereg;

	comblogic: process(currentstate, T, B, Fo, Fc, DrC, MS, Up, Dn, Fl, TMR)
	begin

	case currentstate is
  	-- init
	when init =>
	Q <= "100";
	LE <= "000";
	T <= '0';
	B <= '0';
		nextstate <= waitState;

	-- waitState
	when waitState => 
	
	if (Fl'event) then
	Q <= Fl;
	elsif (Up'event) then
	Q <= Up;
	elsif (Dn'event) then
	Q <= Dn;
	else
	Q <= "100";
	end if;
	--if (Fl = "000" or Fl = "001" or Fl = "010" or Fl = "011") then
	--Q <= Fl; 
	--elsif (Up = "000" or Up = "001" or Up = "010" or Up = "011")
	--Q <= Up; 
	--elsif (Dn = "000" or Dn = "001" or Dn = "010" or Dn = "011")
	--Q <= Dn;
	--end if;
  	if (Q = LE) then
		nextstate <= openState;
	elsif (Q /= LE) and (Q /= "100") then
		nextstate <= Acc;
  	elsif (MS = '1') then
		nextstate <= waitState;
  	end if;
	
  	-- openState
	when openState =>
	Q <= "100";
  	if (TMR = '1' or Fc = '1') then
  		nextstate <= close;
  	elsif (MS = '1') then
  		nextstate <= openState;
	end if;
	
  	--close
	when close => 
	DrC <= '0';
  	if (Q = "100" or Q = "101" or Q = "110" or Q = "111") then
		nextstate <= waitState;
	elsif  (not(Q = LE)) then
		nextstate <= Acc;
	end if;

	-- Acc
	when Acc => 
		T <= '0';
		B <= '0';
		nextstate <= Const;
	 
  	--Const
	when Const => 
	if (Q > LE) then --go Up floors
		if(LE = "000")then LE <= "001";
			if (Q = LE) then T <= '1';
			end if;
		elsif(LE = "001") then LE <= "010";
			if (Q = LE) then T <= '1';
			end if;
		elsif(LE = "010") then LE <= "011";
			if (Q = LE) then T <= '1';
			end if;
		end if;
	elsif not(Q > LE) then -- go Dn floors
		if(LE = "011") then LE <= "010";
			if (Q = LE) then B <= '1';
			end if;
		elsif(LE = "010") then LE <= "001";
			if (Q = LE) then B <= '1';
			end if;
		elsif(LE = "001") then LE <= "000";
			if (Q = LE) then B <= '1';
			end if;
		end if;
	end if;

	if ((T = '1' or B = '1')) and (LE = Q) then
		nextstate <= Dec;
	else
  		nextstate <= Const;
 	end if;
  
	--Dec
	when Dec => 
	T <= '1';
	B <= '1';
	if (T = '1' and B = '1') then
		nextstate <= stop;
	end if;

	--stop
	when stop => 
		Q <= "100";
		nextstate <= openState;
  
 	end case;
  	end process comblogic;
  end beh;


	--tb
library ieee;
use ieee.std_logic_1164.all;
use work.all;

entity hlsm_elevator_tb is

end hlsm_elevator_tb;

architecture beh of hlsm_elevator_tb is

component c1

port (clk, DrC : inout bit; rst: in bit; T, B: inout bit; Fo, Fc, MS, TMR: in bit; Up, Dn, Fl: in bit_vector (2 downto 0); LE: inout bit_vector (2 downto 0));

end component;

signal ct : bit;
signal DrCt: bit;
signal rt: bit;
signal Tt: bit;
signal Bt: bit;
signal Fot: bit;
signal Fct: bit;
signal MSt: bit;
signal TMRt: bit;
signal LEt: bit_vector (2 downto 0);
signal Upt: bit_vector (2 downto 0);
signal Flt: bit_vector (2 downto 0);
signal Dnt: bit_vector (2 downto 0);

for all: c1 use entity work.hlsm_elevator(beh);

begin
g1: c1 port map(ct, DrCt, rt, Tt, Bt, Fot, Fct, MSt, TMRt, Upt, Dnt, Flt, LEt);
	
	
	rt <= '0', '1' after 3000ns;
	--Tt <= '0';
	--Bt <= '0';
	Fot <= '0';
	Fct <= '0';
	MSt <= '0';
	--TMRt <= '0';
	Flt <= "100", "011" after 85ns, "000" after 100ns, "011" after 500ns;
	Upt <= "100";
	Dnt <= "100";

end beh;