-- =============================================================================
-- Authors:         Iqbal Asif
--                  Stefan Unrein
--
-- Entity:      Test harness for dstruct_OutOfOrderBuffer with tag lookup
--
-- License:
-- =============================================================================
-- Copyright 2026 The PoC-Library Authors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--        http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library PoC;
use     PoC.utils.all;

library OSVVM;
context OSVVM.OsvvmContext;

entity tb_OutOfOrderBuffer is
	generic (
		NUM_INDEX      : positive := 13;   -- not a power of 2 on purpose
		DATA_BITS      : positive := 32;
		TAG_BITS       : natural  := 0;
		MAX_REFERENCES : positive := 1
	);
end entity;

architecture TestHarness of tb_OutOfOrderBuffer is
	constant tpd         : time := 2 ns;
	constant tperiod_Clk : time := 10 ns;

	signal Clk      : std_logic := '0';
	signal nReset   : std_logic := '0';

	signal Put      : std_logic;
	signal DataIn   : std_logic_vector(DATA_BITS -1 downto 0);
	signal Full     : std_logic;
	signal IndexOut : unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);
	signal PutReady : std_logic;
	signal TagHit   : std_logic;
	signal TagFull  : std_logic;

	signal Got      : std_logic;
	signal IndexIn  : unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);
	signal DataOut  : std_logic_vector(DATA_BITS -1 downto 0);
	signal Valid    : std_logic;

	component dstruct_OutOfOrderBuffer_TestController is
		generic (
			NUM_INDEX      : positive;
			DATA_BITS      : positive;
			TAG_BITS       : natural;
			MAX_REFERENCES : positive
		);
		port (
			Clock    : in  std_logic;
			nReset   : in  std_logic;
			Put      : out std_logic;
			DataIn   : out std_logic_vector(DATA_BITS -1 downto 0);
			Full     : in  std_logic;
			IndexOut : in  unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);
			PutReady : in  std_logic;
			TagHit   : in  std_logic;
			TagFull  : in  std_logic;
			Got      : out std_logic;
			IndexIn  : out unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);
			DataOut  : in  std_logic_vector(DATA_BITS -1 downto 0);
			Valid    : in  std_logic
		);
	end component;

begin

	Osvvm.ClockResetPkg.CreateClock (
		Clk    => Clk,
		Period => tperiod_Clk
	);

	Osvvm.ClockResetPkg.CreateReset (
		Reset       => nReset,
		ResetActive => '0',
		Clk         => Clk,
		Period      => 7 * tperiod_Clk,
		tpd         => tpd
	);

	TestCtrl : component dstruct_OutOfOrderBuffer_TestController
		generic map (
			NUM_INDEX      => NUM_INDEX,
			DATA_BITS      => DATA_BITS,
			TAG_BITS       => TAG_BITS,
			MAX_REFERENCES => MAX_REFERENCES
		)
		port map (
			Clock    => Clk,
			nReset   => nReset,
			Put      => Put,
			DataIn   => DataIn,
			Full     => Full,
			IndexOut => IndexOut,
			PutReady => PutReady,
			TagHit   => TagHit,
			TagFull  => TagFull,
			Got      => Got,
			IndexIn  => IndexIn,
			DataOut  => DataOut,
			Valid    => Valid
		);

	DUT : entity PoC.dstruct_OutOfOrderBuffer
		generic map (
			DATA_BITS      => DATA_BITS,
			NUM_INDEX      => NUM_INDEX,
			TAG_BITS       => TAG_BITS,
			MAX_REFERENCES => MAX_REFERENCES
		)
		port map (
			Clock    => Clk,
			Reset    => not nReset,

			Put      => Put,
			DataIn   => DataIn,
			Full     => Full,
			IndexOut => IndexOut,

			Got      => Got,
			IndexIn  => IndexIn,
			DataOut  => DataOut,
			Valid    => Valid,

			PutReady => PutReady,
			TagHit   => TagHit,
			TagFull  => TagFull
		);

end architecture;
