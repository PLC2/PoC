-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Stefan Unrein
--									Max Kraft-Kugler
--									Patrick Lehmann
--									Asif Iqbal
--
-- Package:					TBD
--
-- Description:
-- -------------------------------------
--		For detailed documentation see below.
--
-- License:
-- =============================================================================
-- Copyright 2017-2019 PLC2 Design GmbH, Germany
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
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

use     work.utils.all;
use     work.iic.all;


entity iic_RawMultiplexer is
	generic (
		PORTS : positive := 2
	);
	port (
		sel    :	in    unsigned(log2ceilnz(PORTS) - 1 downto 0);
--		input  : 	inout T_IO_IIC_SERIAL_VECTOR(PORTS - 1 downto 0) := (others => (others => (others => 'Z')));
		Input_m2s : in  T_IO_IIC_SERIAL_OUT_VECTOR(PORTS - 1 downto 0);
		Input_s2m : out T_IO_IIC_SERIAL_IN_VECTOR(PORTS - 1 downto 0);
			
--		output :	inout T_IO_IIC_SERIAL := (others => (others => 'Z'))
		Output_m2s : out T_IO_IIC_SERIAL_OUT;
		Output_s2m : in  T_IO_IIC_SERIAL_IN
	);
end entity;

architecture rtl of iic_RawMultiplexer is
begin
	gen: for i in 0 to PORTS - 1 generate
		Input_s2m(i).Clock <= Output_s2m.Clock when sel = i else '0';
		Input_s2m(i).Data  <= Output_s2m.Data when sel = i else '0';
	end generate;
	
	Output_m2s.Clock_O <= Input_m2s(to_index(sel)).Clock_O;
	Output_m2s.Clock_T <= Input_m2s(to_index(sel)).Clock_T;
	Output_m2s.Data_O  <= Input_m2s(to_index(sel)).Data_O;
	Output_m2s.Data_T  <= Input_m2s(to_index(sel)).Data_T;
end architecture;
