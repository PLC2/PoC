## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - ArtyZ7
## FPGA:          Xilinx Zynq 7000
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## Special Button
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:				Bank500			
##	VCCO:				VCC1V8,VCC3V3		
##	Location:			BTNR 		
## -----------------------------------------------------------------------------

## {IN}		BTNR; low-active; external 10k pullup resistor
set_property PACKAGE_PIN  D9       	[ get_ports ArtyZ7_GPIO_Button_CPU_Reset_n ]
# set I/O standard
set_property IOSTANDARD   LVCMOS33  [ get_ports ArtyZ7_GPIO_Button_CPU_Reset_n ]
# Ignore timings on async I/O pins
set_false_path						-from [ get_ports ArtyZ7_GPIO_Button_CPU_Reset_n ]