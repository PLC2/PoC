-- =============================================================================
-- Authors:
--
-- Test case:   Tag lookup with reference counting
--
-- Description:
-- -------------------------------------
-- Directed part (only with TAG_BITS > 0):
--   D1 tag miss allocates an entry
--   D2 tag hit shares the entry up to MAX_REFERENCES, data is not updated
--   D3 Put is ignored at MAX_REFERENCES (TagFull)
--   D4 Put on a hit and Got of the last reference in the same cycle
--   D5 entry released while its tag is presented: IndexOut stays, the next
--      Put re-allocates the same index
--   D6 full buffer: new tags wait, known tags can still share an entry
-- Random part (all configurations):
--   Put/Got traffic against a reference model. Every cycle checks TagHit,
--   TagFull, Full, PutReady, IndexOut, Valid, DataOut and IndexOut stability
--   while a request waits.
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

architecture TagLookup of dstruct_OutOfOrderBuffer_TestController is
	constant TestName      : string   := "TC_TagLookup_Tag" & to_string(TAG_BITS) & "_Ref" & to_string(MAX_REFERENCES);
	constant INDEX_BITS    : positive := log2ceilnz(NUM_INDEX);
	constant RANDOM_CYCLES : positive := 20000;
	signal   TestDone      : integer_barrier := 1;
