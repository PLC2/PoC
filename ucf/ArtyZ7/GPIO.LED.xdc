## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7000
## =============================================================================================================================================================
## General Purpose I/O
## =============================================================================================================================================================
## LEDs
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:				34,35
##	VCCO:				VCC3V3	
##	Location:			LD0, LD1, LD2, LD3
## -----------------------------------------------------------------------------

## {OUT}	LD0;
set_property PACKAGE_PIN  R14       [ get_ports ArtyZ7_GPIO_LED[0] ]
## {OUT}	LD1;
set_property PACKAGE_PIN  P14       [ get_ports ArtyZ7_GPIO_LED[1] ]
## {OUT}	LD2;
set_property PACKAGE_PIN  N16       [ get_ports ArtyZ7_GPIO_LED[2] ]
## {OUT}	LD3;
set_property PACKAGE_PIN  M14       [ get_ports ArtyZ7_GPIO_LED[3] ]

# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports -regexp {ArtyZ7_GPIO_LED\[\d\]} ]

# Ignore timings on async I/O pins
set_false_path                  -to [ get_ports -regexp {ArtyZ7_GPIO_LED\[\d\]} ]
