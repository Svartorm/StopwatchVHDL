library ieee;
use ieee.std_logic_1164.all;

entity key_pulse is
    port(
        Clk      : in  std_logic;
        nReset   : in  std_logic;
        KeyIn    : in  std_logic;
        KeyPulse : out std_logic
    );
end entity key_pulse;

architecture RTL of key_pulse is

    signal KeyPrev : std_logic := '0';

begin

    process(Clk, nReset)
    begin

        if nReset = '0' then

            KeyPrev  <= '0';
            KeyPulse <= '0';

        elsif rising_edge(Clk) then

            -- Détection du front montant
            KeyPulse <= KeyIn and not KeyPrev;

            KeyPrev <= KeyIn;

        end if;

    end process;

end architecture RTL;