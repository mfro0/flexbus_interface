library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity firebee is
    port
    (
        CLK_MAIN    : in std_ulogic;

        FB_CSn      : in std_ulogic_vector(3 downto 1);
        FB_AD       : inout std_logic_vector(31 downto 0);
        FB_ALE      : in std_ulogic;
        FB_OEn      : in std_ulogic;
        FB_WRn      : in std_ulogic;
        FB_TBSTn    : in std_ulogic;
        FB_SIZE     : in std_ulogic_vector(1 downto 0);
        FB_TAn      : out std_ulogic
    );
end entity firebee;

architecture arch of firebee is
    signal clk66,
           clk132       : std_ulogic;
    signal cs_n         : std_ulogic_vector(3 downto 1);
    signal address,
           data_in      : std_logic_vector(31 downto 0);
    signal oe_n,
           rw_n,
           tbst_n       : std_ulogic;
    signal size         : std_ulogic_vector(1 downto 0);

    signal fb_i         : work.firebee_package.flexbus_in_type;

    constant BUS_MEMBERS: integer := 10;

    type fb_os_type is array(0 to BUS_MEMBERS - 1) of work.firebee_package.flexbus_out_type;
    signal fb_o         : fb_os_type;

    signal state        : work.firebee_package.flexbus_state_type;
begin
    fb_i <= work.firebee_package.fb_in(state, cs_n, address, data_in, oe_n, rw_n, tbst_n, size);

    gen_registers: for i in 0 to BUS_MEMBERS - 1 generate
        i_reg : entity work.flexbus_register
            generic map
            (
                REGISTER_ADDRESS => std_logic_vector(x"FF00400" + to_unsigned(i * 4, 32)),
                REGISTER_WIDTH => 8
            )
            port map
            (
                clk132  => clk132,
                i       => fb_i,
                o       => fb_o(i)
            );
    end generate;

    -- multiplex register outputs
    p_register_multiplexer : process
    begin
        wait until rising_edge(clk132);
        FB_AD <= (others => 'Z');
        FB_TAn <= '1';
        for i in 0 to BUS_MEMBERS - 1 loop
            if fb_o(i).ta_n = '0' and oe_n = '0' then
                work.firebee_package.fb_out(fb_o(i), FB_AD, FB_TAn);
            end if;
        end loop;
    end process p_register_multiplexer;

    i_pll : entity work.flexbus_pll
        port map
        (
            inclk0      => CLK_MAIN,
            c0          => clk66,
            c1          => clk132
        );

    i_flexbus_interface : entity work.flexbus_interface
        port map
        (
            clk66       => clk66,
            clk132      => clk132,

            FB_CSn      => FB_CSn,
            FB_AD       => FB_AD,
            FB_ALE      => FB_ALE,
            FB_OEn      => FB_OEn,
            FB_WRn      => FB_WRn,
            FB_TBSTn    => FB_TBSTn,
            FB_SIZE     => FB_SIZE,
            -- FB_TAn      => FB_TAn,

            cs_n        => cs_n,
            address     => address,
            data_in     => data_in,
            oe_n        => oe_n,
            rw_n        => rw_n,
            tbst_n      => tbst_n,
            size        => size
        );
end architecture arch;
