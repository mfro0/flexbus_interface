library ieee;
use ieee.std_logic_1164.all;

use work.firebee_package.all;

entity flexbus_register is
    generic
    (
        REGISTER_ADDRESS    : std_logic_vector(31 downto 0);
        REGISTER_WIDTH      : natural
    );
    port
    (
        clk132              : in std_ulogic;
        i                   : in flexbus_in_type;
        o                   : out flexbus_out_type
    );
end entity flexbus_register;

architecture rtl of flexbus_register is
    signal contents         : std_logic_vector(REGISTER_WIDTH - 1 downto 0);
begin
    p_act : process
    begin
        wait until rising_edge(clk132);
        
        if i.address = REGISTER_ADDRESS then
            if i.rw_n = '0' then
                contents <= i.data_in(REGISTER_WIDTH - 1 downto 0);
            else
                o.data_out <= (others => '0');
                o.data_out(REGISTER_WIDTH - 1 downto 0) <= contents;
            end if;
            o.ta_n <= '0';
            -- synthesis translate_off
            -- report "register address match " & to_hstring(REGISTER_ADDRESS) & " = " & to_hstring(i.address) severity note;
            -- synthesis translate_on
        else
            o.ta_n <= '1';
        end if;
    end process p_act;
end architecture rtl;