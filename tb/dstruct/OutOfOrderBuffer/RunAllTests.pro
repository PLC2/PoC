# =============================================================================
# Authors:
#	Adrian Weiland (PLC2 Design GmbH)
#
# License:
# =============================================================================
# Copyright 2025-2026 The PoC-Library Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =============================================================================

TestSuite PoC.dstruct.OutOfOrderBuffer

library tb_struct_OutOfOrderBuffer

analyze dstruct_OutOfOrderBuffer_TestController.vhdl
analyze tb_OutOfOrderBuffer.vhdl

# Enable code coverage collection in simulations
# if {$::osvvm::ToolVendor eq "Aldec"} {
# 	SetCoverageSimulateEnable true
# }

RunTest TC_WriteRead.vhdl

# Disable code coverage collection in simulations
# if {$::osvvm::ToolVendor eq "Aldec"} {
# 	SetCoverageSimulateEnable false
# }

# Tag lookup feature (TAG_BITS, MAX_REFERENCES) and IndexOut stability
analyze TC_IndexStable.vhdl

TestName TC_IndexStable_Tag0
simulate TC_IndexStable [generic TAG_BITS 0] [generic MAX_REFERENCES 1]
TestName TC_IndexStable_Tag4
simulate TC_IndexStable [generic TAG_BITS 4] [generic MAX_REFERENCES 3]

analyze TC_TagLookup.vhdl

TestName TC_TagLookup_Tag4_Ref3
simulate TC_TagLookup [generic TAG_BITS 4] [generic MAX_REFERENCES 3]
TestName TC_TagLookup_Tag4_Ref1
simulate TC_TagLookup [generic TAG_BITS 4] [generic MAX_REFERENCES 1]
TestName TC_TagLookup_Tag0_Ref1
simulate TC_TagLookup [generic TAG_BITS 0] [generic MAX_REFERENCES 1]
