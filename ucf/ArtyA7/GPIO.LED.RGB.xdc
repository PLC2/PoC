## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
##
## LEDs
## -----------------------------------------------------------------------------
##	Bank:					35
##	VCCO:					3.3V (FPGA_3V3)
##	Location:				LD0, LD1, LD2, LD3
## -----------------------------------------------------------------------------
## {OUT}	LD0.R;
set_property PACKAGE_PIN  G6        [ get_ports {ArtyA7_GPIO_ColorLED[0][R]} ]
## {OUT}	LD0.G;
set_property PACKAGE_PIN  F6        [ get_ports {ArtyA7_GPIO_ColorLED[0][G]} ]
## {OUT}	LD0.B;
set_property PACKAGE_PIN  E1        [ get_ports {ArtyA7_GPIO_ColorLED[0][B]} ]
## {OUT}	LD1.R;
set_property PACKAGE_PIN  G3        [ get_ports {ArtyA7_GPIO_ColorLED[1][R]} ]
## {OUT}	LD1.G;
set_property PACKAGE_PIN  J4        [ get_ports {ArtyA7_GPIO_ColorLED[1][G]} ]
## {OUT}	LD1.B;
set_property PACKAGE_PIN  G4        [ get_ports {ArtyA7_GPIO_ColorLED[1][B]} ]
## {OUT}	LD2.R;
set_property PACKAGE_PIN  J3        [ get_ports {ArtyA7_GPIO_ColorLED[2][R]} ]
## {OUT}	LD2.G;
set_property PACKAGE_PIN  J2        [ get_ports {ArtyA7_GPIO_ColorLED[2][G]} ]
## {OUT}	LD2.B;
set_property PACKAGE_PIN  H4        [ get_ports {ArtyA7_GPIO_ColorLED[2][B]} ]
## {OUT}	LD3.R;
set_property PACKAGE_PIN  K1        [ get_ports {ArtyA7_GPIO_ColorLED[3][R]} ]
## {OUT}	LD3.G;
set_property PACKAGE_PIN  H6        [ get_ports {ArtyA7_GPIO_ColorLED[3][G]} ]
## {OUT}	LD3.B;
set_property PACKAGE_PIN  K2        [ get_ports {ArtyA7_GPIO_ColorLED[3][B]} ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyA7_GPIO_ColorLED\[\d\]\[[RGB]\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyA7_GPIO_ColorLED\[\d\]\[[RGB]\]} ]
