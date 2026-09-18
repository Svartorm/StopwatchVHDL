library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- pour faire h_pos + 1

entity vga_ctrl is
    port(
        clk_25       : in  std_logic; -- car 640×480@60Hz demande une 25 MHz
        nReset       : in  std_logic;
        fsm_state    : in  std_logic_vector(2 downto 0); -- Stop, Pause, Run
        centieme_val : in  unsigned(6 downto 0);  -- pour la barre de progression de 0 a 99

        h_pos        : out unsigned(9 downto 0); -- position horizontale de 0 a 799 
        v_pos        : out unsigned(9 downto 0); -- position verticale de 0 a 524
        R            : out std_logic_vector(3 downto 0); -- RED sur 4 bits par couleur
        G            : out std_logic_vector(3 downto 0); -- GREEN sur 4 bits par couleur
        B            : out std_logic_vector(3 downto 0); -- BLUE sur 4 bits par couleur
        HSYNC        : out std_logic; -- signal electrique a envoyé pour la synchonisation de la prochaine ligne
        VSYNC        : out std_logic
    );
end entity vga_ctrl;

architecture RTL of vga_ctrl is

        constant MAX_hVALUE : unsigned(9 downto 0) := to_unsigned(799, 10);
        constant MAX_vVALUE : unsigned(9 downto 0) := to_unsigned(524, 10);
        
        signal bar_width : unsigned(9 downto 0); -- 0 à 594 pixels.
        signal fsm_state_prev : std_logic_vector(2 downto 0);
        signal bar_width_frozen : unsigned(9 downto 0);

begin

    -- synchonisation vga
    HSYNC <= '0' when (h_pos >= 656 and h_pos <= 751) else '1';
    VSYNC <= '0' when (v_pos >= 490 and v_pos <= 491) else '1';

    process(clk_25, nReset)
    begin

        if nReset = '0' then
            h_pos <= (others => '0'); -- mise à 0
            v_pos <= (others => '0'); -- mise à 0
            
        elsif rising_edge(clk_25) then
            h_pos <= h_pos + 1;

            case h_pos is
                -- bout de ligne on descend
                when MAX_hVALUE => 
                    h_pos <= (others => '0'); -- mise à 0
                    v_pos <= v_pos + 1;
                when others =>
                    null;
            end case;

            case v_pos is 
                when MAX_vVALUE => -- remettre en haut
                    h_pos <= (others => '0'); -- mise à 0
                    v_pos <= (others => '0'); -- mise à 0
                when others =>
                    null;
            end case;

        end if;
    end process;

    -- ecrans de couleur
    process(fsm_state, h_pos, v_pos, centieme_val, bar_width_frozen)
    begin
            bar_width <= resize(centieme_val * 6, 10);

            -- Par défaut écran noir
            R <= "0000";
            G <= "0000";
            B <= "0000";

            -- Zone visible 640 x 480
            if (h_pos < 640) and (v_pos < 480) then
                case fsm_state is
                    when "001" =>                             -- RUN
                        G <= "1111"; -- vert
                        R <= "0000"; 
                        B <= "0000"; 
                        -- zone de barre
                        if (v_pos >= to_unsigned(401, 10)) and 
                           (v_pos <= to_unsigned(439, 10)) and 
                           (h_pos < bar_width) then
                            R <= "1111";
                            G <= "1111";
                            B <= "1111";
                        end if;

                    when "000" =>                            -- STOP
                        B <= "1111"; -- bleu
                        R <= "0000"; 
                        G <= "0000"; 

                    when "010" =>                           -- PAUSE
                        R <= "1111"; -- rouge
                        G <= "0000"; 
                        B <= "0000"; 
                        -- zone de barre
                        if (v_pos >= to_unsigned(401, 10)) and 
                           (v_pos <= to_unsigned(439, 10)) and 
                           (h_pos < bar_width_frozen) then
                            R <= "1111";
                            G <= "1111";
                            B <= "1111";
                        end if;

                    when others =>
                        R <= "0000"; -- noir
                        G <= "0000";
                        B <= "0000";

                end case;
            end if;
    end process;

    -- Gérer le freeze
    process(clk_25, nReset)
    begin

        if nReset = '0' then
            fsm_state_prev   <= (others => '0');
            bar_width_frozen <= (others => '0');

        elsif rising_edge(clk_25) then
            fsm_state_prev <= fsm_state;
            -- Transition détectée : maintenant on est en pause
            if (fsm_state = "010") and (fsm_state_prev /= "010") then
                bar_width_frozen <= bar_width;

            end if;
        end if;
    end process;

end architecture RTL;