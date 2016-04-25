library ieee;
use ieee.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;


entity hlsm_elevator is

port (	clk, DrC: inout bit; 
	rst: in bit; T, B: inout bit; 
	Fo, Fc, MS : in bit; TMR : inout bit; 
	Up, Dn, Fl : in bit_vector (2 downto 0); 
	LE, Q: inout bit_vector (2 downto 0); 
	Fstart, Fstop: inout bit;
	Elv1, Elv2 : inout bit_vector (2 downto 0);
	ElvSelected : inout bit;
	push, pull: inout bit;
	din, dout: inout bit_vector (2 downto 0)
	);
end hlsm_elevator;

architecture beh of hlsm_elevator is 
	signal clk_half_period:time:=5 ns;
	type statetype is (init, waitState, openState,close, Acc, Const, Dec, Stop);
	signal currentstate, nextstate : statetype;
	
	type mem is array (0 to 3) of bit_vector (2 downto 0); --first define the type of array.

	signal queue : mem := (others=>(others=>'0')); --queue is a 4 element array of bit_vector (2 downto 0) others: fill array with '0'

	--type mem is array (0 to 5) of bit_vector (2 downto 0);

--	signal queue : mem := (others=>(others=>'0'));

	
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


	
	queue_design : process (clk,push,pull,din)
	  
	variable mem : bit_vector (2 downto 0) ;
    	variable i : integer := 0;
	    begin                   
	        if (rising_edge (clk)) then
	            if (push='1') then
	                queue(i) <= din;  
	                if (i<3) then
	                    i := i + 1;       
	                end if;
	            elsif (pull='1') then   
	                dout <= queue(0); 
	                if (i>0) then
	                    i := i - 1;
	                end if;
	                queue(0 to 2) <= queue(1 to 3);
	            end if;
	        end if;
	    end process queue_design;

	
	comblogic: process(currentstate, T, B, Fo, Fc, DrC, MS, Up, Dn, Fl, TMR, Fstart, Fstop)
	
	variable IQ : integer := 0;
	variable IElv1 : integer := 0;
	variable IElv2 : integer := 0;
	variable queueIndex : integer := 0;

	begin
	

	case currentstate is
  	-- init
	when init =>
	Q <= "100";
	LE <= "000";
	T <= '0';
	B <= '0';
	DrC <= '0';
	Elv1 <= "000";
	Elv2 <= "000";
	push <= '0';
	pull <= '0';
	queue(0) <= "100";
	queue(1) <= "100";
	queue(2) <= "100";
	queue(3) <= "100";
	nextstate <= waitState;

	-- wait
	when waitState => 
	
	if (Fl'event and Fl /= "100") then
		Q <= Fl;
		din <= Fl;
		push <= '1';
--		if (queue(queueIndex) = "100") then
--			queue(queueIndex) <= Fl;
--			queueIndex := queueIndex + 1;
--		end if;
	end if;

	if (Up'event and up /= "100") then
		Q <= Up;
		din <= Up;
		push <= '1';
--		if (queue(0) = "100") then
--			queue(0) <= Fl;
--			queueIndex := queueIndex + 1;
--		end if;
	end if;
	if (Dn'event and Dn /= "100") then
		Q <= Dn;
		din <= Dn;
		push <= '1';
--		if (queue(queueIndex) = "100") then
--			queue(queueIndex) <= Fl;
--			queueIndex := queueIndex + 1;
--		end if;
	end if;
	
	if(Q = "000") then IQ := 0; end if;
	if(Q = "001") then IQ := 1; end if;
	if(Q = "010") then IQ := 2; end if;
	if(Q = "011") then IQ := 3; end if;

	if(Elv1 = "000") then IElv1 := 0; end if;
	if(Elv1 = "001") then IElv1 := 1; end if;
	if(Elv1 = "010") then IElv1 := 2; end if;
	if(Elv1 = "011") then IElv1 := 3; end if;

	if(Elv2 = "000") then IElv2 := 0; end if;
	if(Elv2 = "001") then IElv2 := 1; end if;
	if(Elv2 = "010") then IElv2 := 2; end if;
	if(Elv2 = "011") then IElv2 := 3; end if;

	if abs(IQ - IElv1) > abs(IQ - IElv2) then
		ElvSelected <= '1';
		nextstate <= Acc;
	elsif abs(IQ - IElv1)< abs(IQ - IElv2) then
		ElvSelected <= '0';
		nextstate <= Acc;
	end if;
		
  	if (Q = Elv1) then
		ElvSelected <= '0';
		nextstate <= openState;
	elsif (Q = Elv2) then
		ElvSelected <= '1';
		nextstate <= openState;
	elsif (Q /= Elv1 or Q/= Elv2) and (Q /= "100") then
		nextstate <= Acc;
  	elsif (MS = '1') then
		nextstate <= openState;
  	end if;
	
  	-- open
	when openState =>
	pull <= '1';
 	Q <= "100";
	T <= '0';
	B <= '0';
	DrC <= '1';
	push <= '0';
	TMR <= '1' after 25 ns;
	
	--Fstop <= '0';
	--Fstart <= '0';
  	if (MS = '1' or Fo = '1') then
  		nextstate <= openState;
  	elsif (TMR = '1' or Fc = '1') then
  		nextstate <= close;
	end if;
	
  	--close
	when close => 
	TMR <= '0';
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
	if (ElvSelected = '0') then
		if (Q > Elv1) then -- go Up
			if(Elv1 = "000") then Elv1 <= "001";
				if(Q = "001") then T <= '1'; end if;			
			elsif(Elv1 = "001") then Elv1 <= "010";
				if(Q = "010") then T <= '1'; end if;
			elsif(Elv1 = "010") then Elv1 <= "011";
				if(Q = "011") then T <= '1'; end if;
			end if;
		elsif (Q < Elv1) then  --go Dn
			if(Elv1 = "011") then Elv1 <= "010";
				if(Q = "010") then B <= '1'; end if;
			elsif(Elv1 = "010") then Elv1 <= "001";
				if(Q = "001") then B <= '1'; end if;
			elsif(Elv1 = "001") then Elv1 <= "000";
				if(Q = "000") then B <= '1'; end if;
			end if;
		end if;
			if ((T = '1' or B = '1')) and (Elv1 = Q) then
			nextstate <= Dec;
			else
  			nextstate <= Const;
 			end if;
	end if;
	
	if (ElvSelected = '1') then
		if (Q > Elv2) then -- go Up
			if(Elv2 = "000") then Elv2 <= "001";
				if(Q = "001") then T <= '1'; end if;			
			elsif(Elv2 = "001") then Elv2 <= "010";
				if(Q = "010") then T <= '1'; end if;
			elsif(Elv2 = "010") then Elv2 <= "011";
				if(Q = "011") then T <= '1'; end if;
			end if;
		elsif (Q < Elv2) then  --go Dn
			if(Elv2 = "011") then Elv2 <= "010";
				if(Q = "010") then B <= '1'; end if;
			elsif(Elv2 = "010") then Elv2 <= "001";
				if(Q = "001") then B <= '1'; end if;
			elsif(Elv2 = "001") then Elv2 <= "000";
				if(Q = "000") then B <= '1'; end if;
			end if;
		end if;
		if ((T = '1' or B = '1')) and (Elv1 = Q) then
			nextstate <= Dec;
		else
  			nextstate <= Const;
 		end if;
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
--ibrary ieee;
--use ieee.std_logic_1164.all;
use work.all;

entity hlsm_elevator_tb is

end hlsm_elevator_tb;

architecture beh of hlsm_elevator_tb is

component c1

port (clk, DrC : inout bit; 
	rst: in bit; T, B : inout bit; 
	Fo, Fc, MS : in bit; 
	TMR: inout bit; Up, Dn, Fl: in bit_vector (2 downto 0); 
	LE: inout bit_vector (2 downto 0); 
	Fstart, Fstop: inout bit;
	push, pull: inout bit;
	din, dout: inout bit_vector (2 downto 0)
);

end component;

--component queue
--port(
--         clk : in bit;
--         push : in bit;
--         pull : in bit;
--         din : in bit_vector (2 downto 0);
--         dout : out bit_vector(2 downto 0)
--         );
--end component;

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
--signal Trigger : bit;

------------queue signals----------------------
	signal pusht, pullt: bit; 
	signal dint,doutt: bit_vector(2 downto 0);

for all: c1 use entity work.hlsm_elevator(beh);
--for all: queue use entity work.queue_8nibble(queue_8nibble_arc);

begin
g1: c1 port map(ct, DrCt, rt, Tt, Bt, Fot, Fct, MSt, TMRt, Upt, Dnt, Flt, LEt, Fstartt, Fstopt);
	
	rt <= '0', '1' after 5000 ns;
	Fot <= '0', '1' after 4500 ns, '0' after 4750 ns;
	Fct <= '0', '1' after 4700 ns;
	--Fstartt <= '0';
	--Fstopt <= '0';
	MSt <= '0';
	--TMRt <= '0', '1' after 100ns, '0' after 125ns,'1' after 150ns, '0' after 250ns, '1' after 300ns, '0' after 350ns, '1' after 400ns, '0' after 415ns,'0' after 550ns,'1' after 600ns,'0' after 650ns,'1' after 700ns;
	Upt <= "100", "011" after 60 ns, "100" after 80 ns,"010" after 530 ns;
	Flt <= "100", "010" after 225 ns, "100" after 245 ns;
	Dnt <= "100", "000" after 325 ns, "100" after 345 ns;

	--Trigger <=  '0', '1' after 200ns, '0' after 250ns, '1' after 300ns, '0' after 350ns, '1' after 400ns, '0' after 450ns,'1' after 500ns;
	
--qu: queue port map (ct, pusht, pullt,dint,doutt);
	--dint <= "010" after 60 ns;
	--pusht <= '1' after 60 ns;

end beh;

--use work.all;
--entity queue_8nibble is
--     port(
--         clk : in bit;
--         push : in bit;
--         pull : in bit;
--         din : in bit_vector (2 downto 0);
--         dout : out bit_vector(2 downto 0)
--         );
--end queue_8nibble;
--
--
--architecture queue_8nibble_arc of queue_8nibble is
--
--type mem is array (0 to 5) of bit_vector (2 downto 0);
--
--signal queue : mem := (others=>(others=>'0'));
--
--begin

--    queue_design : process (clk,push,pull,din) is   
--    variable mem : bit_vector (2 downto 0) ;
--    variable i : integer := 0;
--    begin                   
--        if (rising_edge (clk)) then
--            if (push='1') then
--                queue(i) <= din;  
--                if (i<5) then
--                    i := i + 1;       
--                end if;
--            elsif (pull='1') then   
--                dout <= queue(0); 
--                if (i>0) then
--                    i := i - 1;
--                end if;
--                queue(0 to 4) <= queue(1 to 5);
--            end if;
--        end if;
--    end process queue_design;
   

--end queue_8nibble_arc;
