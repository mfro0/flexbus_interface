library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.firebee_package.all;

entity firebee is
    generic
    (
        BUS_MEMBERS : natural := 3
    );
    port
    (
        CLK_MAIN    : in std_ulogic;

        FB_CSn      : in std_ulogic_vector(5 downto 0);         -- FlexBus has 6 chip selects
        FB_AD       : inout std_logic_vector(31 downto 0);
        FB_ALE      : in std_ulogic;
        FB_OEn      : in std_ulogic := '1';
        FB_WRn      : in std_ulogic;
        FB_TBSTn    : in std_ulogic;
        FB_SIZE     : in std_ulogic_vector(1 downto 0);
        FB_TAn      : out std_ulogic
    );
end entity firebee;

architecture arch of firebee is
    signal clk          : std_ulogic;           -- 264 MHz main clk
    signal fb_i         : work.firebee_package.flexbus_in_type;
    signal fb_os        : work.firebee_package.flexbus_os_type(0 downto 0);
begin

    --
    -- The FireBee's ColdFire runs on a 33 MHz clock. In order to suitably use the speed
    -- of the FireBee's DDR2 memory, we create a 264 MHz clock (8 x the base clock rate)
    -- and drive all FPGA logic with it. Required slower rates are achieved using suitable clock enables.
    --
    i_pll : entity work.flexbus_pll
        port map
        (
            inclk0      => CLK_MAIN,
            c0          => clk
        );

    --
    -- The FlexBus bus multiplexer that drives the FPGA side of the FlexBus
    -- and handles the different modules' response back to the bus.
    --
    i_flexbus_multiplexer : entity work.flexbus_multiplexer
        generic map
        (
            BUS_MEMBERS => BUS_MEMBERS
        )
        port map
        (
            clk         => clk,
            FB_AD       => FB_AD,
            FB_ALE      => FB_ALE,
            FB_TAn      => FB_TAn,
            FB_CSn      => FB_CSn,
            FB_OEn      => FB_OEn,
            FB_WRn      => FB_WRn,
            fb_os       => fb_os,
            fb_i        => fb_i
        );
    
    i_flexbus_interface : entity work.flexbus_interface
        port map
        (
            clk         => clk,
            fb_i        => fb_i,
            fb_o        => fb_os(0)
        );
end architecture arch;
