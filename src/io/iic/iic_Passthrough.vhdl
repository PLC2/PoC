-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Stefan Unrein
--
-- Entity:				 	I2C passthrough module for an FPGA with debug/sniffing outputs
--
-- Description:
-- -------------------------------------
-- This module creates a transparent I2C path through an FPGA. In addition this
-- module offers a debug/sniffing line to log I2C operations.
--
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
use     IEEE.STD_LOGIC_1164.all;
use     IEEE.NUMERIC_STD.all;

use     work.utils.all;
use     work.physical.all;
use     work.io.all;
use     work.iic.all;


entity iic_Passthrough is
	generic (
		CLOCK_FREQ     : FREQ    := 100 MHz;
		DEBOUNCE_TIME  : T_TIME  := 50.0e-9;
		SYNC_BITS      : natural := 3
	);
  port (
		reset   : in    std_logic;
		clock   : in    std_logic;
		
  	port_a  : inout T_IO_IIC_SERIAL;
		port_b  : inout T_IO_IIC_SERIAL;
		
		debug   : out   T_IO_IIC_SERIAL_PCB
	);
end entity;


architecture rtl of iic_Passthrough is
	constant cycles  : natural := TimingToCycles(DEBOUNCE_TIME, CLOCK_FREQ);
	constant c_data  : natural := 1;
	constant c_clock : natural := 0;
  
  signal debug_level     : std_logic_vector(1 downto 0);

	signal a_level         : std_logic_vector(1 downto 0);
	signal b_level         : std_logic_vector(1 downto 0);
	signal a_set           : std_logic_vector(1 downto 0) := (others => '0');
	signal b_set           : std_logic_vector(1 downto 0) := (others => '0');
  

  type t_state is (IDLE, ST_A, ST_B);

begin
	--SCL
	port_a.clock.O    <= '0';
	port_a.clock.T    <= not a_set(c_clock);
	
	port_b.clock.O    <= '0';
	port_b.clock.T    <= not b_set(c_clock);
	
	debug.clock       <= debug_level(c_clock);
	
	--SDA
	port_a.data.O     <= '0';
	port_a.data.T     <= not a_set(c_data);
	
	port_b.data.O     <= '0';
	port_b.data.T     <= not b_set(c_data);
	
	debug.data        <= debug_level(c_data);

  
  sync : entity poc.sync_Bits
  generic map(
    BITS          => 4,
    INIT          => x"FFFFFFFF",
    SYNC_DEPTH    => 2
  )
  port map(
    Clock         => clock,
    Input(0)      => port_a.data.I,
    Input(1)      => port_b.data.I,
    Input(2)      => port_a.clock.I,
    Input(3)      => port_b.clock.I,
    Output(0)     => a_level(c_data),
    Output(1)     => b_level(c_data),
    Output(2)     => a_level(c_clock),
    Output(3)     => b_level(c_clock)
  );


	genFSM : for i in 0 to 1 generate
		signal state      : t_state := IDLE;
		signal wait_count : integer range 0 to cycles := cycles -1;
	begin
		debug_level(i) <= '0' when state /= IDLE else '1';
		
		fsm : process(clock)
		begin
			if rising_edge(clock) then
				a_set(i) <= '0';
				b_set(i) <= '0';
				
				if reset = '1' then
					state      <= IDLE;
					wait_count <= cycles -1;
				else
					case state is
						when IDLE => 
							wait_count <= cycles -1;
							if a_level(i) = '0' then 
								state      <= ST_A;
								b_set(i)   <= '1';
							end if;
							if b_level(i) = '0' then 
								state    <= ST_B;
								a_set(i) <= '1';
							end if;
							
						when ST_A => 
							b_set(i) <= '1';
							if wait_count = 0 then 
								if a_level(i) = '1' then 
									state  <= IDLE;
								end if;
							else 
								wait_count <= wait_count -1;
							end if;

							
						when ST_B => 
							a_set(i) <= '1';
							if wait_count = 0 then 
								if b_level(i) = '1' then 
									state  <= IDLE;
								end if;
							else 
								wait_count <= wait_count -1;
							end if;

					end case;
				end if;
			end if;
		end process;
  end generate;
end architecture;
