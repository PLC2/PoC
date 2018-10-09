-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	TODO
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
--										 Chair of VLSI-Design, Diagnostics and Architecture
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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.net.all;


entity arp_BroadCast_Receiver is
	generic (
		ALLOWED_PROTOCOL_IPV4				: boolean												:= TRUE;
		ALLOWED_PROTOCOL_IPV6				: boolean												:= FALSE
	);
	port (
		Clock												: in	std_logic;																	--
		Reset												: in	std_logic;																	--

		RX_Valid										: in	std_logic;
		RX_Data											: in	T_SLV_8;
		RX_SOF											: in	std_logic;
		RX_EOF											: in	std_logic;
		RX_Ack											: out	std_logic;
		RX_Meta_rst									: out	std_logic;
		RX_Meta_SrcMACAddress_nxt		: out	std_logic;
		RX_Meta_SrcMACAddress_Data	: in	T_SLV_8;
		RX_Meta_DestMACAddress_nxt	: out	std_logic;
		RX_Meta_DestMACAddress_Data	: in	T_SLV_8;

		--CSE Interface
		Command											: in  T_NET_ARP_RECEIVER_COMMAND;
		Status											: out T_NET_ARP_RECEIVER_STATUS;

		--AnswerReceived							: out	std_logic;
		Address_rst									: in	std_logic;
		SenderMACAddress_nxt				: in	std_logic;
		SenderMACAddress_Data				: out	T_SLV_8;
		SenderIPAddress_nxt					: in	std_logic;
		SenderIPAddress_Data				: out	T_SLV_8;
		TargetIPAddress_nxt					: in	std_logic;
		TargetIPAddress_Data				: out	T_SLV_8
	);
end entity;


architecture rtl of arp_BroadCast_Receiver is
	attribute FSM_ENCODING						: string;

	type T_STATE		is (
		ST_IDLE,
																	ST_RECEIVE_HARDWARE_type_1,
			ST_RECEIVE_PROTOCOL_type_0, ST_RECEIVE_PROTOCOL_type_1,
			ST_RECEIVE_HARDWARE_ADDRESS_LENGTH, ST_RECEIVE_PROTOCOL_ADDRESS_LENGTH,
			ST_RECEIVE_OPERATION_0,			ST_RECEIVE_OPERATION_1,
			ST_RECEIVE_SENDER_MAC,			ST_RECEIVE_SENDER_IP,
			ST_RECEIVE_TARGET_MAC,			ST_RECEIVE_TARGET_IP,
		ST_DISCARD_ETHERNET_PADDING_BYTES,
		ST_COMPLETE,
		ST_DISCARD_FRAME, ST_ERROR
	);
	
	type T_OPERATION	is (OP_REQUEST, OP_ANSWER);

	signal State													: T_STATE																												:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is "gray";		--"speed1";
	
	signal Operation											: T_OPERATION 																									:= OP_REQUEST;
	signal NextOperation									: T_OPERATION;
	
	signal Is_SOF													: std_logic;
	signal Is_EOF													: std_logic;

	constant HARDWARE_ADDRESS_LENGTH			: positive																											:= 6;			-- MAC -> 6 bytes
	constant PROTOCOL_IPV4_ADDRESS_LENGTH	: positive																											:= 4;			-- IPv4 -> 4 bytes
	constant PROTOCOL_IPV6_ADDRESS_LENGTH	: positive																											:= 16;		-- IPv6 -> 16 bytes
	constant PROTOCOL_ADDRESS_LENGTH			: positive																											:= ite((ALLOWED_PROTOCOL_IPV6 = FALSE), PROTOCOL_IPV4_ADDRESS_LENGTH, PROTOCOL_IPV6_ADDRESS_LENGTH);		-- IPv4 -> 4 bytes; IPv6 -> 16 bytes

	subtype T_HARDWARE_ADDRESS_INDEX			 is natural range 0 to HARDWARE_ADDRESS_LENGTH - 1;
	subtype T_PROTOCOL_ADDRESS_INDEX			 is natural range 0 to PROTOCOL_ADDRESS_LENGTH - 1;

	signal IsIPv4_set											: std_logic;
	signal IsIPv4_r												: std_logic																											:= '0';
	signal IsIPv6_set											: std_logic;
	signal IsIPv6_r												: std_logic																											:= '0';


	constant WRITER_COUNTER_BITS					: positive																											:= log2ceilnz(imax(HARDWARE_ADDRESS_LENGTH, PROTOCOL_ADDRESS_LENGTH));
	signal Writer_Counter_rst							: std_logic;
	signal Writer_Counter_en							: std_logic;
	signal Writer_Counter_us							: unsigned(WRITER_COUNTER_BITS - 1 downto 0)										:= (others => '0');

	signal Reader_SenderMAC_Counter_rst		: std_logic;
	signal Reader_SenderMAC_Counter_en		: std_logic;
	signal Reader_SenderMAC_Counter_us		: unsigned(log2ceilnz(HARDWARE_ADDRESS_LENGTH) - 1 downto 0)		:= (others => '0');

	signal Reader_SenderIP_Counter_rst		: std_logic;
	signal Reader_SenderIP_Counter_en			: std_logic;
	signal Reader_SenderIP_Counter_us			: unsigned(log2ceilnz(PROTOCOL_ADDRESS_LENGTH) - 1 downto 0)		:= (others => '0');

	signal Reader_TargetIP_Counter_rst		: std_logic;
	signal Reader_TargetIP_Counter_en			: std_logic;
	signal Reader_TargetIP_Counter_us			: unsigned(log2ceilnz(PROTOCOL_ADDRESS_LENGTH) - 1 downto 0)		:= (others => '0');

