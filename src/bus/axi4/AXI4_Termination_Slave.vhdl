-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Stefan Unrein
--                  Patrick Lehmann
--
-- Entity:				 	A slave-side bus termination module for AXI4 (full).
--
-- Description:
-- -------------------------------------
-- This entity is a bus termination module for AXI4 (full) that represents a
-- dummy slave.
--
-- License:
-- =============================================================================
-- Copyright 2018-2019 PLC2 Design GmbH, Germany
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use     IEEE.std_logic_1164.all;

use     work.axi4.all;


entity AXI4_Termination_Slave is
	generic (
		VALUE     : std_logic := '0'
	);
	port ( 
		AXI4_M2S  : in  T_AXI4_Bus_M2S;
		AXI4_S2M  : out T_AXI4_Bus_S2M
	);
end entity;


architecture rtl of AXI4_Termination_Slave is
	constant AddrBits : natural := AXI4_M2S.AWAddr'length;
	constant IDBits   : natural := AXI4_M2S.AWID'length;
	constant UserBits : natural := AXI4_M2S.AWUser'length;
	constant DataBits : natural := AXI4_M2S.WData'length;
	signal M2S_dummy : AXI4_M2S'subtype;
begin

	AXI4_S2M <= Initialize_AXI4_Bus_S2M(AddrBits, DataBits, UserBits, IDBits, VALUE);
	M2S_dummy <= AXI4_M2S;
	
end architecture;
