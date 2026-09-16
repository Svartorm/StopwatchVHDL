library ieee;
use ieee.std_logic_1164.all;

entity fsm_ctrl is
    port(
        Clk      : in  std_logic;
        nReset   : in  std_logic;
        KeyOne   : in  std_logic;

        Running  : out std_logic;
        VGA      : out std_logic_vector(2 downto 0);
        Bar      : out std_logic_vector(1 downto 0)
    );
end entity fsm_ctrl;

architecture RTL of fsm_ctrl is

    type state_t is (Stop, Pause, Run);
    signal State : state_t;

    signal KeyOne_prev  : std_logic := '0';
    signal KeyOne_pulse : std_logic := '0';

begin

    -- Détection d'un seul appui sur Key1
    process(Clk, nReset)
    begin

        if nReset = '0' then
            KeyOne_prev  <= '0';
            KeyOne_pulse <= '0';

        elsif rising_edge(Clk) then

            KeyOne_pulse <= KeyOne and not KeyOne_prev;
            KeyOne_prev  <= KeyOne;

        end if;

    end process;


    process(Clk, nReset)
    begin

        if nReset = '0' then
            State <= Stop;

        elsif rising_edge(Clk) then

            case State is

                when Run =>                             --1
                    if KeyOne_pulse = '1' then
                        State <= Pause;
                    end if;

                when Stop =>                            --2
                    if KeyOne_pulse = '1' then
                        State <= Run;
                    end if;

                when Pause =>                           --3
                    if KeyOne_pulse = '1' then
                        State <= Run;
                    end if;

            end case;

        end if;

    end process;


    -- Sorties
    process(State)
    begin

        case State is

            when Run =>                                --1
                Running <= '1';
                VGA <= "010"; -- green
                Bar <= "01";  -- active

            when Stop =>                               --2
                Running <= '0';
                VGA <= "001"; -- blue
                Bar <= "00";  -- absent

            when Pause =>                              --3
                Running <= '0';
                VGA <= "100"; -- red
                Bar <= "10";  -- stoped

        end case;

    end process;

end architecture RTL;