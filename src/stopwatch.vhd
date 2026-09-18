library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stopwatch is

    generic(
        TICK_MAX_COUNT : integer := 499_999
    );

    port(
        -- Horloge
        MAX10_CLK1_50 : in std_logic;

        -- Boutons
        KEY : in std_logic_vector(1 downto 0);

        -- Switches
        SW : in std_logic_vector(9 downto 0);

        -- LEDs
        LEDR : out std_logic_vector(9 downto 0);

        -- Afficheurs
        HEX0 : out std_logic_vector(7 downto 0);
        HEX1 : out std_logic_vector(7 downto 0);
        HEX2 : out std_logic_vector(7 downto 0);
        HEX3 : out std_logic_vector(7 downto 0);
        HEX4 : out std_logic_vector(7 downto 0);
        HEX5 : out std_logic_vector(7 downto 0)
    );

end entity stopwatch;


architecture RTL of stopwatch is

    -- KEY1
    signal KeyPulse     : std_logic;
    signal KeyOneActive : std_logic;


    -- FSM
    signal Running   : std_logic;
    signal LoadTimer : std_logic;

    signal VGA_State : std_logic_vector(2 downto 0);
    signal Bar_State : std_logic_vector(1 downto 0);
    -- Chenillard
    signal Chaser : std_logic_vector(7 downto 0);

    -- Tick 100 Hz
    signal Tick100 : std_logic;


    -- Compteur
    signal Minutes      : unsigned(6 downto 0);
    signal Seconds      : unsigned(5 downto 0);
    signal Centiseconds : unsigned(6 downto 0);

    signal ReloadValue : unsigned(8 downto 0);


    -- Chiffres pour les afficheurs
    signal MinTens  : unsigned(3 downto 0);
    signal MinUnits : unsigned(3 downto 0);

    signal SecTens  : unsigned(3 downto 0);
    signal SecUnits : unsigned(3 downto 0);

    signal CsTens   : unsigned(3 downto 0);
    signal CsUnits  : unsigned(3 downto 0);


    -- Segments
    signal Seg0 : std_logic_vector(6 downto 0);
    signal Seg1 : std_logic_vector(6 downto 0);
    signal Seg2 : std_logic_vector(6 downto 0);
    signal Seg3 : std_logic_vector(6 downto 0);
    signal Seg4 : std_logic_vector(6 downto 0);
    signal Seg5 : std_logic_vector(6 downto 0);

begin

    -- Valeur du minuteur
    ReloadValue <= unsigned(SW(9 downto 1));


    -- Détection d'un appui sur KEY1

    -- KEY1 est actif à 0
    KeyOneActive <= not KEY(1);

    KEY_PULSE_INST : entity work.key_pulse
        port map(
            Clk      => MAX10_CLK1_50,
            nReset   => KEY(0),
            KeyIn    => KeyOneActive,
            KeyPulse => KeyPulse
        );


    -- FSM
    FSM_INST : entity work.fsm_ctrl
        port map(
            Clk       => MAX10_CLK1_50,
            nReset    => KEY(0),
            KeyOne    => KeyPulse,

            Running   => Running,
            LoadTimer => LoadTimer,
            VGA       => VGA_State,
            Bar       => Bar_State
        );


    -- Tick 100 Hz
    TICK_INST : entity work.tick_100hz
        generic map(
            MAX_COUNT => TICK_MAX_COUNT
        )
        port map(
            Clk     => MAX10_CLK1_50,
            nReset  => KEY(0),
            Tick100 => Tick100
        );


    -- Chronometre et Minuteur
    COUNTER_INST : entity work.time_counter
        port map(
            Clk          => MAX10_CLK1_50,
            nReset       => KEY(0),

            Running      => Running,
            Tick100      => Tick100,

            Mode         => SW(0),

            ReloadValue  => ReloadValue,
            LoadTimer    => LoadTimer,

            Minutes      => Minutes,
            Seconds      => Seconds,
            Centiseconds => Centiseconds
        );
    -- Chenillard
    CHASER_INST : entity work.led_chaser
        port map(
            Clk       => MAX10_CLK1_50,
            nReset    => KEY(0),
            Running   => Running,
            LoadTimer => LoadTimer,
            Chaser    => Chaser
        );


    -- Separation minutes
    MinTens  <= to_unsigned(to_integer(Minutes) / 10, 4);
    MinUnits <= to_unsigned(to_integer(Minutes) mod 10, 4);

    -- Separation secondes
    SecTens  <= to_unsigned(to_integer(Seconds) / 10, 4);
    SecUnits <= to_unsigned(to_integer(Seconds) mod 10, 4);

    -- Separation centiemes
    CsTens  <= to_unsigned(to_integer(Centiseconds) / 10, 4);
    CsUnits <= to_unsigned(to_integer(Centiseconds) mod 10, 4);


    -- HEX0 : unite des centiemes
    HEX0_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => CsUnits,
            Seg   => Seg0
        );

    -- HEX1 : dizaine des centiemes
    HEX1_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => CsTens,
            Seg   => Seg1
        );

    -- HEX2 : unite des secondes
    HEX2_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => SecUnits,
            Seg   => Seg2
        );

    -- HEX3 : dizaine des secondes
    HEX3_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => SecTens,
            Seg   => Seg3
        );

    -- HEX4 : unite des minutes
    HEX4_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => MinUnits,
            Seg   => Seg4
        );

    -- HEX5 : dizaine des minutes
    HEX5_DECODER : entity work.sevenseg_decoder
        port map(
            Digit => MinTens,
            Seg   => Seg5
        );


    -- Affichage MM:SS:CC
    HEX0(6 downto 0) <= Seg0;
    HEX0(7) <= '1';

    HEX1(6 downto 0) <= Seg1;
    HEX1(7) <= '1';

    HEX2(6 downto 0) <= Seg2;
    HEX2(7) <= '1';

    HEX3(6 downto 0) <= Seg3;
    HEX3(7) <= '1';

    HEX4(6 downto 0) <= Seg4;
    HEX4(7) <= '1';

    HEX5(6 downto 0) <= Seg5;
    HEX5(7) <= '1';


    -- Mode : 0 = chrono et 1 = minuteur
    LEDR(0) <= SW(0);

    -- Etat RUN
    LEDR(1) <= Running;

    -- Chenillard
    LEDR(9 downto 2) <= Chaser;

end architecture RTL;