begin

	ControlProc : process
		constant TIMEOUT : time := 2 ms;
	begin
		SetTestName(TestName);
		TranscriptOpen;
		SetTranscriptMirror(TRUE);
		SetLogEnable(PASSED, FALSE);
		SetLogEnable(INFO, FALSE);

		wait for 0 ns; wait for 0 ns;
		wait until nReset = '1';
		ClearAlerts;

		WaitForBarrier(TestDone, TIMEOUT);
		AlertIf(now >= TIMEOUT, "Test finished due to timeout");
		AlertIf(GetAffirmCount < 50000, "Test is not Self-Checking");

		EndOfTestReports(ReportAll => TRUE, Timeout => now >= TIMEOUT);
		std.env.stop;
		wait;
	end process;

	StimulusProc : process
		subtype T_Data is std_logic_vector(DATA_BITS -1 downto 0);
		type    T_Bool_Vector is array (natural range <>) of boolean;
		type    T_Data_Vector is array (natural range <>) of T_Data;

		constant TAG_RANGE   : positive := minimum(2**TAG_BITS, NUM_INDEX + NUM_INDEX / 2 + 1);
		constant PAYLOAD_MAX : natural  := 2**(DATA_BITS - TAG_BITS) - 1;

		-- reference model
		variable mValid : T_Bool_Vector(0 to NUM_INDEX -1) := (others => false);
		variable mCount : integer_vector(0 to NUM_INDEX -1) := (others => 0);
		variable mData  : T_Data_Vector(0 to NUM_INDEX -1) := (others => (others => '0'));

		-- previous cycle, for the IndexOut stability check
		variable PrevData       : T_Data  := (others => '0');
		variable PrevIndex      : natural := 0;
		variable PrevAccepted   : boolean := true;
		variable PrevMeaningful : boolean := false;

		-- result of the last cycle, for directed checks
		variable LastIndex    : natural;
		variable LastHit      : boolean;
		variable LastAccepted : boolean;

		-- coverage
		variable cntAlloc, cntShare, cntBlocked, cntFull, cntShareLast, cntStable, cntKeepIndex : natural := 0;

		variable RV : RandomPType;

		impure function MakeData(Payload : natural; TagValue : natural) return T_Data is
			variable Result : T_Data;
		begin
			if TAG_BITS = 0 then
				Result := std_logic_vector(to_unsigned(Payload, DATA_BITS));
			else
				Result := std_logic_vector(shift_left(to_unsigned(Payload, DATA_BITS), TAG_BITS));
				Result(TAG_BITS -1 downto 0) := std_logic_vector(to_unsigned(TagValue, TAG_BITS));
			end if;
			return Result;
		end function;

		procedure ModelLookup(Data : T_Data; Hit : out boolean; Index : out natural) is
		begin
			Hit   := false;
			Index := 0;
			if TAG_BITS > 0 then
				for i in 0 to NUM_INDEX -1 loop
					if mValid(i) and (mData(i)(TAG_BITS -1 downto 0) = Data(TAG_BITS -1 downto 0)) then
						Hit   := true;
						Index := i;
					end if;
				end loop;
			end if;
		end procedure;

		impure function ModelFull return boolean is
		begin
			for i in 0 to NUM_INDEX -1 loop
				if not mValid(i) then
					return false;
				end if;
			end loop;
			return true;
		end function;

		impure function ModelUsed return natural is
			variable n : natural := 0;
		begin
			for i in 0 to NUM_INDEX -1 loop
				if mValid(i) then
					n := n + 1;
				end if;
			end loop;
			return n;
		end function;

		-- one clock cycle: drive, check all outputs against the model, clock, update the model
		procedure Cycle(PutV : std_logic; DataV : T_Data; GotV : std_logic; IdxV : natural; Msg : string) is
			variable eHit, eHitFull, eFull, eReady : boolean;
			variable eIndex, Index : natural;
			variable Accepted, GotHit : boolean;
		begin
			Put     <= PutV;
			DataIn  <= DataV;
			Got     <= GotV;
			IndexIn <= to_unsigned(IdxV, INDEX_BITS);
			wait for 1 ns;

			ModelLookup(DataV, eHit, eIndex);
			eHitFull := eHit and (mCount(eIndex) >= MAX_REFERENCES);
			eFull    := ModelFull;
			eReady   := (eHit and not eHitFull) or (not eHit and not eFull);
			Index    := to_integer(IndexOut);

			AffirmIfEqual(TagHit,   to_sl(eHit),     Msg & ": TagHit");
			AffirmIfEqual(TagFull,  to_sl(eHitFull), Msg & ": TagFull");
			AffirmIfEqual(Full,     to_sl(eFull),    Msg & ": Full");
			AffirmIfEqual(PutReady, to_sl(eReady),   Msg & ": PutReady");
			if eHit then
				AffirmIfEqual(Index, eIndex, Msg & ": IndexOut on tag hit");
			elsif not eFull then
				AffirmIf((Index < NUM_INDEX) and not mValid(Index), Msg & ": IndexOut " & to_string(Index) & " is not a free entry");
			end if;

			-- IndexOut must not move while the same request waits
			if (DataV = PrevData) and not PrevAccepted and PrevMeaningful then
				AffirmIfEqual(Index, PrevIndex, Msg & ": IndexOut changed while the request was waiting");
				cntStable := cntStable + 1;
			end if;

			if IdxV < NUM_INDEX then
				AffirmIfEqual(Valid, to_sl(mValid(IdxV)), Msg & ": Valid of index " & to_string(IdxV));
				if mValid(IdxV) then
					AffirmIfEqual(DataOut, mData(IdxV), Msg & ": DataOut of index " & to_string(IdxV));
				end if;
			end if;

			Accepted := (PutV = '1') and eReady;
			GotHit   := (GotV = '1') and (IdxV < NUM_INDEX) and mValid(IdxV);

			-- coverage
			if Accepted and not eHit then cntAlloc   := cntAlloc + 1;   end if;
			if Accepted and eHit     then cntShare   := cntShare + 1;   end if;
			if (PutV = '1') and eHitFull then cntBlocked := cntBlocked + 1; end if;
			if eFull                 then cntFull    := cntFull + 1;    end if;
			if Accepted and eHit and GotHit and (IdxV = eIndex) and (mCount(eIndex) = 1) then
				cntShareLast := cntShareLast + 1;
			end if;
			if eHit and not Accepted and GotHit and (IdxV = eIndex) and (mCount(eIndex) = 1) then
				cntKeepIndex := cntKeepIndex + 1;  -- entry of the waiting tag is released
			end if;

			PrevData       := DataV;
			PrevIndex      := Index;
			PrevAccepted   := Accepted;
			PrevMeaningful := eHit or not eFull;
			LastIndex      := Index;
			LastHit        := eHit;
			LastAccepted   := Accepted;

			WaitForClock(Clock);

			-- model update: Put first, then Got (same-cycle share keeps the entry)
			if Accepted then
				if eHit then
					mCount(eIndex) := mCount(eIndex) + 1;
				elsif Index < NUM_INDEX then
					mValid(Index) := true;
					mCount(Index) := 1;
					mData(Index)  := DataV;
				end if;
			end if;
			if GotHit then
				mCount(IdxV) := mCount(IdxV) - 1;
				if mCount(IdxV) = 0 then
					mValid(IdxV) := false;
				end if;
			end if;
		end procedure;

		-- random Got index: mostly an occupied entry, sometimes any index
		impure function RandomGotIndex return natural is
			variable n, k : natural;
		begin
			n := ModelUsed;
			if (n = 0) or (RV.RandInt(0, 99) < 15) then
				return RV.RandInt(0, 2**INDEX_BITS -1);
			end if;
			k := RV.RandInt(1, n);
			for i in 0 to NUM_INDEX -1 loop
				if mValid(i) then
					k := k - 1;
					if k = 0 then
						return i;
					end if;
				end if;
			end loop;
			return 0;
		end function;

		variable A, B     : T_Data;
		variable IdxA     : natural;
		variable TagNext  : natural;
		variable DataV    : T_Data;
		variable PutV     : std_logic;
		variable GotV     : std_logic;
		variable PutRate  : natural;
		variable GotRate  : natural;
	begin
		assert (TAG_BITS = 0) or (2**TAG_BITS > NUM_INDEX + 2) report "TAG_BITS too small for this test" severity failure;
		RV.InitSeed(TestName);

		Put     <= '0';
		Got     <= '0';
		DataIn  <= (others => '0');
		IndexIn <= (others => '0');
		wait until nReset = '1';
		WaitForClock(Clock, 2);

		if TAG_BITS > 0 then
			Log("D1-D3: allocate, share, saturate", ALWAYS);
			A := MakeData(16#A1#, 1);
			B := MakeData(16#B1#, 1);  -- same tag, other payload
			Cycle('1', A, '0', 0, "D1 allocate");
			AffirmIf(not LastHit and LastAccepted, "D1 tag miss must allocate");
			IdxA := LastIndex;

			for r in 2 to MAX_REFERENCES loop
				Cycle('1', B, '0', IdxA, "D2 share");
				AffirmIf(LastHit and LastAccepted and (LastIndex = IdxA), "D2 tag hit must share entry " & to_string(IdxA));
			end loop;

			Cycle('1', B, '0', IdxA, "D3 saturated");
			AffirmIf(LastHit and not LastAccepted and (LastIndex = IdxA), "D3 Put must be ignored at MAX_REFERENCES");
			AffirmIfEqual(mCount(IdxA), MAX_REFERENCES, "D3 reference count");

			if MAX_REFERENCES > 1 then
				Log("D4: share and return last reference in the same cycle", ALWAYS);
				while mCount(IdxA) > 1 loop
					Cycle('0', A, '1', IdxA, "D4 return reference");
				end loop;
				Cycle('1', A, '1', IdxA, "D4 share + last Got");
				AffirmIf(LastHit and LastAccepted, "D4 share must be accepted");
				Cycle('0', A, '0', IdxA, "D4 entry kept");
				AffirmIf(LastHit and (LastIndex = IdxA), "D4 entry must stay valid");
			end if;

			Log("D5: release while the tag is presented", ALWAYS);
			while mCount(IdxA) > 0 loop
				Cycle('0', A, '1', IdxA, "D5 return reference");
			end loop;
			Cycle('1', A, '0', 0, "D5 re-allocate");
			AffirmIf(not LastHit and LastAccepted and (LastIndex = IdxA), "D5 waiting tag must be re-allocated to index " & to_string(IdxA));

			Log("D6: full buffer", ALWAYS);
			TagNext := 2;
			while not ModelFull loop
				Cycle('1', MakeData(TagNext, TagNext), '0', 0, "D6 fill");
				TagNext := TagNext + 1;
			end loop;
			Cycle('1', MakeData(0, TagNext), '0', 0, "D6 new tag while full");
			AffirmIf(not LastAccepted, "D6 new tag must wait while full");
			Cycle('1', A, '0', 0, "D6 known tag while full");
			AffirmIf(LastHit and (LastAccepted = (MAX_REFERENCES > 1)), "D6 known tag shares while full (MAX_REFERENCES > 1)");

			for i in 0 to NUM_INDEX -1 loop
				while mValid(i) loop
					Cycle('0', MakeData(0, TagNext), '1', i, "D6 drain");
				end loop;
			end loop;
		end if;

		-- ---------------------------------------------------------------------
		-- Random traffic against the reference model
		-- ---------------------------------------------------------------------
		Log("Random traffic, " & to_string(RANDOM_CYCLES) & " cycles", ALWAYS);
		DataV := MakeData(0, 0);
		for c in 1 to RANDOM_CYCLES loop
			if (c / 400) mod 2 = 0 then
				PutRate := 75; GotRate := 30;   -- fill phase
			else
				PutRate := 35; GotRate := 70;   -- drain phase
			end if;

			-- a request that was not accepted mostly keeps waiting (like AXI VALID)
			if PrevAccepted or (RV.RandInt(0, 99) < 15) then
				DataV := MakeData(RV.RandInt(0, PAYLOAD_MAX), RV.RandInt(0, TAG_RANGE -1));
			end if;

			PutV := '0';
			if RV.RandInt(0, 99) < PutRate then
				PutV := '1';
			end if;
			GotV := '0';
			if RV.RandInt(0, 99) < GotRate then
				GotV := '1';
			end if;

			Cycle(PutV, DataV, GotV, RandomGotIndex, "R" & to_string(c));
		end loop;

		for i in 0 to NUM_INDEX -1 loop
			while mValid(i) loop
				Cycle('0', DataV, '1', i, "drain");
			end loop;
		end loop;
		Cycle('0', DataV, '0', 0, "empty");

		Log("Coverage: alloc=" & to_string(cntAlloc) & " share=" & to_string(cntShare) &
		    " blocked=" & to_string(cntBlocked) & " full=" & to_string(cntFull) &
		    " shareLast=" & to_string(cntShareLast) & " keepIndex=" & to_string(cntKeepIndex) &
		    " stableChecks=" & to_string(cntStable), ALWAYS);
		AffirmIf(cntAlloc  > 0, "Coverage: allocations");
		AffirmIf(cntFull   > 0, "Coverage: buffer full");
		AffirmIf(cntStable > 0, "Coverage: stability checks");
		if TAG_BITS > 0 then
			AffirmIf(cntBlocked   > 0, "Coverage: Put blocked by TagFull");
			AffirmIf(cntKeepIndex > 0, "Coverage: entry released while its tag waits");
			if MAX_REFERENCES > 1 then
				AffirmIf(cntShare     > 0, "Coverage: shared entries");
				AffirmIf(cntShareLast > 0, "Coverage: share and last Got in one cycle");
			end if;
		end if;

		WaitForBarrier(TestDone);
		wait;
	end process;

end architecture;

configuration TC_TagLookup of tb_OutOfOrderBuffer is
	for TestHarness
		for TestCtrl : dstruct_OutOfOrderBuffer_TestController
			use entity work.dstruct_OutOfOrderBuffer_TestController(TagLookup);
		end for;
	end for;
end configuration;
