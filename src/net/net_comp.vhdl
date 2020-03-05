-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	TODO
--
-- Authors:				 	Patrick Lehmann
-- 
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
--										 Chair for VLSI-Design, Diagnostics and Architecture
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
-- ============================================================================

LIBRARY IEEE;
USE			IEEE.STD_LOGIC_1164.ALL;
USE			IEEE.NUMERIC_STD.ALL;

LIBRARY PoC;
USE			PoC.config.ALL;
USE			PoC.utils.ALL;
USE			PoC.vectors.ALL;
USE			PoC.physical.ALL;
USE			PoC.io.ALL;
USE			PoC.net.ALL;


PACKAGE net_comp IS
	-- ==========================================================================================================================================================
	-- Ethernet: reconcilation sublayer (RS)
	-- ==========================================================================================================================================================
	COMPONENT eth_RSLayer_GMII_GMII_Xilinx is
	port (
		Reset_async								: in		std_logic;			-- @async:
		
		-- RS-GMII interface
		RS_TX_Clock								: in		std_logic;
		RS_TX_Valid								: in		std_logic;
		RS_TX_Data								: in		T_SLV_8;
		RS_TX_Error								: in		std_logic;
		
		RS_RX_Clock								: in		std_logic;
		RS_RX_Valid								: out		std_logic;
		RS_RX_Data								: out		T_SLV_8;
		RS_RX_Error								: out		std_logic;
		
		-- PHY-GMII interface
		PHY_Interface							: inout	T_NET_ETH_PHY_INTERFACE_GMII
	);
	END COMPONENT;

	COMPONENT Eth_RSLayer_GMII_SGMII_Virtex5 IS
		GENERIC (
			CLOCK_IN_FREQ							: FREQ													:= 125.0 MHz					-- 125 MHz
		);
		PORT (
			Clock											: IN	STD_LOGIC;
			Reset											: IN	STD_LOGIC;
			
			-- GEMAC-GMII interface
			RS_TX_Clock								: IN	STD_LOGIC;
			RS_TX_Valid								: IN	STD_LOGIC;
			RS_TX_Data								: IN	T_SLV_8;
			RS_TX_Error								: IN	STD_LOGIC;
			
			RS_RX_Clock								: IN	STD_LOGIC;
			RS_RX_Valid								: OUT	STD_LOGIC;
			RS_RX_Data								: OUT	T_SLV_8;
			RS_RX_Error								: OUT	STD_LOGIC;
			
			-- PHY-SGMII interface		
			PHY_Interface							: INOUT	T_NET_ETH_PHY_INTERFACE_SGMII
		);
	END COMPONENT;

	COMPONENT Eth_RSLayer_GMII_SGMII_Virtex6 IS
		GENERIC (
			CLOCK_IN_FREQ							: FREQ													:= 125.0 MHz					-- 125 MHz
		);
		PORT (
			Clock											: IN	STD_LOGIC;
			Reset											: IN	STD_LOGIC;
			
			-- GEMAC-GMII interface
			RS_TX_Clock								: IN	STD_LOGIC;
			RS_TX_Valid								: IN	STD_LOGIC;
			RS_TX_Data								: IN	T_SLV_8;
			RS_TX_Error								: IN	STD_LOGIC;
			
			RS_RX_Clock								: IN	STD_LOGIC;
			RS_RX_Valid								: OUT	STD_LOGIC;
			RS_RX_Data								: OUT	T_SLV_8;
			RS_RX_Error								: OUT	STD_LOGIC;
			
			-- PHY-SGMII interface		
			PHY_Interface							: INOUT	T_NET_ETH_PHY_INTERFACE_SGMII
		);
	END COMPONENT;

	COMPONENT Eth_RSLayer_GMII_SGMII_Series7 IS
		GENERIC (
			CLOCK_IN_FREQ							: FREQ													:= 125.0 MHz					-- 125 MHz
		);
		PORT (
			Clock											: IN	STD_LOGIC;
			Reset											: IN	STD_LOGIC;
			
			-- GEMAC-GMII interface
			RS_TX_Clock								: IN	STD_LOGIC;
			RS_TX_Valid								: IN	STD_LOGIC;
			RS_TX_Data								: IN	T_SLV_8;
			RS_TX_Error								: IN	STD_LOGIC;
			
			RS_RX_Clock								: IN	STD_LOGIC;
			RS_RX_Valid								: OUT	STD_LOGIC;
			RS_RX_Data								: OUT	T_SLV_8;
			RS_RX_Error								: OUT	STD_LOGIC;
			
			-- PHY-SGMII interface		
			PHY_Interface							: INOUT	T_NET_ETH_PHY_INTERFACES
		);
	END COMPONENT;

	COMPONENT eth_GMII_SGMII_PCS_Series7
  PORT (
		--Control
    reset : IN STD_LOGIC;
    resetdone : OUT STD_LOGIC;
		
    status_vector : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    configuration_vector : IN STD_LOGIC_VECTOR(4 DOWNTO 0);
    speed_is_10_100 : IN STD_LOGIC;
    speed_is_100 : IN STD_LOGIC;
    signal_detect : IN STD_LOGIC;
		
		--CLK s
    gtrefclk_bufg : IN STD_LOGIC;
    gtrefclk : IN STD_LOGIC;
		
    gt0_qplloutclk_in : IN STD_LOGIC;
    gt0_qplloutrefclk_in : IN STD_LOGIC;
		
    independent_clock_bufg : IN STD_LOGIC;
		
    mmcm_locked : IN STD_LOGIC;
    mmcm_reset : OUT STD_LOGIC;
		
    txoutclk : OUT STD_LOGIC;
    rxoutclk : OUT STD_LOGIC;
		
    cplllock : OUT STD_LOGIC;
		
    pma_reset : IN STD_LOGIC;
		
    userclk : IN STD_LOGIC;
    userclk2 : IN STD_LOGIC;
		
    rxuserclk : IN STD_LOGIC;
    rxuserclk2 : IN STD_LOGIC;
		
    sgmii_clk_r : OUT STD_LOGIC;
    sgmii_clk_f : OUT STD_LOGIC;
    sgmii_clk_en : OUT STD_LOGIC;
		
		--SGMII PHY Interface
    txn : OUT STD_LOGIC;
    txp : OUT STD_LOGIC;
    rxn : IN STD_LOGIC;
    rxp : IN STD_LOGIC;
		
		--GMII Interface
    gmii_txd : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_tx_en : IN STD_LOGIC;
    gmii_tx_er : IN STD_LOGIC;
    gmii_rxd : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    gmii_rx_dv : OUT STD_LOGIC;
    gmii_rx_er : OUT STD_LOGIC;
    gmii_isolate : OUT STD_LOGIC
  );
