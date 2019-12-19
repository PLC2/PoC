-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Max Kraft-Kugler
--                  Stefan Unrein
--
-- Entity:          Creates a histogram of all input data
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
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
use     PoC.vectors.all;


entity stat_Histogram_man_boundary is
	generic (
		DATA_BITS           : positive    := 16;
		RESOLUTION_BITS     : positive    :=  4;
		COUNTER_BITS        : positive    := 16
	);
	port (
		Clock               : in  std_logic;
		Reset               : in  std_logic;

		Enable              : in  std_logic;
		DataIn              : in  std_logic_vector(DATA_BITS - 1 downto 0);
		window_bounds       : in  T_SLVV(2**RESOLUTION_BITS - 1 downto 1)(DATA_BITS - 1 downto 0);
		window_changed      : in  std_logic;

		Histogram           : out T_SLM(2**RESOLUTION_BITS - 1 downto 0, COUNTER_BITS - 1 downto 0)
	);
end entity;

architecture rtl of stat_Histogram_man_boundary is
	constant NUM_OF_BUCKETS : natural := 2**RESOLUTION_BITS; 

	signal buckets          : std_logic_vector(RESOLUTION_BITS - 1 downto 0);

begin
	-- re-resolve buckets depending on window resolution and boundary:
	process(DataIn, window_bounds) is
	begin
		--default to lowest bucket:
		buckets <= (others => '0');
		assign_buckets : for bucket_n in 1 to NUM_OF_BUCKETS - 1 loop
			-- check for highest bucket it differently:
			if (bucket_n = NUM_OF_BUCKETS - 1) then
				--check if datum is above highest bucket's threshhold
				if DataIn >= window_bounds(bucket_n) then
					buckets <= std_logic_vector(to_unsigned(bucket_n, buckets'length));
				end if;
			else
				--check if datum is between this and next bucket's threshhold
				if (DataIn >= window_bounds(bucket_n)) and (DataIn < window_bounds(bucket_n + 1 )) then
					buckets <= std_logic_vector(to_unsigned(bucket_n, buckets'length));
				end if;
			end if;
		end loop;
	end process;

	histogram : entity PoC.stat_Histogram
		generic map(
			DATA_BITS     => RESOLUTION_BITS,
			COUNTER_BITS  => COUNTER_BITS
		)
		port map(
			Clock         => Clock,
			Reset         => Reset or window_changed, -- reset on window change
			Enable        => Enable,
			DataIn        => buckets,
			Histogram     => Histogram
		);

end architecture;