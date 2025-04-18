## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## Switch
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:			16			
##	VCCO:			VCC3V3			
##	Location:		SW0,SW1,SW2,SW3			
## -----------------------------------------------------------------------------

## {IN}    SW0
set_property PACKAGE_PIN  A8       [ get_ports Arty_GPIO_Switch[0] ]	
## {IN}    SW1
set_property PACKAGE_PIN  C11      [ get_ports Arty_GPIO_Switch[1] ]	
## {IN}    SW2
set_property PACKAGE_PIN  C10      [ get_ports Arty_GPIO_Switch[2] ]	
## {IN}    SW3
set_property PACKAGE_PIN  A10      [ get_ports Arty_GPIO_Switch[3] ]	