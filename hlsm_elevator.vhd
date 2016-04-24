library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;


entity hlsm_elevator is

port (clk, DrC: inout bit; rst: in bit; T, B: inout bit; Fo, Fc, MS, TMR: in bit; Up, Dn, Fl : in bit_vector (2 downto 0); LE, Q: inout bit_vector (2 downto 0); Fstart, Fstop: in bit);
end hlsm_elevator;

architecture beh of hlsm_elevator is 
	signal clk_half_period:time:=5 ns;
	type statetype is (init, waitState, openState,close, Acc, Const, Dec, Stop);
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

	comblogic: process(currentstate, T, B, Fo, Fc, DrC, MS, Up, Dn, Fl, TMR, Fstart, Fstop)
	
	begin

	case currentstate is

  	-- init
	when init =>
	Q <= "100";
	LE <= "000";
	T <= '0';
	B <= '0';
	DrC <= '0';
	nextstate <= waitState;

	-- wait
	when waitState => 
	
	if (Fl'event and Fl /= "100") then
		Q <= Fl;
	elsif (Up'event and up /= "100") then
		Q <= Up;
	elsif (Dn'event and Dn /= "100") then
		Q <= Dn;
	else
		--Q <= "100";
	end if;


  	if (Q = LE) then
		nextstate <= openState;
	elsif (Q /= LE) and (Q /= "100") then
		nextstate <= Acc;
  	elsif (MS = '1') then
		nextstate <= waitState;
  	end if;
	
  	-- open
	when openState =>
 	Q <= "100";
	T <= '0';
	B <= '0';
	DrC <= '1';
	
	--Fstop <= '0';
	--Fstart <= '0';
  	if (Fc = '1') then
  		nextstate <= close;
  	elsif (MS = '1' or Fo = '1') then
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
		if(Fstop = '1') then
			nextstate <= Dec;
		else
			nextstate <= Const;
	 	end if;

  	--const
	when Const => 

		if (Q > LE) then -- go Up
			if(LE = "000") then LE <= "001";
				if(Q = "001") then T <= '1'; end if;			
			elsif(LE = "001") then LE <= "010";
				if(Q = "010") then T <= '1'; end if;
			elsif(LE = "010") then LE <= "011";
				if(Q = "011") then T <= '1'; end if;
			end if;
		elsif (Q < LE) then  --go Dn
			if(LE = "011") then LE <= "010";
				if(Q = "010") then B <= '1'; end if;
			elsif(LE = "010") then LE <= "001";
				if(Q = "001") then B <= '1'; end if;
			elsif(LE = "001") then LE <= "000";
				if(Q = "000") then B <= '1'; end if;
			end if;
		end if;

	
	

	if ((T = '1' or B = '1')) and (LE = Q) then
		nextstate <= Dec;
	else
  		nextstate <= Const;
 	end if;
  
	--Dec
	when Dec => 
	T <= '1'; B <= '1';
	if (T = '1' and B = '1') then
		nextstate <= Stop;
	end if;

	--stop
	when Stop => 
		if (Fstart = '1') then
			--Fstop = '0';
			nextstate <= Acc;
		end if;
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

port (clk, DrC : inout bit; rst: in bit; T, B : inout bit; Fo, Fc, MS, TMR: in bit; Up, Dn, Fl: in bit_vector (2 downto 0); LE: inout bit_vector (2 downto 0);Fstart, Fstop: in bit);

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
signal Fstartt, Fstopt: bit;


for all: c1 use entity work.hlsm_elevator(beh);

begin
g1: c1 port map(ct, DrCt, rt, Tt, Bt, Fot, Fct, MSt, TMRt, Upt, Dnt, Flt, LEt, Fstartt, Fstopt);
	--------------------Basic Elevator----------------------------------------------
--	rt <= '0', '1' after 5000 ns;
--	Fot <= '0', '1' after 4500 ns, '0' after 4750 ns;
--	Fct <= '0', '1' after 4700 ns;
--	Fstartt <= '0';
--	Fstopt <= '0';
--	MSt <= '0';
--	TMRt <= '0', '1' after 100 ns, '0' after 125 ns,'1' after 150 ns, '0' after 250 ns, '1' after 300 ns, '0' after 350 ns, '1' after 400 ns, '0' after 415 ns,'0' after 550 ns,'1' after 600 ns,'0' after 650 ns,'1' after 700 ns;
--	Upt <= "100", "011" after 60 ns, "100" after 80 ns,"010" after 530 ns;
--	Flt <= "100", "010" after 225 ns, "100" after 245 ns;
--	Dnt <= "100", "000" after 325 ns, "100" after 345 ns;

------------------------------ Force open and close Test--------------------------------------------
	Fot <= '0', '1' after 4500 ns, '0' after 4750 ns;
	Fct <= '0', '1' after 4700 ns;
	Fstartt <= '0';
	Fstopt <= '0';
	MSt <= '0';
	TMRt <= '0', '1' after 100 ns, '0' after 125 ns,'1' after 150 ns, '0' after 250 ns, '1' after 300 ns, '0' after 350 ns, '1' after 400 ns, '0' after 415 ns,'0' after 550 ns,'1' after 600 ns,'0' after 650 ns,'1' after 700 ns;
	Upt <= "100", "011" after 60 ns, "100" after 80 ns,"010" after 530 ns;
	Flt <= "100", "010" after 225 ns, "100" after 245 ns;
	Dnt <= "100", "000" after 325 ns, "100" after 345 ns;
------------------------------ Force Start and Stop Test--------------------------------------------
	Fot <= '0', '1' after 4500 ns, '0' after 4750 ns;
	Fct <= '0', '1' after 4700 ns;
	Fstartt <= '0';
	Fstopt <= '0';
	MSt <= '0';
	TMRt <= '0', '1' after 100 ns, '0' after 125 ns,'1' after 150 ns, '0' after 250 ns, '1' after 300 ns, '0' after 350 ns, '1' after 400 ns, '0' after 415 ns,'0' after 550 ns,'1' after 600 ns,'0' after 650 ns,'1' after 700 ns;
	Upt <= "100", "011" after 60 ns, "100" after 80 ns,"010" after 530 ns;
	Flt <= "100", "010" after 225 ns, "100" after 245 ns;
	Dnt <= "100", "000" after 325 ns, "100" after 345 ns;

end beh;