library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flexbus_interface is
    generic
    (
        BUS_MEMBERS : natural := 10
    );
    port
    (
        clk         : in std_ulogic;
        fb_i        : in work.firebee_package.flexbus_in_type;
        fb_o        : out work.firebee_package.flexbus_out_type
    );
end entity flexbus_interface;

architecture rtl of flexbus_interface is
    signal fb_os    : work.firebee_package.flexbus_os_type(BUS_MEMBERS - 1 downto 0);
    signal i_fb_o   : work.firebee_package.flexbus_out_type;
begin
    gen_registers: for i in 0 to BUS_MEMBERS - 1 generate
        i_reg : entity work.flexbus_register
            generic map
            (
                REGISTER_ADDRESS => std_logic_vector(x"F0000400" + to_unsigned(i * 4, 32)),
                REGISTER_WIDTH => 32
            )
            port map
            (
                clk     => clk,
                i       => fb_i,
                o       => i_fb_o
            );
    end generate;
    i_drive : entity work.bus_driver
        generic map
        (
            BUS_MEMBERS     => BUS_MEMBERS
        )
        port map
        (
            clk             => clk,
            fb_i            => fb_i,
            fb_os           => FB_OS,
            fb_o            => fb_o
        );
    
end architecture rtl;

-------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bus_driver is
    generic
    (
        BUS_MEMBERS     : natural
    );
    port
    (
        clk     : in std_ulogic;
        fb_i    : in work.firebee_package.flexbus_in_type;
        fb_os   : in work.firebee_package.flexbus_os_type(BUS_MEMBERS - 1 downto 0);
        fb_o    : out work.firebee_package.flexbus_out_type
    );
end entity bus_driver;

architecture rtl of bus_driver is
begin
    p_drive_bus : process(all)
    begin
        if rising_edge(clk) then
            for i in 0 to BUS_MEMBERS - 1 loop
                if fb_i.oe_n = '0' then
                    if fb_os(i).ta_n = '0' then
                        fb_o <= fb_os(i);
                        exit;
                    end if;
                end if;
            end loop;
        end if;
    end process p_drive_bus;
end architecture rtl;