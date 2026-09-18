library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_stopwatch is
end entity tb_stopwatch;

architecture simulation of tb_stopwatch is

    -- Horloge
    signal MAX10_CLK1_50 : std_logic := '0';

    -- Boutons
    signal KEY : std_logic_vector(1 downto 0) := "11";

    -- Switches
    signal SW : std_logic_vector(9 downto 0) := (others => '0');

    -- LEDs
    signal LEDR : std_logic_vector(9 downto 0);

    -- Afficheurs
    signal HEX0 : std_logic_vector(7 downto 0);
    signal HEX1 : std_logic_vector(7 downto 0);
    signal HEX2 : std_logic_vector(7 downto 0);
    signal HEX3 : std_logic_vector(7 downto 0);
    signal HEX4 : std_logic_vector(7 downto 0);
    signal HEX5 : std_logic_vector(7 downto 0);

begin

    -- Stopwatch
    DUT : entity work.stopwatch
        generic map(
            TICK_MAX_COUNT => 4
        )
        port map(
            MAX10_CLK1_50 => MAX10_CLK1_50,

            KEY => KEY,
            SW  => SW,

            LEDR => LEDR,

            HEX0 => HEX0,
            HEX1 => HEX1,
            HEX2 => HEX2,
            HEX3 => HEX3,
            HEX4 => HEX4,
            HEX5 => HEX5
        );


    -- Horloge 50 MHz
    MAX10_CLK1_50 <= not MAX10_CLK1_50 after 10 ns;


    -- Test
    process
    begin

        -- Mode minuteur
        SW(0) <= '1';

        -- SW9..SW1 = 60 secondes
        SW(9 downto 1) <= std_logic_vector(to_unsigned(60, 9));


        -- Reset
        KEY(0) <= '0';
        KEY(1) <= '1';

        wait for 40 ns;

        KEY(0) <= '1';

        -- STOP et chargement du minuteur
        wait for 100 ns;


        -- STOP -> RUN
        KEY(1) <= '0';
        wait for 40 ns;

        KEY(1) <= '1';

        -- Décompte
        wait for 600 ns;


        -- RUN -> PAUSE
        KEY(1) <= '0';
        wait for 40 ns;

        KEY(1) <= '1';

        -- Compteur figé
        wait for 300 ns;


        -- PAUSE -> RUN
        KEY(1) <= '0';
        wait for 40 ns;

        KEY(1) <= '1';

        -- Reprise du décompte
        wait for 400 ns;


        -- Reset final
        KEY(0) <= '0';
        wait for 40 ns;

        KEY(0) <= '1';

        wait for 100 ns;

        wait;

    end process;

end architecture simulation;