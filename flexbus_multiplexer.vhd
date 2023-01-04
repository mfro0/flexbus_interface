library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- multiplex register outputs

entity flexbus_multiplexer is
    generic
    (
        BUS_MEMBERS : natural
    );
    port
    (
        clk         : in std_ulogic;
        FB_ALE      : in std_ulogic;
        FB_AD       : inout std_logic_vector(31 downto 0);
        FB_TAn      : out std_ulogic;
        FB_CSn      : in std_ulogic_vector(5 downto 0);
        FB_OEn      : in std_ulogic;
        FB_WRn      : in std_ulogic;
        fb_i        : out work.firebee_package.flexbus_in_type;
        fb_os       : in work.firebee_package.flexbus_os_type
    );
end entity flexbus_multiplexer;

architecture rtl of flexbus_multiplexer is    
    signal state        : work.firebee_package.flexbus_state_type;
    
    signal address      : std_logic_vector(31 downto 0);
    signal data         : std_logic_vector(31 downto 0);
    signal tbst_n       : std_ulogic;
    signal size         : std_ulogic_vector(1 downto 0);

begin
    fb_i <= work.firebee_package.fb_in(state, FB_CSn, address, data, FB_OEn, FB_WRn, tbst_n, size);
    
    p_latch_address : process(all)
    begin
        if rising_edge(clk) then
            if FB_ALE = '1' then    -- latch address
                address <= FB_AD;
            elsif FB_WRn = '0' then
                data <= FB_AD;
            end if;
        end if;
    end process p_latch_address;
    
    p_register_multiplexer : process(all)
    begin
        if rising_edge(clk) then
            FB_AD <= (others => 'Z');           -- tristate FB_AD as default
            FB_TAn <= '1';                      -- and do not acknowledge anything until we need to
            for i in fb_os'range loop
                if fb_os(i).ta_n = '0' then
                    if FB_OEn = '1' then
                        work.firebee_package.fb_out(fb_os(i), FB_AD, FB_TAn);
                    end if;
                end if;
            end loop;
        end if;
    end process p_register_multiplexer;
end architecture rtl; -- of flexbus_multiplexer