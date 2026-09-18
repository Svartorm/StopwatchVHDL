library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_ctrl is
    port(
        clk_25       : in  std_logic;
        nReset       : in  std_logic;

        fsm_state    : in  std_logic_vector(2 downto 0);
        centieme_val : in  unsigned(6 downto 0);

        h_pos        : out unsigned(9 downto 0);
        v_pos        : out unsigned(9 downto 0);

        R            : out std_logic_vector(3 downto 0);
        G            : out std_logic_vector(3 downto 0);
        B            : out std_logic_vector(3 downto 0);

        HSYNC        : out std_logic;
        VSYNC        : out std_logic
    );
end entity vga_ctrl;


architecture RTL of vga_ctrl is

    -- Compteurs internes VGA
    signal h_count : unsigned(9 downto 0) := (others => '0');
    signal v_count : unsigned(9 downto 0) := (others => '0');

    -- Largeur de la barre
    signal bar_width        : unsigned(9 downto 0);
    signal bar_width_frozen : unsigned(9 downto 0);

    signal fsm_state_prev : std_logic_vector(2 downto 0);

begin

    -- Sorties positions
    h_pos <= h_count;
    v_pos <= v_count;


    -- Synchronisation VGA
    HSYNC <= '0'
        when (h_count >= to_unsigned(656, 10) and
              h_count <= to_unsigned(751, 10))
        else '1';

    VSYNC <= '0'
        when (v_count >= to_unsigned(490, 10) and
              v_count <= to_unsigned(491, 10))
        else '1';


    -- Largeur de la barre :
    -- 1 centieme = 6 pixels
    bar_width <= to_unsigned(to_integer(centieme_val) * 6, 10);


    -- Compteurs VGA
    process(clk_25, nReset)
    begin

        if nReset = '0' then

            h_count <= (others => '0');
            v_count <= (others => '0');

        elsif rising_edge(clk_25) then

            if h_count = to_unsigned(799, 10) then

                h_count <= (others => '0');

                if v_count = to_unsigned(524, 10) then
                    v_count <= (others => '0');
                else
                    v_count <= v_count + 1;
                end if;

            else

                h_count <= h_count + 1;

            end if;

        end if;

    end process;


    -- Couleurs VGA
    process(fsm_state, h_count, v_count, bar_width, bar_width_frozen)
    begin

        -- Noir hors zone visible
        R <= "0000";
        G <= "0000";
        B <= "0000";


        -- Zone visible 640x480
        if (h_count < to_unsigned(640, 10)) and
        (v_count < to_unsigned(480, 10)) then

            case fsm_state is

                -- STOP = bleu
                when "001" =>

                    R <= "0000";
                    G <= "0000";
                    B <= "1111";


                -- RUN = vert
                when "010" =>

                    R <= "0000";
                    G <= "1111";
                    B <= "0000";

                    -- Barre blanche
                    if (v_count >= to_unsigned(401, 10)) and
                    (v_count <= to_unsigned(439, 10)) and
                    (h_count < bar_width) then

                        R <= "1111";
                        G <= "1111";
                        B <= "1111";

                    end if;


                -- PAUSE = rouge
                when "100" =>

                    R <= "1111";
                    G <= "0000";
                    B <= "0000";

                    -- Barre figee
                    if (v_count >= to_unsigned(401, 10)) and
                       (v_count <= to_unsigned(439, 10)) and
                       (h_count < bar_width_frozen) then

                        R <= "1111";
                        G <= "1111";
                        B <= "1111";

                    end if;


                when others =>

                    R <= "0000";
                    G <= "0000";
                    B <= "0000";

            end case;

        end if;

    end process;


    -- Freeze de la barre lors du passage en PAUSE
    process(clk_25, nReset)
    begin

        if nReset = '0' then

            fsm_state_prev   <= (others => '0');
            bar_width_frozen <= (others => '0');

        elsif rising_edge(clk_25) then

            fsm_state_prev <= fsm_state;

            if (fsm_state = "100") and
            (fsm_state_prev /= "100") then

                bar_width_frozen <= bar_width;

            end if;

        end if;

    end process;

end architecture RTL;