library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fmf;
use fmf.all;

entity videl_test is
    generic
    (
        VERSION             : std_logic;

        -- generics that enable only part of the
        -- design. Useful for testing module by module
        -- without the need to synthesize  everything
        WITH_ACIA_KEYBOARD  : boolean := TRUE;
        WITH_ACIA_MIDI      : boolean := TRUE;
        WITH_BLITTER        : boolean := TRUE;
        WITH_DMA            : boolean := TRUE;
        WITH_DSP            : boolean := TRUE;
        WITH_IDE            : boolean := TRUE;
        WITH_SCSI           : boolean := TRUE;
        WITH_SOUND          : boolean := TRUE;
        WITH_FDC            : boolean := TRUE;
        WITH_RTC            : boolean := TRUE
    );
end entity videl_test;

architecture sim of videl_test is
    signal rsto_mcf_n       : std_logic;

    -- clocks
    signal clk_33m0_in      : std_logic;
    signal clk_main         : std_logic := '0';
    signal clk_24m576,
           clk_25m0,
           clk_ddr_out,
           clk_ddr_out_n,
           clk_usb          : std_logic;

    -- FlexBus signals
    signal fb_ad            : std_logic_vector(31 downto 0);
    signal fb_ale,
           fb_burst_n       : std_logic;
    signal fb_cs_n          : std_logic_vector(3 downto 1);
    signal fb_size          : std_logic_vector(1 downto 0);
    signal fb_oe_n,
           fb_wr_n,
           fb_ta_n,

           dack0_n,
           dack1_n,
           dreq1_n,
           master_n,
           tout0_n,

           led_fpga_ok      : std_logic;

    -- DDR memory control signals
    signal ba               : std_logic_vector(1 downto 0);
    signal va               : std_logic_vector(12 downto 0);
    signal vwe_n,
           vcas_n,
           vras_n,
           vcs_n,
           vcke             : std_logic;
    signal vdm              : std_logic_vector(3 downto 0);
    signal vd               : std_logic_vector(31 downto 0);
    signal vdqs             : std_logic_vector(3 downto 0);

    -- video signals
    signal clk_pixel,
           sync_n,
           vsync,
           hsync,
           blank_n          : std_logic;

    signal vr,
           vg,
           vb               : std_logic_vector(7 downto 0);

    signal pd_vga_n,
           pic_int,
           e0_int,
           dvi_int,
           pci_inta_n,
           pci_intb_n,
           pci_intc_n,
           pci_intd_n       : std_logic;
    signal irq_n            : std_logic_vector(7 downto 2);
    signal tin0,

    -- sound subsystem signals
           ym_qa,
           ym_qb,
           ym_qc            : std_logic;

    signal lp_d             : std_logic_vector(7 downto 0);
    signal lp_dir,
           lp_busy,
           lp_str,

           dsa_d,
           dtr,
           rts,
           cts,
           ri,
           dcd,
           rxd,
           txd,

           midi_in,
           midi_olr,
           midi_tlr,

           amkb_rx_pic,
           amkb_rx,
           amkb_tx,

           scsi_drq_n,
           scsi_msg_n,
           scsi_cd_n,
           scsi_io_n,
           scsi_ack_n,
           scsi_atn_n,
           scsi_sel_n,
           scsi_busy_n,
           scsi_rst_n,
           scsi_dir         : std_logic;

    signal scsi_d    : std_logic_vector(7 downto 0);

    signal scsi_par,

           acsi_dir         : std_logic;
    signal acsi_d           : std_logic_vector(7 downto 0);
    signal acsi_cs_n,
           acsi_a1,
           acsi_reset_n,
           acsi_ack_n,
           acsi_drq_n,
           acsi_int_n    : std_logic;

    -- Floppy Disk
    signal fdd_dchg_n,
           fdd_sdsel_n,
           fdd_hd_dd,
           fdd_rd_n,
           fdd_track00,
           fdd_index_n,
           fdd_wp_n,
           fdd_mot_on,
           fdd_wr_gate_n,
           fdd_wd_n,
           fdd_step_n,
           fdd_step_dir,

           rom4_n,
           rom3_n,

           rp_uds_n,
           rp_lds_n,

           sd_clk,
           sd_cmd_d1,
           sd_d3,
           sd_d0,
           sd_d1,
           sd_d2,
           sd_detect,
           sd_wp,

           cf_wp        : std_logic;
    signal cf_cs_n      : std_logic_vector(1 downto 0);

    signal dsp_io       : std_logic_vector(17 downto 0);
    signal dsp_srd      : std_logic_vector(15 downto 0);

    signal dsp_srcs_n,
           dsp_srble_n,
           dsp_srbhe_n,
           dsp_srwe_n,
           dsp_sroe_n,

           ide_int,
           ide_rdy,
           ide_res_n,
           ide_wr_n,
           ide_rd_n     : std_logic;
    signal ide_cs_n     : std_logic_vector(1 downto 0);

    signal io           : std_logic_vector(2 downto 0);

    signal pll_locked   : boolean := false;
