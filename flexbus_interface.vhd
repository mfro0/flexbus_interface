library ieee;
use ieee.std_logic_1164.all;

entity flexbus_interface is
    port
    (
        clk66       : in std_ulogic;
        clk132      : in std_ulogic;
            
        FB_CSn      : in std_ulogic_vector(3 downto 1);
        FB_AD       : in std_logic_vector(31 downto 0);
        FB_ALE,
        FB_OEn,
        FB_WRn,
        FB_TBSTn    : in std_ulogic;
        FB_SIZE     : in std_ulogic_vector(1 downto 0);
        FB_TAn      : out std_ulogic;
            
        cs_n        : out std_ulogic_vector(3 downto 0);
        address     : out std_ulogic_vector(31 downto 0);
        data_in     : out std_ulogic_vector(31 downto 0);
        data_out    : in std_ulogic_vector(31 downto 0);
        oe_n        : out std_ulogic;
        rw_n        : out std_ulogic;
        tbst_n      : out std_ulogic;
        size        : out std_ulogic_vector(3 downto 1);
    );
end entity flexbus_interface;

architecture rtl of flexbus_interface is
begin
end architecture rtl;