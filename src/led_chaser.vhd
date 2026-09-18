library ieee;
use ieee.std_logic_1164.all;

entity led_chaser is

    generic(
        MAX_COUNT : integer := 6_249_999
    );

    port(
        Clk       : in  std_logic;
        nReset    : in  std_logic;
        Running   : in  std_logic;
        LoadTimer : in  std_logic;  

        Chaser    : out std_logic_vector(7 downto 0)
    );

end entity led_chaser;


architecture RTL of led_chaser is

    -- Compteur pour 125 ms
    signal Count : integer range 0 to MAX_COUNT := 0;

    -- Position de la LED
    signal Pattern : std_logic_vector(7 downto 0) := "00000001";

begin

    process(Clk, nReset)
    begin

        if nReset = '0' then

            Count   <= 0;
            Pattern <= "00000001";

        elsif rising_edge(Clk) then

            -- STOP
            if LoadTimer = '1' then

                Count   <= 0;
                Pattern <= "00000001";


            -- RUN
            elsif Running = '1' then

                if Count = MAX_COUNT then

                    Count <= 0;

                    if Pattern = "10000000" then
                        Pattern <= "00000001";
                    else
                        Pattern <= Pattern(6 downto 0) & '0';
                    end if;

                else

                    Count <= Count + 1;

                end if;


            -- PAUSE
            else

                Count <= Count;

            end if;

        end if;

    end process;


    -- Sortie du chenillard
    Chaser <= Pattern;

end architecture RTL;