begin
    process(clk_main)
    begin
        clk_main <= not clk_main after 30.03 ns;
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
        variable counter    : integer := 0;
        constant WAIT_COUNT : integer := 5;
    begin
        wait until rising_edge(clk_ddr_out);
        if counter < WAIT_COUNT then
            counter := counter + 1;
        else
            pll_locked <= true;
        end if;
    end process catch_pll_start;

    -- implement uut
    fb : entity work.firebee_top
        generic map
        (
            VERSION     => x"20200A00",

            WITH_ACIA_KEYBOARD  => WITH_ACIA_KEYBOARD,
            WITH_ACIA_MIDI      => WITH_ACIA_MIDI,
            WITH_BLITTER        => WITH_BLITTER,
            WITH_DMA            => WITH_DMA,
            WITH_DSP            => WITH_DSP,
            WITH_IDE            => WITH_IDE,
            WITH_SCSI           => WITH_SCSI,
            WITH_SOUND          => WITH_SOUND,
            WITH_FDC            => WITH_FDC,
            WITH_RTC            => WITH_RTC
        )
        port map
        (
            RSTO_MCFn       => rsto_mcf_n,
            CLK_33M0_IN     => clk_33m0_in,
            CLK_MAIN        => clk_main,
            CLK_24M576      => clk_24m576,
            CLK_25M0        => clk_25m0,
            CLK_DDR_OUT     => clk_ddr_out,
            CLK_DDR_OUTn    => clk_ddr_out_n,
            CLK_USB         => clk_usb,

            FB_AD           => fb_ad,
            FB_ALE          => fb_ale,
            FB_BURSTn       => fb_burst_n,
            FB_CSn          => fb_cs_n,
            FB_SIZE         => fb_size,
            FB_OEn          => fb_oe_n,
            FB_WRn          => fb_wr_n,
            FB_TAn          => fb_ta_n,

            DACK0n          => dack0_n,
            DACK1n          => dack1_n,
            DREQ1n          => dreq1_n,
            MASTERn         => master_n,
            TOUT0n          => tout0_n,
            LED_FPGA_OK     => led_fpga_ok,
            BA              => ba,
            VA              => va,
            VWEn            => vwe_n,
            VCASn           => vcas_n,
            VRASn           => vras_n,
            VCSn            => vcs_n,
            VCKE            => vcke,
            VDM             => vdm,
            VD              => vd,
            VDQS            => vdqs,
            CLK_PIXEL       => clk_pixel,
            SYNCn           => sync_n,
            VSYNC           => vsync,
            HSYNC           => hsync,
            BLANKn          => blank_n,
            VR              => vr,
            VG              => vg,
            VB              => vb,
            PD_VGAn         => pd_vga_n,
            PIC_INT         => pic_int,
            E0_INT          => e0_int,
            DVI_INT         => dvi_int,
            PCI_INTAn       => pci_inta_n,
            PCI_INTBn       => pci_intb_n,
            PCI_INTCn       => pci_intc_n,
            PCI_INTDn       => pci_intd_n,
            IRQn            => irq_n,
            TIN0            => tin0,
            YM_QA           => ym_qa,
            YM_QB           => ym_qb,
            YM_QC           => ym_qc,
            LP_D            => lp_d,
            LP_DIR          => lp_dir,
            LP_BUSY         => lp_busy,
            LP_STR          => lp_str,
            DSA_D           => dsa_d,
            DTR             => dtr,
            RTS             => rts,
            CTS             => cts,
            RI              => ri,
            DCD             => dcd,
            RxD             => rxd,
            TxD             => txd,
            MIDI_IN         => midi_in,
            MIDI_OLR        => midi_olr,
            MIDI_TLR        => midi_tlr,
            AMKB_Rx_PIC     => amkb_rx_pic,
            AMKB_Rx         => amkb_rx,
            AMKB_Tx         => amkb_tx,
            SCSI_DRQn       => scsi_drq_n,
            SCSI_MSGn       => scsi_msg_n,
            SCSI_CDn        => scsi_cd_n,
            SCSI_IOn        => scsi_io_n,
            SCSI_ACKn       => scsi_ack_n,
            SCSI_ATNn       => scsi_atn_n,
            SCSI_SELn       => scsi_sel_n,
            SCSI_BUSYn      => scsi_busy_n,
            SCSI_RSTn       => scsi_rst_n,
            SCSI_DIR        => scsi_dir,
            SCSI_D          => scsi_d,
            SCSI_PAR        => scsi_par,

            ACSI_DIR        => acsi_dir,
            ACSI_D          => acsi_d,
            ACSI_CSn        => acsi_cs_n,
            ACSI_A1         => acsi_a1,
            ACSI_RESETn     => acsi_reset_n,
            ACSI_ACKn       => acsi_ack_n,
            ACSI_DRQn       => acsi_drq_n,
            ACSI_INTn       => acsi_int_n,

            -- Floppy Disk
            FDD_DCHGn       => fdd_dchg_n,
            FDD_SDSELn      => fdd_sdsel_n,
            FDD_HD_DD       => fdd_hd_dd,
            FDD_RDn         => fdd_rd_n,
            FDD_TRACK00     => fdd_track00,
            FDD_INDEXn      => fdd_index_n,
            FDD_WPn         => fdd_wp_n,
            FDD_MOT_ON      => fdd_mot_on,
            FDD_WR_GATEn    => fdd_wr_gate_n,
            FDD_WDn         => fdd_wd_n,
            FDD_STEPn       => fdd_step_n,
            FDD_STEP_DIR    => fdd_step_dir,

            ROM4n           => rom4_n,
            ROM3n           => rom3_n,

            RP_UDSn         => rp_uds_n,
            RP_LDSn         => rp_lds_n,

            SD_CLK          => sd_clk,
            SD_CMD_D1       => sd_cmd_d1,
            SD_D3           => sd_d3,
            SD_D0           => sd_d0,
            SD_D1           => sd_d1,
            SD_D2           => sd_d2,
            SD_DETECT       => sd_detect,
            SD_WP           => sd_wp,

            CF_WP           => cf_wp,
            CF_CSn          => cf_cs_n,

            DSP_IO          => dsp_io,
            DSP_SRD         => dsp_srd,
            DSP_SRCSn       => dsp_srcs_n,
            DSP_SRBLEn      => dsp_srble_n,
            DSP_SRBHEn      => dsp_srbhe_n,
            DSP_SRWEn       => dsp_srwe_n,
            DSP_SROEn       => dsp_sroe_n,

            IDE_INT         => ide_int,
            IDE_RDY         => ide_rdy,
            IDE_RESn        => ide_res_n,
            IDE_WRn         => ide_wr_n,
            IDE_RDn         => ide_rd_n,
            IDE_CSn         => ide_cs_n,

            IO              => io
        );

    i_ddr : entity work.dual_ddr
        port map
        (
            clk             => clk_ddr_out,
            clk_n           => clk_ddr_out_n,
            ba              => ba,
            va              => va,
            vwe_n           => vwe_n,
            vcas_n          => vcas_n,
            vras_n          => vras_n,
            vcs_n           => vcs_n,
            vcke            => vcke,
            vdm             => vdm,
            vd              => vd,
            vdqs            => vdqs
        );
end architecture sim;

