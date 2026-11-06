-- =============================================================================
-- Authors:     Stefan Unrein
--
-- Entity:      Out of Order Buffer
--
-- Description:
-- -------------------------------------
-- When data (DataIn) is put in (Put = '1'), an index (IndexOut) is returned.
-- If later, this index is given to this component (IndexIn and Got = '1') the
-- Data of the corresponding index is returned.
--
-- Index stability
-- ***************
-- IndexOut only moves to another free index when a Put is accepted or when the
-- buffer was full and an entry is released. As long as DataIn is stable and no
-- Put is accepted, IndexOut is stable while PutReady = '1' or TagHit = '1'.
-- This allows to use IndexOut directly as an ID while VALID is pending.
--
-- Tag lookup (TAG_BITS > 0)
-- *************************
-- The lower bits of DataIn form a tag. The tag is compared in parallel
-- against all occupied entries (fully-associative lookup). Tags of occupied
-- entries are unique.
--
-- * Tag miss: IndexOut is the next free index. A Put allocates this entry and
--   stores DataIn (same as without lookup).
-- * Tag hit:  IndexOut is the index of the matching entry (TagHit = '1'). A Put
--   allocates no new entry, but adds a reference to the matching entry. The
--   stored data is not updated on a hit.
-- * Every accepted Got returns one reference of entry IndexIn. The entry is
--   released with its last reference. A Put on a hit in the same cycle keeps
--   the entry alive.
-- * MAX_REFERENCES limits the references per entry. If reached, TagFull = '1'
--   and a Put is ignored. With MAX_REFERENCES = 1 every hit blocks, so equal
--   tags are serialized.
-- * If the entry matching the presented DataIn is released, IndexOut keeps its
--   value and the entry is re-allocated to the same index by the next Put.
-- * A tag hit is possible while Full = '1'. Use PutReady instead of Full.
--
-- PutReady and TagFull do not depend on Got/IndexIn (no combinatorial path
-- from the Get port to the Put port). A reference returned in the same cycle
-- becomes usable in the next cycle.
--
-- +----------------+---------------------------------------------------------+
-- | Generic        | Description                                             |
-- +================+=========================================================+
-- | DATA_BITS      | Width of DataIn and DataOut.                            |
-- | NUM_INDEX      | Number of entries (indices 0 to NUM_INDEX - 1).         |
-- | TAG_BITS       | 0 = no lookup (default). Else number of DataIn LSBs     |
-- |                | used as tag. TAG_BITS <= DATA_BITS.                     |
-- | MAX_REFERENCES | Max. references per entry, only with TAG_BITS > 0.      |
-- +----------------+---------------------------------------------------------+
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


use     work.config.all;
use     work.utils.all;
use     work.ocram.all;


entity dstruct_OutOfOrderBuffer is
	generic (
		DATA_BITS      : positive;
		NUM_INDEX      : positive;
		TAG_BITS       : natural  := 0;  -- 0 = no tag lookup
		MAX_REFERENCES : positive := 1   -- only used with TAG_BITS > 0
	);
	port (
		-- INPUTS
		Clock : in  std_logic;
		Reset : in  std_logic;

		-- Put Port
		Put      : in  std_logic;
		DataIn   : in  std_logic_vector(DATA_BITS-1 downto 0);
		Full     : out std_logic;
		IndexOut : out unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);

		-- Get Port
		Got      : in  std_logic;
		IndexIn  : in  unsigned(log2ceilnz(NUM_INDEX) -1 downto 0);
		DataOut  : out std_logic_vector(DATA_BITS-1 downto 0);
		Valid    : out std_logic;

		-- Tag lookup (optional)
		PutReady : out std_logic;  -- a Put in this cycle is accepted
		TagHit   : out std_logic;  -- tag of DataIn is held by entry IndexOut
		TagFull  : out std_logic   -- tag hit and entry holds MAX_REFERENCES references
	);
end entity;

