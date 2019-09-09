# This XDC file must be directly applied to all instances of sync_Bits_Xilinx.
# To achieve this, set property SCOPED_TO_REF to sync_Bits_Xilinx within the Vivado project.
# Load XDC file defining the clocks before this XDC file by using the property PROCESSING_ORDER.
set_property  ASYNC_REG true  [ get_cells -regexp {gen\[\d+\]\.Sync/FF1_METASTABILITY_FFS} ]
set_property  ASYNC_REG true  [ get_cells -regexp {gen\[\d+\]\.Sync/gen\[\d+\]\.FF}        ]

#set_max_delay             -to [ get_pins -regexp {gen\[\d+\]\.Sync/FF1_METASTABILITY_FFS/D} ] 5.0

set_false_path -from [all_clocks] -to [get_pins -regexp {gen\[\d+\]\.Sync/FF1_METASTABILITY_FFS/D}]
