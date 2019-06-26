library IEEE;
use     IEEE.std_logic_1164.all;
use     IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;
use PoC.axi4.all;

entity AXI4Lite_Termination_Slave is
  Generic (
    VALUE         : std_logic := '0'
  );
  Port ( 
    AXI4Lite_M2S  : in   T_AXI4Lite_Bus_M2S;
    AXI4Lite_S2M  : out  T_AXI4Lite_Bus_S2M
  );
end entity;

architecture rtl of AXI4Lite_Termination_Slave is
  constant AddrBits : natural := AXI4Lite_M2S.AWAddr'length;
  constant DataBits : natural := AXI4Lite_M2S.WData'length;
begin

  AXI4Lite_S2M <= Initialize_AXI4Lite_Bus_S2M(AddrBits, DataBits, VALUE);

end architecture;