--	signal SenderMACAddress_Data_rst			: STD_LOGIC;
	signal SenderHardwareAddress_en				: std_logic;
	signal SenderHardwareAddress_us				: unsigned(log2ceilnz(HARDWARE_ADDRESS_LENGTH) - 1 downto 0);
	signal SenderHardwareAddress_d				: T_SLVV_8(HARDWARE_ADDRESS_LENGTH - 1 downto 0)								:= (others => (others => '0'));

--	signal SenderIPv4Address_Data_rst			: STD_LOGIC;
	signal SenderProtocolAddress_en				: std_logic;
	signal SenderProtocolAddress_us				: unsigned(log2ceilnz(PROTOCOL_ADDRESS_LENGTH) - 1 downto 0);
	signal SenderProtocolAddress_d				: T_SLVV_8(PROTOCOL_ADDRESS_LENGTH - 1 downto 0)								:= (others => (others => '0'));

--	signal TargetIPv4Address_Data_rst			: STD_LOGIC;
	signal TargetProtocolAddress_en				: std_logic;
	signal TargetProtocolAddress_us				: unsigned(log2ceilnz(PROTOCOL_ADDRESS_LENGTH) - 1 downto 0);
	signal TargetProtocolAddress_d				: T_SLVV_8(PROTOCOL_ADDRESS_LENGTH - 1 downto 0)								:= (others => (others => '0'));

