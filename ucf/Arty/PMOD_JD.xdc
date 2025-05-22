## =============================================================================================================================================================
## Xilinx Design Constraint File (XDC)
## =============================================================================================================================================================
## Board:         Digilent - Arty
## FPGA:          Xilinx Artix 7
## =============================================================================================================================================================
## General Purpose I/O 
## =============================================================================================================================================================
## PMOD JD
## =============================================================================================================================================================
## -----------------------------------------------------------------------------
##	Bank:						35
##	VCCO:						3.3V (VCC3V3)
##	Location:					JD1,JD2,JD3,JD4,JD7,JD8,JD9,JD10
## -----------------------------------------------------------------------------

## {IN}			JD1
set_property PACKAGE_PIN  D4        [ get_ports Arty_PMOD_PortD[1] ]  
## {IN}			JD2                                         
set_property PACKAGE_PIN  D3        [ get_ports Arty_PMOD_PortD[2] ]  
## {IN}			JD3                                         
set_property PACKAGE_PIN  F4        [ get_ports Arty_PMOD_PortD[3] ]  
## {IN}			JD4                                         
set_property PACKAGE_PIN  F3        [ get_ports Arty_PMOD_PortD[4] ]  
## {IN}			JD7                                         
set_property PACKAGE_PIN  E2        [ get_ports Arty_PMOD_PortD[7] ]  
## {IN}			JD8                                         
set_property PACKAGE_PIN  D2        [ get_ports Arty_PMOD_PortD[8] ]  
## {IN}			JD9                                         
set_property PACKAGE_PIN  H2        [ get_ports Arty_PMOD_PortD[9] ]  
## {IN}			JD10                                        
set_property PACKAGE_PIN  G2        [ get_ports Arty_PMOD_PortD[10] ] 

