library ieee;
use ieee.std_logic_1164.all;

package firebee_package is
    type flexbus_state_type is (S0, S1, S2, S3);
    subtype small_int_type is integer range 0 to 7;

    type flexbus_in_type is record
        state       : flexbus_state_type;
        cs_n        : std_ulogic_vector(3 downto 1);
        address,
        data_in     : std_logic_vector(31 downto 0);
        oe_n,
        rw_n,
        tbst_n      : std_ulogic;
        size        : std_ulogic_vector(1 downto 0);
    end record flexbus_in_type;

    type flexbus_out_type is record
        data_out    : std_logic_vector(31 downto 0);
        ta_n        : std_ulogic;
    end record flexbus_out_type;

    -- fill in a flexbus_in_type record
    function fb_in(state        : flexbus_state_type;
                   cs_n         : std_ulogic_vector(3 downto 1);
                   address,
                   data_in      : std_logic_vector(31 downto 0);
                   oe_n,
                   rw_n,
                   tbst_n       : std_ulogic;
                   size         : std_ulogic_vector(1 downto 0)) return flexbus_in_type;

    -- segregate a flexbus_out_type record in its elements
    procedure fb_out(o : flexbus_out_type;
                     signal FB_AD  : inout std_logic_vector(31 downto 0);
                     signal FB_TAn : out std_ulogic);

end package firebee_package;

package body firebee_package is
    function fb_in(state        : flexbus_state_type;
                   cs_n         : std_ulogic_vector(3 downto 1);
                   address,
                   data_in      : std_logic_vector(31 downto 0);
                   oe_n,
                   rw_n,
                   tbst_n       : std_ulogic;
                   size         : std_ulogic_vector(1 downto 0)) return flexbus_in_type is
        variable fb : flexbus_in_type;
    begin
        fb.state := state;
        fb.cs_n := cs_n;
        fb.address := address;
        fb.data_in := data_in;
        fb.oe_n := oe_n;
        fb.rw_n := rw_n;
        fb.tbst_n := tbst_n;
        fb.size := size;

        -- synthesis translate_off
        report "state = " & to_string(state) &
               " cs_n = " & to_string(cs_n) &
               " address = " & to_hstring(address) &
               " data_in = " & to_hstring(data_in) &
               " oe_n = " & to_string(oe_n) &
               " rw_n = " & to_string(rw_n) &
               " tbst_n = " & to_string(tbst_n) &
               " size = " & to_string(size) severity note;
        -- synthesis translate_on
        return fb;
    end function fb_in;

    procedure fb_out(o : flexbus_out_type;
                     signal FB_AD   : inout std_logic_vector(31 downto 0);
                     signal FB_TAn  : out std_ulogic) is
    begin
        FB_AD  <= o.data_out;
        FB_TAn <= o.ta_n;
        -- synthesis translate_off
        report "FB_AD <= " & to_hstring(o.data_out) severity note;
        report "FB_TAn <= " & to_string(o.ta_n) severity note;
        -- synthesis translate_on
    end procedure fb_out;
end package body firebee_package;