begin
	assert (ALLOWED_PROTOCOL_IPV4 or ALLOWED_PROTOCOL_IPV6) report "At least one protocol must be selected: IPv4, IPv6" severity FAILURE;

	RX_Meta_rst									<= '0';
	RX_Meta_SrcMACAddress_nxt		<= '0';
	RX_Meta_DestMACAddress_nxt	<= '0';

	Is_SOF		<= RX_Valid and RX_SOF;
	Is_EOF		<= RX_Valid and RX_EOF;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State			<= ST_IDLE;
			else
				State			<= NextState;
				Operation <= NextOperation;
			end if;
		end if;
	end process;

	process(State,
					Command, Operation,
					RX_Valid, RX_Data, Is_SOF, Is_EOF,
					IsIPv4_r, IsIPv6_r, Writer_Counter_us,
					Address_rst,
					SenderMACAddress_nxt, SenderIPAddress_nxt, TargetIPAddress_nxt)
	begin
		NextState											<= State;
		NextOperation									<= Operation;

		Status												<= NET_ARP_RECEIVER_STATUS_IDLE;

		RX_Ack												<= '0';

		IsIPv4_set										<= '0';
		IsIPv6_set										<= '0';

		Writer_Counter_rst						<= '0';
		Writer_Counter_en							<= '0';

		Reader_SenderMAC_Counter_rst	<= to_sl(Command = NET_ARP_RECEIVER_CMD_CLEAR) or Address_rst;
		Reader_SenderMAC_Counter_en		<= SenderMACAddress_nxt;
		SenderHardwareAddress_en			<= '0';
		SenderHardwareAddress_us			<= Writer_Counter_us(SenderHardwareAddress_us'range);

		Reader_SenderIP_Counter_rst		<= to_sl(Command = NET_ARP_RECEIVER_CMD_CLEAR) or Address_rst;
		Reader_SenderIP_Counter_en		<= SenderIPAddress_nxt;
		SenderProtocolAddress_en			<= '0';
		SenderProtocolAddress_us			<= Writer_Counter_us(SenderProtocolAddress_us'range);

		Reader_TargetIP_Counter_rst		<= to_sl(Command = NET_ARP_RECEIVER_CMD_CLEAR) or Address_rst;
		Reader_TargetIP_Counter_en		<= TargetIPAddress_nxt;
		TargetProtocolAddress_en			<= '0';
		TargetProtocolAddress_us			<= Writer_Counter_us(TargetProtocolAddress_us'range);

		case State is
			when ST_IDLE =>
				if (Is_SOF = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if (RX_Data = x"00") then
							NextState		<= ST_RECEIVE_HARDWARE_type_1;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_HARDWARE_type_1 =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if (RX_Data = x"01") then
							NextState		<= ST_RECEIVE_PROTOCOL_type_0;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_PROTOCOL_type_0 =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if ((ALLOWED_PROTOCOL_IPV4 = TRUE) and (RX_Data = x"08")) then
							IsIPv4_set	<= '1';
							NextState		<= ST_RECEIVE_PROTOCOL_type_1;
						elsif ((ALLOWED_PROTOCOL_IPV6 = TRUE) and (RX_Data = x"86")) then
							IsIPv6_set	<= '1';
							NextState		<= ST_RECEIVE_PROTOCOL_type_1;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_PROTOCOL_type_1 =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if ((IsIPv4_r = '1') and (RX_Data = x"00")) then
							NextState		<= ST_RECEIVE_HARDWARE_ADDRESS_LENGTH;
						elsif ((IsIPv6_r = '1') and (RX_Data = x"66")) then
							NextState		<= ST_RECEIVE_HARDWARE_ADDRESS_LENGTH;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_HARDWARE_ADDRESS_LENGTH =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if (RX_Data = x"06") then
							NextState		<= ST_RECEIVE_PROTOCOL_ADDRESS_LENGTH;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_PROTOCOL_ADDRESS_LENGTH =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if ((IsIPv4_r = '1') and (RX_Data = x"04")) then
							NextState		<= ST_RECEIVE_OPERATION_0;
						elsif ((IsIPv6_r = '1') and (RX_Data = x"10")) then
							NextState		<= ST_RECEIVE_OPERATION_0;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_OPERATION_0 =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if (RX_Data = x"00") then
							NextState		<= ST_RECEIVE_OPERATION_1;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState		<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_OPERATION_1 =>
				if (RX_Valid = '1') then
					RX_Ack					<= '1';

					if (Is_EOF = '0') then
						if (RX_Data = x"01") then
							NextState		  <= ST_RECEIVE_SENDER_MAC;
							NextOperation	<= OP_REQUEST;
						elsif (RX_Data = x"02") then
							NextState		  <= ST_RECEIVE_SENDER_MAC;
							NextOperation	<= OP_ANSWER;
						else
							NextState		<= ST_DISCARD_FRAME;
						end if;
					else
						NextState			<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_SENDER_MAC =>
				if (RX_Valid = '1') then
					RX_Ack										<= '1';
					Writer_Counter_en					<= '1';
					SenderHardwareAddress_en	<= '1';

					if (Is_EOF = '0') then
						if (Writer_Counter_us = (HARDWARE_ADDRESS_LENGTH - 1)) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_RECEIVE_SENDER_IP;
						end if;
					else
						NextState								<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_SENDER_IP =>
				if (RX_Valid = '1') then
					RX_Ack										<= '1';
					Writer_Counter_en					<= '1';
					SenderProtocolAddress_en	<= '1';

					if (Is_EOF = '0') then
						if ((IsIPv4_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV4_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_RECEIVE_TARGET_MAC;
						elsif ((IsIPv6_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV6_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_RECEIVE_TARGET_MAC;
						end if;
					else
						NextState								<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TARGET_MAC =>
				if (RX_Valid = '1') then
					RX_Ack										<= '1';
					Writer_Counter_en					<= '1';			-- needed to count incoming bytes

					if (Is_EOF = '0') then
						if (RX_Data = x"00") then
							if (Writer_Counter_us = (HARDWARE_ADDRESS_LENGTH - 1)) then
								Writer_Counter_rst	<= '1';
								NextState						<= ST_RECEIVE_TARGET_IP;
							end if;
						else
							NextState							<= ST_DISCARD_FRAME;
						end if;
					else
						NextState								<= ST_ERROR;
					end if;
				end if;

			when ST_RECEIVE_TARGET_IP =>
				if (RX_Valid = '1') then
					RX_Ack										<= '1';
					Writer_Counter_en					<= '1';
					TargetProtocolAddress_en	<= '1';

					if (Is_EOF = '0') then
						if ((IsIPv4_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV4_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_DISCARD_ETHERNET_PADDING_BYTES;
						elsif ((IsIPv6_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV6_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_DISCARD_ETHERNET_PADDING_BYTES;
						end if;
					else
						if ((IsIPv4_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV4_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_COMPLETE;
						elsif ((IsIPv6_r = '1') and (Writer_Counter_us = (PROTOCOL_IPV6_ADDRESS_LENGTH - 1))) then
							Writer_Counter_rst		<= '1';
							NextState							<= ST_COMPLETE;
						else
							NextState							<= ST_ERROR;
						end if;
					end if;
				end if;

			when ST_DISCARD_ETHERNET_PADDING_BYTES =>
				RX_Ack											<= '1';

				if (Is_EOF = '1') then
					NextState									<= ST_COMPLETE;
				end if;

			when ST_COMPLETE =>
				if (Operation = OP_REQUEST) then
					Status                    <= NET_ARP_RECEIVER_STATUS_RequestReceived;
				elsif (Operation = OP_ANSWER) then
					Status                    <= NET_ARP_RECEIVER_STATUS_AnswerReceived;
				end if;

				if (Command = NET_ARP_RECEIVER_CMD_CLEAR) then
					NextState									<= ST_IDLE;
				end if;

			when ST_DISCARD_FRAME =>
				RX_Ack											<= '1';

				if (Is_EOF = '1') then
					NextState									<= ST_ERROR;
				end if;

			when ST_ERROR =>
				Status											<= NET_ARP_RECEIVER_STATUS_ERROR;

				if (Command = NET_ARP_RECEIVER_CMD_CLEAR) then
					NextState									<= ST_IDLE;
				end if;

		end case;
	end process;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset = '1') or (Command = NET_ARP_RECEIVER_CMD_CLEAR)) then
				IsIPv4_r			<= '0';
				IsIPv6_r			<= '0';
			else
				if (IsIPv4_set = '1') then
					IsIPv4_r		<= '1';
				end if;

				if (IsIPv6_set = '1') then
					IsIPv6_r		<= '1';
				end if;
			end if;
		end if;
	end process;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Writer_Counter_rst = '1') then
				Writer_Counter_us								<= (others => '0');
			elsif (Writer_Counter_en = '1') then
				Writer_Counter_us								<= Writer_Counter_us + 1;
			end if;

			if (Reader_SenderMAC_Counter_rst = '1') then
				Reader_SenderMAC_Counter_us			<= (others => '0');
			elsif (Reader_SenderMAC_Counter_en = '1') then
				Reader_SenderMAC_Counter_us			<= Reader_SenderMAC_Counter_us + 1;
			end if;

			if (Reader_SenderIP_Counter_rst = '1') then
				Reader_SenderIP_Counter_us			<= (others => '0');
			elsif (Reader_SenderIP_Counter_en = '1') then
				Reader_SenderIP_Counter_us			<= Reader_SenderIP_Counter_us + 1;
			end if;

			if (Reader_TargetIP_Counter_rst = '1') then
				Reader_TargetIP_Counter_us			<= (others => '0');
			elsif (Reader_TargetIP_Counter_en = '1') then
				Reader_TargetIP_Counter_us			<= Reader_TargetIP_Counter_us + 1;
			end if;
		end if;
	end process;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if (SenderHardwareAddress_en = '1') then
				SenderHardwareAddress_d(to_integer(SenderHardwareAddress_us))		<= RX_Data;
			end if;

			if (SenderProtocolAddress_en = '1') then
				SenderProtocolAddress_d(to_integer(SenderProtocolAddress_us))		<= RX_Data;
			end if;

			if (TargetProtocolAddress_en = '1') then
				TargetProtocolAddress_d(to_integer(TargetProtocolAddress_us))		<= RX_Data;
			end if;
		end if;
	end process;

	SenderMACAddress_Data				<= SenderHardwareAddress_d(ite((not SIMULATION), to_integer(Reader_SenderMAC_Counter_us), imin(to_integer(Reader_SenderMAC_Counter_us), 5)));
	SenderIPAddress_Data				<= SenderProtocolAddress_d(ite((not SIMULATION), to_integer(Reader_SenderIP_Counter_us), imin(to_integer(Reader_SenderIP_Counter_us), 3)));
	TargetIPAddress_Data				<= TargetProtocolAddress_d(ite((not SIMULATION), to_integer(Reader_TargetIP_Counter_us), imin(to_integer(Reader_TargetIP_Counter_us), 3)));

end architecture;
