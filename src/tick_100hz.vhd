library ieee;
use ieee.std_logic_1164.all;

entity tick_100hz is
    generic(
        MAX_COUNT : integer := 499_999
    );
    port(
        Clk      : in  std_logic;
        nReset   : in  std_logic;
        Tick100  : out std_logic
    );
end entity tick_100hz;

architecture RTL of tick_100hz is

    signal Count : integer range 0 to MAX_COUNT := 0;

begin

    process(Clk, nReset)
    begin

        if nReset = '0' then

            Count   <= 0;
            Tick100 <= '0';

        elsif rising_edge(Clk) then

            if Count = MAX_COUNT then

                Count   <= 0;
                Tick100 <= '1';

            else

                Count   <= Count + 1;
                Tick100 <= '0';

            end if;

        end if;

    end process;

end architecture RTL;