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
    function fb_in(state : flexbus_state_type; cs_n : std_ulogic_vector(3 downto 1);
                   address, data_in : std_logic_vector(31 downto 0);
                   oe_n, rw_n, tbst_n : std_ulogic;
                   size : std_ulogic_vector(1 downto 0)) return flexbus_in_type;
    
    -- fill in a flexbus_out_type record
    function fb_out(data_out : std_logic_vector(31 downto 0); ta_n : std_ulogic) return flexbus_out_type;
end package firebee_package;

package body firebee_package is
    function fb_in(state : flexbus_state_type; cs_n : std_ulogic_vector(3 downto 1);
                   address, data_in : std_logic_vector(31 downto 0);
                   oe_n, rw_n, tbst_n : std_ulogic;
                   size : std_ulogic_vector(1 downto 0)) return flexbus_in_type is
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
        
        return fb;
    end function fb_in;
    
    function fb_out(data_out : std_logic_vector(31 downto 0); ta_n : std_ulogic) return flexbus_out_type is
        variable fb : flexbus_out_type;
    begin
        fb.data_out := data_out;
        fb.ta_n := ta_n;
        
        return fb;
    end function fb_out;
end package body firebee_package;