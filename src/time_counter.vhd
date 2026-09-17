library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity time_counter is
    port(
        Clk          : in  std_logic;
        nReset       : in  std_logic;
        Running      : in  std_logic;
        Tick100      : in  std_logic;
        Mode         : in  std_logic;  -- 0 = chrono, 1 = timer

        ReloadValue  : in  unsigned(8 downto 0);
        LoadTimer    : in  std_logic;

        Minutes      : out unsigned(6 downto 0);
        Seconds      : out unsigned(5 downto 0);
        Centiseconds : out unsigned(6 downto 0)
    );
end entity time_counter;

architecture RTL of time_counter is

    signal MinCount : unsigned(6 downto 0) := (others => '0');
    signal SecCount : unsigned(5 downto 0) := (others => '0');
    signal CsCount  : unsigned(6 downto 0) := (others => '0');

begin

    process(Clk, nReset)

        variable TotalSeconds : integer;

    begin

        if nReset = '0' then

            MinCount <= (others => '0');
            SecCount <= (others => '0');
            CsCount  <= (others => '0');

        elsif rising_edge(Clk) then

            -- load du minuteur
            if LoadTimer = '1' and Mode = '1' then

                TotalSeconds := to_integer(ReloadValue);

                MinCount <= to_unsigned(
                    TotalSeconds / 60,
                    MinCount'length
                );

                SecCount <= to_unsigned(
                    TotalSeconds mod 60,
                    SecCount'length
                );

                CsCount <= (others => '0');


            elsif Running = '1' and Tick100 = '1' then

                -- mode chrono : compteur montant
                if Mode = '0' then

                    if CsCount = 99 then

                        CsCount <= (others => '0');

                        if SecCount = 59 then

                            SecCount <= (others => '0');

                            if MinCount = 99 then
                                MinCount <= (others => '0');
                            else
                                MinCount <= MinCount + 1;
                            end if;

                        else
                            SecCount <= SecCount + 1;
                        end if;

                    else
                        CsCount <= CsCount + 1;
                    end if;

                -- mode minuteur : compteur descendant
                else

                    if MinCount = 0 and
                    SecCount = 0 and
                    CsCount = 0 then

                        -- le reste est mis à 00:00:00
                        null;

                    elsif CsCount > 0 then

                        CsCount <= CsCount - 1;

                    elsif SecCount > 0 then

                        CsCount  <= to_unsigned(99, CsCount'length);
                        SecCount <= SecCount - 1;

                    elsif MinCount > 0 then

                        CsCount  <= to_unsigned(99, CsCount'length);
                        SecCount <= to_unsigned(59, SecCount'length);
                        MinCount <= MinCount - 1;

                    end if;

                end if;

            end if;

        end if;

    end process;

    Minutes      <= MinCount;
    Seconds      <= SecCount;
    Centiseconds <= CsCount;

end architecture RTL;