architecture rtl of dstruct_OutOfOrderBuffer is
	constant INDEX_BITS : positive := log2ceilnz(NUM_INDEX);
	constant COUNT_BITS : positive := log2ceilnz(MAX_REFERENCES + 1);

	subtype T_Data  is std_logic_vector(DATA_BITS-1 downto 0);
	type    T_Data_Vector is array (natural range <>) of T_Data;    -- FIXME: T_SLVV
	subtype T_Index is unsigned(INDEX_BITS -1 downto 0);

	signal IndexValid  : std_logic_vector(0 to NUM_INDEX -1) := (others => '0');
	signal DataBuffer  : T_Data_Vector(0 to NUM_INDEX -1)    := (others => (others => '0'));

	signal NextIndex   : T_Index   := (others => '0');
	signal full_i      : std_logic := '0';

	-- Tag lookup
	signal Hit         : std_logic;
	signal HitIndex    : T_Index;
	signal HitFull     : std_logic;

	-- Accepted operations
	signal PutReady_i  : std_logic;
	signal PutAlloc    : std_logic;  -- accepted Put on a tag miss: allocates NextIndex
	signal PutShare    : std_logic;  -- accepted Put on a tag hit: adds a reference to HitIndex
	signal GotValid    : std_logic;  -- Got for an occupied entry
	signal LastRef     : std_logic;  -- Got returns the last reference of entry IndexIn

	function first_free(Free : std_logic_vector(0 to NUM_INDEX -1)) return T_Index is
	begin
		for i in Free'range loop
			if Free(i) = '1' then
				return to_unsigned(i, INDEX_BITS);
			end if;
		end loop;
		return to_unsigned(0, INDEX_BITS);
	end function;

