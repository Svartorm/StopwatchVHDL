library ieee;
use ieee.std_logic_1164.all;

  entity MyCounter
    port(
	  Clk       : in  std_logic;
      nReset   : in  std_logic;
	  KeyZero 		 : in std_logic;
	  KeyOne 		 : in std_logic;
      Running		 : out 	std_logic;
	  VGA 			 : out 	std_logic_vector(2 downto 0);
	  Bar 			 : out 	std_logic_vector(2 downto 0); 
	  );  
  end entity MyCounter ;

----------------------------

  architecture RTL of MyCounter is
type state_t is (Stop, Pause, Run); 
signal State : state_t;

begin

 process(Clk, nReset) 
 begin
 	if Reset_n = '0' then
      State <= Stop;
    elsif rising_edge(Clk) then
	
	case State is
			when Run =>								--1
				Running <= '1' ;
				VGA <= "000" ; -- green
				Bar <= "001" ; -- active
				if KeyOne <= '1' then
					State <= Pause;
				end if;
			
			when Stop => 							--2
				Running <= '0' ;
				VGA <= "001" ; -- blue
				Bar <= "000" ; -- absent
				if KeyOne <= '1' then
					State <= Run;
				end if;
			
			when Pause => 							--3
				Running <= '0' ;
				VGA <= "010" ; -- red
				Bar <= "010" ; -- stoped
				if KeyZero <= '1' then
					State <= Stop;
				end if;
				if KeyOne <= '1' then
					State <= Run;
				end if;
			
		end case;
	end if;
end process;

end architecture;

