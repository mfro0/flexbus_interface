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
            
        cs_n        : out std_ulogic_vector(3 downto 1);
        address     : out std_logic_vector(31 downto 0);
        data_in     : out std_logic_vector(31 downto 0);
        oe_n        : out std_ulogic;
        rw_n        : out std_ulogic;
        tbst_n      : out std_ulogic;
        size        : out std_ulogic_vector(1 downto 0);
        state       : out work.firebee_package.small_int_type
    );
end entity flexbus_interface;

architecture rtl of flexbus_interface is
    signal phase_counter    : work.firebee_package.small_int_type;
begin
    p_sync : process
        variable edge_detect    : std_ulogic_vector(1 downto 0);
    begin
        wait until rising_edge(clk66);
        
        edge_detect := edge_detect(0) & FB_ALE;
        if edge_detect = "01" then
            phase_counter <= 0;
        elsif phase_counter = 7 then
            phase_counter <= 0;
        else
            phase_counter <= phase_counter + 1;
        end if;
        
        if FB_ALE = '1' then
            address <= FB_AD;
        elsif FB_WRn = '0' then
            data_in <= FB_AD;
        end if;
        oe_n <= FB_OEn;
        rw_n <= FB_WRn;
        tbst_n <= FB_TBSTn;
        size <= FB_SIZE;
        cs_n <= FB_CSn;
    end process p_sync;
end architecture rtl;