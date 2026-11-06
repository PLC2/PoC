-- =============================================================================
-- Authors:
--
-- Test case:   IndexOut stability
--
-- Description:
-- -------------------------------------
-- A request waits with Put = '0' (like an AXI address with VALID = '1' and
-- READY = '0') while another entry is released. IndexOut must not change,
-- because it is already visible as AWID/ARID. The previous implementation
-- moved IndexOut to the released index if only one entry was free.
-- Runs with and without tag lookup.
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

architecture IndexStable of dstruct_OutOfOrderBuffer_TestController is
	constant TestName   : string   := "TC_IndexStable_Tag" & to_string(TAG_BITS);
	constant INDEX_BITS : positive := log2ceilnz(NUM_INDEX);
	signal   TestDone   : integer_barrier := 1;
begin

	ControlProc : process
		constant TIMEOUT : time := 100 us;
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
		AlertIf(GetAffirmCount < 10, "Test is not Self-Checking");

		EndOfTestReports(ReportAll => TRUE, Timeout => now >= TIMEOUT);
		std.env.stop;
		wait;
	end process;

	StimulusProc : process
		variable Alloc   : integer_vector(0 to NUM_INDEX -1);
		variable Waiting : natural;

		-- distinct data words; distinct tags while n < 2**TAG_BITS
		impure function D(n : natural) return std_logic_vector is
		begin
			return std_logic_vector(to_unsigned(n, DATA_BITS));
		end function;

		procedure NextCycle is
		begin
			WaitForClock(Clock);
			wait for 1 ns;
		end procedure;

		procedure Settle is
		begin
			wait for 1 ns;
		end procedure;
	begin
		assert (TAG_BITS = 0) or (2**TAG_BITS > NUM_INDEX + 2) report "TAG_BITS too small for this test" severity failure;
		assert NUM_INDEX >= 3 report "NUM_INDEX must be >= 3 for this test" severity failure;

		Put     <= '0';
		Got     <= '0';
		DataIn  <= (others => '0');
		IndexIn <= (others => '0');
		wait until nReset = '1';
		NextCycle;

		-- -----------------------------------------------------------------------
		-- Scenario 1: one free entry left, request waits, another entry is released
		-- -----------------------------------------------------------------------
		Log("Scenario 1: waiting request while another entry is released", ALWAYS);
		for n in 0 to NUM_INDEX - 2 loop
			Put    <= '1';
			DataIn <= D(n + 1);
			Settle;
			AffirmIfEqual(PutReady, '1', "S1 fill " & to_string(n) & ": PutReady");
			Alloc(n) := to_integer(IndexOut);
			NextCycle;
		end loop;

		Put    <= '0';
		DataIn <= D(NUM_INDEX);
		Settle;
		AffirmIfEqual(Full,     '0', "S1 one entry left: Full");
		AffirmIfEqual(PutReady, '1', "S1 one entry left: PutReady");
		Waiting := to_integer(IndexOut);

		Got     <= '1';
		IndexIn <= to_unsigned(Alloc(0), INDEX_BITS);
		NextCycle;
		Got     <= '0';
		Settle;
		AffirmIfEqual(to_integer(IndexOut), Waiting, "S1 IndexOut changed while the request was waiting");

		Put <= '1';
		Settle;
		AffirmIfEqual(to_integer(IndexOut), Waiting, "S1 IndexOut at Put");
		NextCycle;
		Put     <= '0';
		IndexIn <= to_unsigned(Waiting, INDEX_BITS);
		DataIn  <= D(NUM_INDEX + 1);
		Settle;
		AffirmIfEqual(Valid,   '1',          "S1 entry allocated at the shown index");
		AffirmIfEqual(DataOut, D(NUM_INDEX), "S1 data stored at the shown index");
		AffirmIfEqual(to_integer(IndexOut), Alloc(0), "S1 released entry is the next free index");

		-- -----------------------------------------------------------------------
		-- Scenario 2: buffer full, request waits, an entry is released
		-- -----------------------------------------------------------------------
		Log("Scenario 2: full buffer, release while a request waits", ALWAYS);
		Put <= '1';
		NextCycle;
		Put    <= '0';
		DataIn <= D(NUM_INDEX + 2);
		Settle;
		AffirmIfEqual(Full,     '1', "S2 Full");
		AffirmIfEqual(PutReady, '0', "S2 PutReady while full");

		Got     <= '1';
		IndexIn <= to_unsigned(Alloc(1), INDEX_BITS);
		NextCycle;
		Got <= '0';
		Settle;
		AffirmIfEqual(Full,     '0', "S2 Full after release");
		AffirmIfEqual(PutReady, '1', "S2 PutReady after release");
		AffirmIfEqual(to_integer(IndexOut), Alloc(1), "S2 released entry is the next free index");
		Waiting := to_integer(IndexOut);
		NextCycle;
		AffirmIfEqual(to_integer(IndexOut), Waiting, "S2 IndexOut stable");

		WaitForBarrier(TestDone);
		wait;
	end process;

end architecture;

configuration TC_IndexStable of tb_OutOfOrderBuffer is
	for TestHarness
		for TestCtrl : dstruct_OutOfOrderBuffer_TestController
			use entity work.dstruct_OutOfOrderBuffer_TestController(IndexStable);
		end for;
	end for;
end configuration;