begin
	assert TAG_BITS <= DATA_BITS report "PoC.dstruct_OutOfOrderBuffer:: TAG_BITS must not exceed DATA_BITS." severity failure;
	assert (TAG_BITS > 0) or (MAX_REFERENCES = 1) report "PoC.dstruct_OutOfOrderBuffer:: MAX_REFERENCES has no effect without TAG_BITS." severity note;

	-- ===========================================================================
	-- Get port
	-- ===========================================================================
	process(all)
	begin
		DataOut  <= (others => '1');
		Valid    <= '0';
		GotValid <= '0';
		if IndexIn < NUM_INDEX then -- range check for index
			DataOut  <= DataBuffer(to_integer(IndexIn));
			Valid    <= IndexValid(to_integer(IndexIn));
			GotValid <= Got and IndexValid(to_integer(IndexIn));
		end if;
	end process;

	-- ===========================================================================
	-- Tag lookup
	-- ===========================================================================
	gen_lookup : if TAG_BITS > 0 generate
		signal HitVector : std_logic_vector(0 to NUM_INDEX -1);
	begin
		process(all)
			variable Index : T_Index;
		begin
			Index := (others => '0');
			for i in 0 to NUM_INDEX -1 loop
				if (IndexValid(i) = '1') and (DataBuffer(i)(TAG_BITS -1 downto 0) = DataIn(TAG_BITS -1 downto 0)) then
					HitVector(i) <= '1';
					Index        := Index or to_unsigned(i, INDEX_BITS); -- tags are unique: OR-encoder is sufficient
				else
					HitVector(i) <= '0';
				end if;
			end loop;
			HitIndex <= Index;
		end process;

		Hit <= slv_or(HitVector);

		-- synthesis translate_off
		process(Clock) -- sanity check for simulation
			variable Count : natural;
		begin
			if rising_edge(Clock) and (Reset = '0') then
				Count := 0;
				for i in HitVector'range loop
					if HitVector(i) = '1' then
						Count := Count + 1;
					end if;
				end loop;
				assert Count <= 1 report "PoC.dstruct_OutOfOrderBuffer:: Tag is stored in more than one entry." severity error;
			end if;
		end process;
		-- synthesis translate_on

	else generate
		Hit      <= '0';
		HitIndex <= (others => '0');
	end generate;

	-- ===========================================================================
	-- Reference counting
	-- ===========================================================================
	gen_refcount : if (TAG_BITS > 0) and (MAX_REFERENCES > 1) generate
		subtype T_Count is unsigned(COUNT_BITS -1 downto 0);
		type    T_Count_Vector is array (natural range <>) of T_Count;

		signal RefCount : T_Count_Vector(0 to NUM_INDEX -1) := (others => (others => '0'));
	begin
		process(all)
			variable CountHit : T_Count;
			variable CountIn  : T_Count;
		begin
			CountHit := (others => '0');
			CountIn  := (others => '0');
			if HitIndex < NUM_INDEX then
				CountHit := RefCount(to_integer(HitIndex));
			end if;
			if IndexIn < NUM_INDEX then
				CountIn  := RefCount(to_integer(IndexIn));
			end if;

			HitFull <= Hit and to_sl(CountHit = MAX_REFERENCES);
			-- last reference returned, unless a Put on the same entry adds one in this cycle
			LastRef <= GotValid and to_sl(CountIn = 1) and not (PutShare and to_sl(HitIndex = IndexIn));
		end process;

		process(Clock)
			variable Inc : std_logic;
			variable Dec : std_logic;
		begin
			if rising_edge(Clock) then
				for i in 0 to NUM_INDEX -1 loop
					Inc := (PutAlloc and to_sl(NextIndex = i)) or (PutShare and to_sl(HitIndex = i));
					Dec := GotValid and to_sl(IndexIn = i);
					if Reset = '1' then
						RefCount(i) <= (others => '0');
					elsif (Inc = '1') and (Dec = '0') then
						RefCount(i) <= RefCount(i) + 1;
					elsif (Inc = '0') and (Dec = '1') then
						RefCount(i) <= RefCount(i) - 1;
					end if;
				end loop;
			end if;
		end process;

	else generate
		HitFull <= Hit;       -- one reference per entry: every hit blocks
		LastRef <= GotValid;
	end generate;

	-- ===========================================================================
	-- Put port
	-- ===========================================================================
	PutReady_i <= (Hit and not HitFull) or (not Hit and not full_i);
	PutAlloc   <= Put and not Hit and not full_i;
	PutShare   <= Put and Hit and not HitFull;

	process(Clock)
		variable FreeOthers : std_logic_vector(0 to NUM_INDEX -1);
	begin
		if rising_edge(Clock) then
			if Reset = '1' then
				IndexValid <= (others => '0');
				NextIndex  <= (others => '0');
				full_i     <= '0';
			else
				if LastRef = '1' then
					IndexValid(to_integer(IndexIn)) <= '0';
				end if;

				if PutAlloc = '1' then
					IndexValid(to_integer(NextIndex)) <= '1';
					DataBuffer(to_integer(NextIndex)) <= DataIn;
				end if;

				-- NextIndex only moves if it was consumed or if the buffer was full.
				-- The priority encoder only sees registered state; a released index
				-- is only used as fallback (short path from the Get port).
				FreeOthers := not IndexValid;
				FreeOthers(to_integer(NextIndex)) := '0';

				if (PutAlloc = '1') or (full_i = '1') then
					if slv_or(FreeOthers) = '1' then
						NextIndex <= first_free(FreeOthers);
						full_i    <= '0';
					elsif LastRef = '1' then
						NextIndex <= IndexIn;
						full_i    <= '0';
					else
						full_i    <= '1';
					end if;
				elsif (LastRef = '1') and (Hit = '1') and (HitIndex = IndexIn) then
					-- entry of the waiting DataIn is released: keep IndexOut stable
					NextIndex <= IndexIn;
				end if;
			end if;
		end if;
	end process;

	-- ===========================================================================
	-- Outputs
	-- ===========================================================================
	IndexOut <= HitIndex when Hit = '1' else NextIndex;
	Full     <= full_i;
	PutReady <= PutReady_i;
	TagHit   <= Hit;
	TagFull  <= HitFull;

end architecture;