END COMPONENT;

	COMPONENT eth_GMII_SGMII_PCS_Series7_transceiver is
	generic
	(
			EXAMPLE_SIMULATION                      : integer   := 0          -- Set to 1 for simulation
	);
		 port (
				mmcm_reset          : out   std_logic;
				recclk_mmcm_reset   : out   std_logic;
				data_valid          : in    std_logic;
				independent_clock   : in    std_logic;
				encommaalign        : in    std_logic;
				powerdown           : in    std_logic;
				usrclk              : in    std_logic;
				usrclk2             : in    std_logic;
				rxusrclk              : in    std_logic;
				rxusrclk2             : in    std_logic;
				txreset             : in    std_logic;
				txdata              : in    std_logic_vector (7 downto 0);
				txchardispmode      : in    std_logic;
				txchardispval       : in    std_logic;
				txcharisk           : in    std_logic;
				rxreset             : in    std_logic;
				rxchariscomma       : out   std_logic;
				rxcharisk           : out   std_logic;
				rxclkcorcnt         : out   std_logic_vector (2 downto 0);
				rxdata              : out   std_logic_vector (7 downto 0);
				rxdisperr           : out   std_logic;
				rxnotintable        : out   std_logic;
				rxrundisp           : out   std_logic;
				rxbuferr            : out   std_logic;
				txbuferr            : out   std_logic;
				plllkdet            : out   std_logic;
				txoutclk            : out   std_logic;
				rxoutclk            : out   std_logic;
				txn                 : out   std_logic;
				txp                 : out   std_logic;
				rxn                 : in    std_logic;
				rxp                 : in    std_logic;
				gtrefclk            : in    std_logic;
				gtrefclk_bufg       : in    std_logic;
			 
				pmareset            : in    std_logic;
				mmcm_locked         : in    std_logic;
				resetdone           : out   std_logic;
					gt0_rxbyteisaligned_out   : out std_logic;
					gt0_rxbyterealign_out     : out std_logic;
					gt0_rxcommadet_out        : out std_logic;
					gt0_txpolarity_in         : in  std_logic;
					gt0_txdiffctrl_in         : in  std_logic_vector(3 downto 0);
					gt0_txinhibit_in          : in  std_logic;
					gt0_txpostcursor_in       : in  std_logic_vector(4 downto 0);
					gt0_txprecursor_in        : in  std_logic_vector(4 downto 0);
					gt0_rxpolarity_in         : in  std_logic;
					gt0_rxdfelpmreset_in      : in  std_logic;
					gt0_rxdfeagcovrden_in     : in  std_logic;
					gt0_rxlpmen_in            : in  std_logic;
					gt0_txprbssel_in          : in  std_logic_vector(2 downto 0);
					gt0_txprbsforceerr_in     : in  std_logic;
					gt0_rxprbscntreset_in     : in  std_logic;
					gt0_rxprbserr_out         : out std_logic;
					gt0_rxprbssel_in          : in  std_logic_vector(2 downto 0);
					gt0_loopback_in           : in  std_logic_vector(2 downto 0);
					gt0_txresetdone_out       : out std_logic;
					gt0_rxresetdone_out       : out std_logic;
					gt0_eyescanreset_in       : in  std_logic;
					gt0_eyescandataerror_out  : out std_logic;
					gt0_eyescantrigger_in     : in  std_logic;
					gt0_rxcdrhold_in          : in  std_logic;
					gt0_rxmonitorout_out      : out std_logic_vector(6 downto 0);
					gt0_rxmonitorsel_in       : in  std_logic_vector(1 downto 0);
					gt0_drpaddr_in            : in  std_logic_vector(8 downto 0);
					gt0_drpclk_in             : in  std_logic;
					gt0_drpdi_in              : in  std_logic_vector(15 downto 0);
					gt0_drpdo_out             : out std_logic_vector(15 downto 0);
					gt0_drpen_in              : in  std_logic;
					gt0_drprdy_out            : out std_logic;
					gt0_drpwe_in              : in  std_logic;  
					gt0_txpmareset_in         : in  std_logic;
					gt0_txpcsreset_in         : in  std_logic;
					gt0_rxpmareset_in         : in  std_logic;
					gt0_rxpcsreset_in         : in  std_logic;
					gt0_rxbufreset_in         : in  std_logic;
					gt0_rxbufstatus_out       : out std_logic_vector(2 downto 0);
					gt0_txbufstatus_out       : out std_logic_vector(1 downto 0);
					gt0_dmonitorout_out       : out std_logic_vector(7 downto 0);        
					gt0_qplloutclk            : in  std_logic;
					gt0_qplloutrefclk         : in  std_logic
		 );
	end component;
 -----------------------------------------------------------------------------
   -- Component Declaration for the 1000BASE-X PCS/PMA sublayer core.
   -----------------------------------------------------------------------------
	COMPONENT Eth_PCS_IPCore_Virtex7
		PORT (
			-- Core <=> Transceiver Interface
			------------------------------
			mgt_rx_reset         : out std_logic;                    -- Transceiver connection: reset for the receiver half of the Transceiver
			mgt_tx_reset         : out std_logic;                    -- Transceiver connection: reset for the transmitter half of the Transceiver
			userclk              : in std_logic;                     -- Routed to TXUSERCLK and RXUSERCLK of Transceiver.
			userclk2             : in std_logic;                     -- Routed to TXUSERCLK2 and RXUSERCLK2 of Transceiver.
			dcm_locked           : in std_logic;                     -- LOCKED signal from DCM.

			rxbufstatus          : in std_logic_vector (1 downto 0); -- Transceiver connection: Elastic Buffer Status.
			rxchariscomma        : in std_logic;                     -- Transceiver connection: Comma detected in RXDATA.
			rxcharisk            : in std_logic;                     -- Transceiver connection: K character received (or extra data bit) in RXDATA.
			rxclkcorcnt          : in std_logic_vector(2 downto 0);  -- Transceiver connection: Indicates clock correction.
			rxdata               : in std_logic_vector(7 downto 0);  -- Transceiver connection: Data after 8B/10B decoding.
			rxdisperr            : in std_logic;                     -- Transceiver connection: Disparity-error in RXDATA.
			rxnotintable         : in std_logic;                     -- Transceiver connection: Non-existent 8B/10 code indicated.
			rxrundisp            : in std_logic;                     -- Transceiver connection: Running Disparity of RXDATA (or extra data bit).
			txbuferr             : in std_logic;                     -- Transceiver connection: TX Buffer error (overflow or underflow).

			powerdown            : out std_logic;                    -- Transceiver connection: Powerdown the Transceiver
			txchardispmode       : out std_logic;                    -- Transceiver connection: Set running disparity for current byte.
			txchardispval        : out std_logic;                    -- Transceiver connection: Set running disparity value.
			txcharisk            : out std_logic;                    -- Transceiver connection: K character transmitted in TXDATA.
			txdata               : out std_logic_vector(7 downto 0); -- Transceiver connection: Data for 8B/10B encoding.
			enablealign          : out std_logic;                    -- Allow the transceivers to serially realign to a comma character.

			-- GMII Interface
			-----------------
			gmii_txd             : in std_logic_vector(7 downto 0);  -- Transmit data from client MAC.
			gmii_tx_en           : in std_logic;                     -- Transmit control signal from client MAC.
			gmii_tx_er           : in std_logic;                     -- Transmit control signal from client MAC.
			gmii_rxd             : out std_logic_vector(7 downto 0); -- Received Data to client MAC.
			gmii_rx_dv           : out std_logic;                    -- Received control signal to client MAC.
			gmii_rx_er           : out std_logic;                    -- Received control signal to client MAC.
			gmii_isolate         : out std_logic;                    -- Tristate control to electrically isolate GMII.

			-- Management: MDIO Interface
			-----------------------------
			mdc                  : in    std_logic;                  -- Management Data Clock
			mdio_in              : in    std_logic;                  -- Management Data In
			mdio_out             : out   std_logic;                  -- Management Data Out
			mdio_tri             : out   std_logic;                  -- Management Data Tristate
			phyad                : in std_logic_vector(4 downto 0);  -- Port address to for MDIO to recognise.
			configuration_vector : in std_logic_vector(4 downto 0);  -- Alternative to MDIO interface.
			configuration_valid  : in std_logic;                     -- Validation signal for Config vector.

			an_interrupt         : out std_logic;                    -- Interrupt to processor to signal that Auto-Negotiation has completed
			an_adv_config_vector : in std_logic_vector(15 downto 0); -- Alternate interface to program REG4 (AN ADV)
			an_adv_config_val    : in std_logic;                     -- Validation signal for AN ADV
			an_restart_config    : in std_logic;                     -- Alternate signal to modify AN restart bit in REG0
			link_timer_value     : in std_logic_vector(8 downto 0);  -- Programmable Auto-Negotiation Link Timer Control

			-- General IO's
			---------------
			status_vector        : out std_logic_vector(15 downto 0); -- Core status.
			reset                : in std_logic;                     -- Asynchronous reset for entire core.
			signal_detect        : in std_logic                      -- Input from PMD to indicate presence of optical input.
		);
	END COMPONENT;

	-- ==========================================================================================================================================================
	-- Ethernet: MAC Control-Layer
	-- ==========================================================================================================================================================
	COMPONENT Eth_Wrapper_Virtex5 IS
		GENERIC (
			DEBUG											: BOOLEAN														:= FALSE;															-- 
			CLOCKIN_FREQ							: FREQ															:= 125.0 MHz;													-- 125 MHz
			ETHERNET_IPSTYLE					: T_IPSTYLE													:= IPSTYLE_SOFT;											-- 
			RS_DATA_INTERFACE					: T_NET_ETH_RS_DATA_INTERFACE				:= NET_ETH_RS_DATA_INTERFACE_GMII;		-- 
			PHY_DATA_INTERFACE				: T_NET_ETH_PHY_DATA_INTERFACE			:= NET_ETH_PHY_DATA_INTERFACE_GMII		-- 
		);
		PORT (
			-- clock interface
			RS_TX_Clock								: IN	STD_LOGIC;
			RS_RX_Clock								: IN	STD_LOGIC;
			Eth_TX_Clock							: IN	STD_LOGIC;
			Eth_RX_Clock							: IN	STD_LOGIC;
			TX_Clock									: IN	STD_LOGIC;
			RX_Clock									: IN	STD_LOGIC;

			-- reset interface
			Reset											: IN	STD_LOGIC;
			
			-- Command-Status-Error interface
			
			-- MAC LocalLink interface
			TX_Valid									: IN	STD_LOGIC;
			TX_Data										: IN	T_SLV_8;
			TX_SOF										: IN	STD_LOGIC;
			TX_EOF										: IN	STD_LOGIC;
			TX_Ack										: OUT	STD_LOGIC;

			RX_Valid									: OUT	STD_LOGIC;
			RX_Data										: OUT	T_SLV_8;
			RX_SOF										: OUT	STD_LOGIC;
			RX_EOF										: OUT	STD_LOGIC;
			RX_Ack										: In	STD_LOGIC;
			
			-- PHY-SGMII interface
			PHY_Interface							:	INOUT	T_NET_ETH_PHY_INTERFACES
		);
	END COMPONENT;
	
	COMPONENT Eth_Wrapper_Virtex6 IS
		GENERIC (
			DEBUG											: BOOLEAN														:= FALSE;															-- 
			CLOCKIN_FREQ							: FREQ															:= 125.0 MHz;													-- 125 MHz
			ETHERNET_IPSTYLE					: T_IPSTYLE													:= IPSTYLE_SOFT;											-- 
			RS_DATA_INTERFACE					: T_NET_ETH_RS_DATA_INTERFACE				:= NET_ETH_RS_DATA_INTERFACE_GMII;		-- 
			PHY_DATA_INTERFACE				: T_NET_ETH_PHY_DATA_INTERFACE			:= NET_ETH_PHY_DATA_INTERFACE_GMII		-- 
		);
		PORT (
			-- clock interface
			RS_TX_Clock								: IN	STD_LOGIC;
			RS_RX_Clock								: IN	STD_LOGIC;
			Eth_TX_Clock							: IN	STD_LOGIC;
			Eth_RX_Clock							: IN	STD_LOGIC;
			TX_Clock									: IN	STD_LOGIC;
			RX_Clock									: IN	STD_LOGIC;
			
			-- reset interface
			Reset											: IN	STD_LOGIC;
			
			-- Command-Status-Error interface
			
			-- MAC LocalLink interface
			TX_Valid									: IN	STD_LOGIC;
			TX_Data										: IN	T_SLV_8;
			TX_SOF										: IN	STD_LOGIC;
			TX_EOF										: IN	STD_LOGIC;
			TX_Ack										: OUT	STD_LOGIC;

			RX_Valid									: OUT	STD_LOGIC;
			RX_Data										: OUT	T_SLV_8;
			RX_SOF										: OUT	STD_LOGIC;
			RX_EOF										: OUT	STD_LOGIC;
			RX_Ack										: In	STD_LOGIC;
			
			-- PHY-SGMII interface
			PHY_Interface							:	INOUT	T_NET_ETH_PHY_INTERFACES
		);
	END COMPONENT;
	
	COMPONENT eth_Wrapper_Series7 is
	generic (
		DEBUG											: boolean														:= FALSE;															--
--		CLOCK_FREQ_MHZ						: REAL															:= 125.0;															-- 125 MHz
		CLOCKIN_FREQ								: FREQ															:= 125.0 MHz;															-- 125 MHz
		ETHERNET_IPSTYLE					: T_IPSTYLE													:= IPSTYLE_SOFT;											--
		RS_DATA_INTERFACE					: T_NET_ETH_RS_DATA_INTERFACE				:= NET_ETH_RS_DATA_INTERFACE_GMII;		--
		PHY_DATA_INTERFACE				: T_NET_ETH_PHY_DATA_INTERFACE			:= NET_ETH_PHY_DATA_INTERFACE_GMII;		--
		IS_SIM										: boolean														:= FALSE
	);
	port (
		-- clock interface
		RS_TX_Clock								: in	std_logic;
		RS_RX_Clock								: in	std_logic;
		Eth_TX_Clock							: in	std_logic;
		Eth_RX_Clock							: in	std_logic;
		TX_Clock									: in	std_logic;
		RX_Clock									: in	std_logic;
		
		-- reset interface
		Reset											: in	std_logic;
		
		-- Command-Status-Error interface
		Core_Status								: out T_SLV_16;
		
		-- MAC LocalLink interface
		TX_Valid									: in	std_logic;
		TX_Data										: in	T_SLV_8;
		TX_SOF										: in	std_logic;
		TX_EOF										: in	std_logic;
		TX_Ack										: out	std_logic;
		
		RX_Valid									: out	std_logic;
		RX_Data										: out	T_SLV_8;
		RX_SOF										: out	std_logic;
		RX_EOF										: out	std_logic;
		RX_Ack										: in	std_logic;
		
		PHY_Interface							:	inout	T_NET_ETH_PHY_INTERFACES
	);
	END COMPONENT;
	
	-- ==========================================================================================================================================================
	-- Ethernet: MAC Data-Link-Layer
	-- ==========================================================================================================================================================
	COMPONENT TEMAC_GMII_Virtex5 IS
		PORT (
			-- Client Receiver Interface - EMAC0
			EMAC0CLIENTRXCLIENTCLKOUT       : out std_logic;
			CLIENTEMAC0RXCLIENTCLKIN        : in  std_logic;
			EMAC0CLIENTRXD                  : out std_logic_vector(7 downto 0);
			EMAC0CLIENTRXDVLD               : out std_logic;
			EMAC0CLIENTRXDVLDMSW            : out std_logic;
			EMAC0CLIENTRXGOODFRAME          : out std_logic;
			EMAC0CLIENTRXBADFRAME           : out std_logic;
			EMAC0CLIENTRXFRAMEDROP          : out std_logic;
			EMAC0CLIENTRXSTATS              : out std_logic_vector(6 downto 0);
			EMAC0CLIENTRXSTATSVLD           : out std_logic;
			EMAC0CLIENTRXSTATSBYTEVLD       : out std_logic;

			-- Client Transmitter Interface - EMAC0
			EMAC0CLIENTTXCLIENTCLKOUT       : out std_logic;
			CLIENTEMAC0TXCLIENTCLKIN        : in  std_logic;
			CLIENTEMAC0TXD                  : in  std_logic_vector(7 downto 0);
			CLIENTEMAC0TXDVLD               : in  std_logic;
			CLIENTEMAC0TXDVLDMSW            : in  std_logic;
			EMAC0CLIENTTXACK                : out std_logic;
			CLIENTEMAC0TXFIRSTBYTE          : in  std_logic;
			CLIENTEMAC0TXUNDERRUN           : in  std_logic;
			EMAC0CLIENTTXCOLLISION          : out std_logic;
			EMAC0CLIENTTXRETRANSMIT         : out std_logic;
			CLIENTEMAC0TXIFGDELAY           : in  std_logic_vector(7 downto 0);
			EMAC0CLIENTTXSTATS              : out std_logic;
			EMAC0CLIENTTXSTATSVLD           : out std_logic;
			EMAC0CLIENTTXSTATSBYTEVLD       : out std_logic;

			-- MAC Control Interface - EMAC0
			CLIENTEMAC0PAUSEREQ             : in  std_logic;
			CLIENTEMAC0PAUSEVAL             : in  std_logic_vector(15 downto 0);

			-- Clock Signal - EMAC0
			GTX_CLK_0                       : in  std_logic;
			PHYEMAC0TXGMIIMIICLKIN          : in  std_logic;
			EMAC0PHYTXGMIIMIICLKOUT         : out std_logic;

			-- GMII Interface - EMAC0
			GMII_TXD_0                      : out std_logic_vector(7 downto 0);
			GMII_TX_EN_0                    : out std_logic;
			GMII_TX_ER_0                    : out std_logic;
			GMII_RXD_0                      : in  std_logic_vector(7 downto 0);
			GMII_RX_DV_0                    : in  std_logic;
			GMII_RX_ER_0                    : in  std_logic;
			GMII_RX_CLK_0                   : in  std_logic;

			DCM_LOCKED_0                    : in  std_logic;

			-- Asynchronous Reset
			RESET                           : in  std_logic
		);
	END COMPONENT;

	-- ==========================================================================================================================================================
	-- Eth_Wrapper: configuration data structures
	-- ==========================================================================================================================================================
	
	-- ==========================================================================================================================================================
	-- local network: sequence and flow control protocol (SFC)
	-- ==========================================================================================================================================================
	
	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol Version 4 (IPv4)
	-- ==========================================================================================================================================================
	
	-- ==========================================================================================================================================================
	-- internet layer: Address Resolution Protocol (ARP)
	-- ==========================================================================================================================================================
	
END;

PACKAGE BODY net_comp IS
	
END PACKAGE BODY;