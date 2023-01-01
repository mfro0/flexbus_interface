library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package firebee_package is
    type flexbus_state_type is (S0, S1, S2, S3);
    -- subtype int8_type is natural range 0 to 7;

    constant ADDRESS_LENGTH     : natural := 32;
    --
    -- from ColdFire bus into the FPGA
    --
    type flexbus_in_type is record
        state       : flexbus_state_type;
        cs_n        : std_ulogic_vector(5 downto 0);
        address,
        data        : std_logic_vector(31 downto 0);
        oe_n,
        wr_n,
        tbst_n      : std_ulogic;
        size        : std_ulogic_vector(1 downto 0);
    end record flexbus_in_type;

    --
    -- from FPGA to ColdFire
    --
    type flexbus_out_type is record
        data        : std_logic_vector(31 downto 0);
        ta_n        : std_ulogic;
    end record flexbus_out_type;
    type flexbus_os_type is array(natural range <>) of flexbus_out_type;

    -- fill in a flexbus_in_type record
    function fb_in(state        : flexbus_state_type;
                   cs_n         : std_ulogic_vector(3 downto 1);
                   address,
                   data         : std_logic_vector(31 downto 0);
                   oe_n,
                   wr_n,
                   tbst_n       : std_ulogic;
                   size         : std_ulogic_vector(1 downto 0)) return flexbus_in_type;

    -- segregate a flexbus_out_type record in its elements
    procedure fb_out(o : flexbus_out_type;
                     signal FB_AD  : inout std_logic_vector(31 downto 0);
                     signal FB_TAn : out std_ulogic);

    -- an address
    subtype address_type is unsigned(ADDRESS_LENGTH - 1 downto 0);
    subtype address_length_type is natural;
    --
    -- This record type describes an address range
    --
    type address_range_type is record
        start_address   : address_type;
        length          : address_length_type;
    end record address_range_type;
    
    type bus_slave_type is record
        cs              : natural flexbus_in_type'range;
        address_range   : address_range_type;
    end record bus_slave_type;
    
    type bus_slaves_type is array(natural range <>) of bus_slave_type;
    
end package firebee_package;

package body firebee_package is
    function fb_in(state        : flexbus_state_type;
                   cs_n         : std_ulogic_vector(flexbus_in_type.cs_n'reverse_range);
                   address,
                   data         : std_logic_vector(31 downto 0);
                   oe_n,
                   wr_n,
                   tbst_n       : std_ulogic;
                   size         : std_ulogic_vector(1 downto 0)) return flexbus_in_type is
        variable fb : flexbus_in_type;
    begin
        fb.state := state;
        fb.cs_n := cs_n;
        fb.address := address;
        fb.data := data;
        fb.oe_n := oe_n;
        fb.wr_n := wr_n;
        fb.tbst_n := tbst_n;
        fb.size := size;

        -- synthesis translate_off
        report "state = " & to_string(state) &
               " cs_n = " & to_string(cs_n) &
               " address = " & to_hstring(address) &
               " data = " & to_hstring(data) &
               " oe_n = " & to_string(oe_n) &
               " rw_n = " & to_string(rw_n) &
               " tbst_n = " & to_string(tbst_n) &
               " size = " & to_string(size) severity note;
        -- synthesis translate_on
        return fb;
    end function fb_in;

    procedure fb_out(o : flexbus_out_type;
                     signal FB_AD   : out std_logic_vector(31 downto 0);
                     signal FB_TAn  : out std_ulogic) is
    begin
        FB_AD  <= o.data;
        FB_TAn <= o.ta_n;
        -- synthesis translate_off
        report "FB_AD <= " & to_hstring(o.data) severity note;
        report "FB_TAn <= " & to_string(o.ta_n) severity note;
        -- synthesis translate_on
    end procedure fb_out;
end package body firebee_package;
