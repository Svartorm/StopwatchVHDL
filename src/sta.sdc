# Horloge physique
## 50 MHz clock --> (1000/50 = 20ns period)
create_clock -name clk_50 -period 20.0 [get_ports MAX10_CLK1_50]

# Horloge generée, derivée de l'horloge physique (divisée par2)
## 25 MHz clock (1000/25 = 40ns period)
create_generated_clock -name clk_25 \
    -source [get_pins {ATROUVER}] \
    -divide_by 2 \
    [get_pins {ATROUVER}]


# Declare them asynchronous (no timing relationship)
set_clock_groups -asynchronous \
    -group {clk_50} \
    -group {clk_25}

# Exclusion des entrées 
set_false_path -from [get_ports {KEY[0]}]
set_false_path -from [get_ports {KEY[1]}]
set_false_path -from [get_ports {SW[*]}]

# Exclusion des sorties peu critiques
## leds
set_false_path -to [get_ports {LEDR[*]}]
## afficheurs 7 segmets
set_false_path -to [get_ports {HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]