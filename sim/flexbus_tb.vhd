library ieee;
use ieee.std_logic_1164.all;

entity flexbus_tb is
end entity flexbus_tb;

architecture sim of flexbus_tb is
    -- clocks
    signal clk_main             : std_logic := '0';

    -- FlexBus signals
    signal fb_ad                : std_logic_vector(31 downto 0);
    signal fb_ale,
           fb_burst_n           : std_logic;
    signal fb_cs_n              : std_logic_vector(3 downto 1);
    signal fb_size              : std_logic_vector(1 downto 0);
    signal fb_oe_n,
           fb_wr_n,
           fb_ta_n,

           dack0_n,
           dack1_n,
           dreq1_n,
           master_n,
           tout0_n,

           led_fpga_ok          : std_logic;
    
    signal pll_locked           : boolean := false;

    constant MAIN_CLOCK_PERIOD  : time := 30.03 ns;
begin
    process(clk_main)
    begin
        clk_main <= not clk_main after MAIN_CLOCK_PERIOD;
    end process;

    flexbus_sm : block
        constant TSZ_BYTE           : std_logic_vector := "01";
        constant TSZ_WORD           : std_logic_vector := "10";
        constant TSZ_LONG           : std_logic_vector := "00";
        constant TSZ_LINE           : std_logic_vector := "11";

        constant RWN_READ           : std_logic := '1';
        constant RWN_WRITE          : std_logic := '0';

        type flexbus_state_type is (S_WAIT, S0, S1, S2, S3);
        signal flexbus_state       : flexbus_state_type := S_WAIT;

        -- FlexBus stimulation vector type definition
        subtype desc_type is string(1 to 32);
        type fb_record_type is record
            address                 : std_logic_vector(31 downto 0);
            data                    : std_logic_vector(31 downto 0);
            fb_cs_n                 : std_logic_vector(3 downto 1);
            fb_size                 : std_logic_vector(1 downto 0);
            rw_n                    : std_logic;
            desc                    : desc_type;
        end record;
        type fb_sim_records_type is array(natural range <>) of fb_record_type;

        -- the actual stimulation data
        constant fb_stim_data        : fb_sim_records_type :=
        (
            (
                address => x"f0000400", data => x"00000000", fb_cs_n => "101",
                fb_size => TSZ_LONG, rw_n => RWN_READ, desc => "READ FBEE VIDEO CONFIG REGISTER "
            ),
            -- initialize DDR RAM
            -- this is a direct transliteration from what BaS and BaS_gcc is doing on startup
            (
                address => x"f0000400", data => x"000B0000", fb_cs_n => "101",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "CKE=1, CS=1, CONFIG=1           "
            ),
            -- need to wait for power up, the DDR model takes 2 µS, the real thing more like 200 µS
            (
                address => x"f0000400", data => x"00000000", fb_cs_n => "101",
                fb_size => TSZ_LONG, rw_n => RWN_READ, desc => "READ FBEE VIDEO CONFIG REGISTER "
            ),
            (
                address => x"f0000400", data => x"00000000", fb_cs_n => "101",
                fb_size => TSZ_LONG, rw_n => RWN_READ, desc => "READ FBEE VIDEO CONFIG REGISTER "
            ),
            (
                address => x"60000000", data => x"00050400", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "IPALL                           "
            ),
            (
                address => x"60000000", data => x"00072000", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "load EMR PLL ON                 "
            ),
            (
                address => x"60000000", data => x"00070122", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "load MR RESET PLL CL=2 BURST=41w"
            ),
            (
                address => x"60000000", data => x"00050400", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "IPALL                           "
            ),
            (
                address => x"60000000", data => x"00060000", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "auto refresh                    "
            ),
            (
                address => x"60000000", data => x"00060000", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "auto refresh                    "
            ),
            (
                address => x"60000000", data => x"00070022", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "load MR DLL ON                  "
            ),
            (
                address => x"f0000400", data => x"01070082", fb_cs_n => "101",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "fifo on refresh on ddrcs on cke "
            ),
            -- write something to DDR RAM
            (
                address => x"60000000", data => x"01020304", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "write test vector to DDR RAM    "
            ),
            (
                address => x"60000004", data => x"05060708", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "write test vector to DDR RAM    "
            ),
            -- read it back
            (
                address => x"60000000", data => x"00000000", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_READ, desc => "read value back from 1st address"
            ),
            (
                address => x"60000004", data => x"00000000", fb_cs_n => "111",
                fb_size => TSZ_LONG, rw_n => RWN_WRITE, desc => "read value back from 2nd address"
            )
        );
        signal stim_index           : natural := 0;

        signal address              : std_logic_vector(31 downto 0);
        signal desc                 : desc_type := (others => ' ');
    begin

        flexbus_sm : process
            variable cs_n   : std_logic_vector(3 downto 1);
            variable rw_n   : std_logic;
            variable rdata,
                     wdata  : std_logic_vector(31 downto 0);
            variable sz     : std_logic_vector(1 downto 0);
            variable stop   : boolean := false;
        begin
            wait until rising_edge(clk_main);

            rw_n := fb_stim_data(stim_index).rw_n;
            cs_n := fb_stim_data(stim_index).fb_cs_n;
            wdata := fb_stim_data(stim_index).data;
            sz := fb_stim_data(stim_index).fb_size;

            case flexbus_state is
                when S0 =>
                    desc <= fb_stim_data(stim_index).desc;
                    fb_ale <= '0';
                    fb_cs_n <= cs_n;
                    fb_size <= sz;
                    if rw_n = '0' then              -- write cycle
                         fb_ad <= wdata;
                    else                            -- read cycle
                        -- TODO: tristate only those bits that are actually used
                        fb_ad <= (others => 'Z');
                        fb_oe_n <= '0';
                    end if;
                    flexbus_state <= S1;

                when S1 =>
                    if fb_ta_n = '0' then
                        if rw_n = '1' then          -- read cycle
                            rdata := fb_ad;
                        end if;
                        fb_oe_n <= '1';
                        flexbus_state <= S2;
                    end if;

                when S2 =>
                    if rw_n = '1' then
                        assert false report desc & "= " & to_hstring(rdata) severity note;
                    else
                        assert false report desc & " " & to_hstring(wdata) severity note;
                    end if;
                    flexbus_state <= S3;
                    fb_cs_n <= "111";

                    -- increment index into stimulation vector
                    if stim_index < fb_stim_data'high then
                        stim_index <= stim_index + 1;
                    else
                        stop := true;
                    end if;

                when S3 =>
                    -- prepare for S0 state
                    fb_ad <= fb_stim_data(stim_index).address;
                    fb_wr_n <= fb_stim_data(stim_index).rw_n;
                    fb_ale <= '1';
                    if stop then
                        report "Stimulation vector exhausted. Simulation stop" severity note;
                        std.env.stop(0);
                    end if;
                    flexbus_state <= S0;

                when S_WAIT =>
                    -- stay in S_WAIT until PLL is ready
                    if pll_locked then
                        fb_ad <= fb_stim_data(stim_index).address;
                        fb_wr_n <= rw_n;
                        fb_ale <= '1';
                        flexbus_state <= S0;
                    end if;
            end case;
        end process flexbus_sm;
    end block flexbus_sm;

    -- we need to know when the uut is ready for action. This requires the PLLs to
    -- be locked and everything initialized. Since we can't see from the
    -- outside when this is finished, we just wait for the DDR clock to
    -- start ticking and add a few additional wait cycles

    catch_pll_start : process
        constant WAIT_COUNT : integer := 5;
        variable counter    : integer range 0 to WAIT_COUNT := 0;
    begin
        -- VHDL 2008 can reference external names. Nice!
        wait until rising_edge(<< signal fb.clk66 : std_ulogic >>);
        if counter < WAIT_COUNT then
            counter := counter + 1;
        else
            pll_locked <= true;
        end if;
    end process catch_pll_start;

    -- implement uut
    fb : entity work.firebee
        port map
        (
            CLK_MAIN        => clk_main,

            FB_AD           => fb_ad,
            FB_ALE          => fb_ale,
            FB_TBSTn        => fb_burst_n,
            FB_CSn          => fb_cs_n,
            FB_SIZE         => fb_size,
            FB_OEn          => fb_oe_n,
            FB_WRn          => fb_wr_n,
            FB_TAn          => fb_ta_n
        );

end architecture sim;

