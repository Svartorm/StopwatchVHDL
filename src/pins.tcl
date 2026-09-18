# VGA RED
set_location_assignment PIN_AA1 -to {VGA_R[0]}
set_location_assignment PIN_V1  -to {VGA_R[1]}
set_location_assignment PIN_Y2  -to {VGA_R[2]}
set_location_assignment PIN_Y1  -to {VGA_R[3]}

# VGA GREEN
set_location_assignment PIN_W1 -to {VGA_G[0]}
set_location_assignment PIN_T2 -to {VGA_G[1]}
set_location_assignment PIN_R2 -to {VGA_G[2]}
set_location_assignment PIN_R1 -to {VGA_G[3]}

# VGA BLUE
set_location_assignment PIN_P1 -to {VGA_B[0]}
set_location_assignment PIN_T1 -to {VGA_B[1]}
set_location_assignment PIN_P4 -to {VGA_B[2]}
set_location_assignment PIN_N2 -to {VGA_B[3]}

# VGA Synchronisation
set_location_assignment PIN_N3 -to VGA_HS
set_location_assignment PIN_N1 -to VGA_VS

# Standard VGA
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_R[*]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_G[*]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {VGA_B[*]}
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS