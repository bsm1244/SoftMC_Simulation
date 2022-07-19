`timescale 1ps / 1ps

`include "softMC.inc"

module tb_softMC_top;
	
  parameter REFCLK_FREQ           = 200;
                                    // # = 200 for all design frequencies of
                                    //         -1 speed grade devices
                                    //   = 200 when design frequency < 480 MHz
                                    //         for -2 and -3 speed grade devices.
                                    //   = 300 when design frequency >= 480 MHz
                                    //         for -2 and -3 speed grade devices.
  parameter SIM_BYPASS_INIT_CAL   = "FAST";
                                    // # = "OFF" -  Complete memory init &
                                    //              calibration sequence
                                    // # = "SKIP" - Skip memory init &
                                    //              calibration sequence
                                    // # = "FAST" - Skip memory init & use
                                    //              abbreviated calib sequence
  parameter RST_ACT_LOW           = 0;
                                    // =1 for active low reset,
                                    // =0 for active fhigh.
  parameter IODELAY_GRP           = "IODELAY_MIG";
                                    //to phy_top
  parameter nCK_PER_CLK           = 2;
                                    // # of memory CKs per fabric clock.
                                    // # = 2, 1.
  parameter nCS_PER_RANK          = 1;
                                    // # of unique CS outputs per Rank for
                                    // phy.
  parameter DQS_CNT_WIDTH         = 3;
                                    // # = ceil(log2(DQS_WIDTH)).
  parameter RANK_WIDTH            = 1;
                                    // # = ceil(log2(RANKS)).
  parameter BANK_WIDTH            = 3;
                                    // # of memory Bank Address bits.
  parameter CK_WIDTH              = 2;
                                    // # of CK/CK# outputs to memory.
  parameter CKE_WIDTH             = 1;
                                    // # of CKE outputs to memory.
  parameter COL_WIDTH             = 10;
                                    // # of memory Column Address bits.
  parameter CS_WIDTH              = 1;
                                    // # of unique CS outputs to memory.
  parameter DM_WIDTH              = 8;
                                    // # of Data Mask bits.
  parameter DQ_WIDTH              = 64;
                                    // # of Data (DQ) bits.
  parameter DQS_WIDTH             = 8;
                                    // # of DQS/DQS# bits.
  parameter ROW_WIDTH             = 15;
                                    // # of memory Row Address bits.
  parameter BURST_MODE            = "8";
                                    // Burst Length (Mode Register 0).
                                    // # = "8", "4", "OTF".
  parameter INPUT_CLK_TYPE        = "DIFFERENTIAL";
                                    // input clock type DIFFERENTIAL or SINGLE_ENDED
  parameter BM_CNT_WIDTH          = 2;
                                    // # = ceil(log2(nBANK_MACHS)).
  parameter ADDR_CMD_MODE         = "1T" ;
                                    // # = "2T", "1T".
  parameter ORDERING              = "STRICT";
                                    // # = "NORM", "STRICT".
  parameter RTT_NOM               = "60";
                                    // RTT_NOM (ODT) (Mode Register 1).
                                    // # = "DISABLED" - RTT_NOM disabled,
                                    //   = "120" - RZQ/2,
                                    //   = "60" - RZQ/4,
                                    //   = "40" - RZQ/6.
   parameter RTT_WR               = "OFF";
                                       // RTT_WR (ODT) (Mode Register 2).
                                       // # = "OFF" - Dynamic ODT off,
                                       //   = "120" - RZQ/2,
                                       //   = "60" - RZQ/4,
  parameter OUTPUT_DRV            = "HIGH";
                                    // Output Driver Impedance Control (Mode Register 1).
                                    // # = "HIGH" - RZQ/7,
                                    //   = "LOW" - RZQ/6.
  parameter REG_CTRL              = "OFF";
                                    // # = "ON" - RDIMMs,
                                    //   = "OFF" - Components, SODIMMs, UDIMMs.
  parameter CLKFBOUT_MULT_F       = 6;
                                    // write PLL VCO multiplier.
  parameter DIVCLK_DIVIDE         = 1;
                                    // write PLL VCO divisor.
  parameter CLKOUT_DIVIDE         = 3;
                                    // VCO output divisor for fast (memory) clocks.
  parameter tCK                   = 2500;
                                    // memory tCK paramter.
                                    // # = Clock Period.
  parameter DEBUG_PORT            = "OFF";
                                    // # = "ON" Enable debug signals/controls.
                                    //   = "OFF" Disable debug signals/controls.
  parameter tPRDI                   = 1_000_000;
                                    // memory tPRDI paramter.
  parameter tREFI                   = 7800000;
                                    // memory tREFI paramter.
  parameter tZQI                    = 128_000_000;
                                    // memory tZQI paramter.
  parameter ADDR_WIDTH              = 29;
                                    // # = RANK_WIDTH + BANK_WIDTH
                                    //     + ROW_WIDTH + COL_WIDTH;
  parameter STARVE_LIMIT            = 2;
                                    // # = 2,3,4.
  parameter TCQ                     = 100;
  parameter ECC                     = "OFF";
  parameter ECC_TEST                = "OFF";
  parameter DATA_WIDTH              = 64;
  parameter PAYLOAD_WIDTH           = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;


  //***********************************************************************//
  // Traffic Gen related parameters
  //***********************************************************************//
  parameter EYE_TEST                = "FALSE";
                                      // set EYE_TEST = "TRUE" to probe memory
                                      // signals. Traffic Generator will only
                                      // write to one single location and no
                                      // read transactions will be generated.

  parameter SIMULATION              = "TRUE";
  // PRBS_DATA_MODE can only be used together with either PRBS_ADDR or SEQUENTIAL_ADDR
  // FIXED_DATA_MODE is designed to work with FIXED_ADDR
  parameter ADDR_MODE               = 3;
                                      //FIXED_ADDR      = 2'b01;
                                      //PRBS_ADDR       = 2'b10;
                                      //SEQUENTIAL_ADDR = 2'b11;
  parameter DATA_MODE               = 2;  // To change simulation data pattern
                                      // FIXED_DATA_MODE       =    4'b0001;
                                      // ADDR_DATA_MODE        =    4'b0010;
                                      // HAMMER_DATA_MODE      =    4'b0011;
                                      // NEIGHBOR_DATA_MODE    =    4'b0100;
                                      // WALKING1_DATA_MODE    =    4'b0101;
                                      // WALKING0_DATA_MODE    =    4'b0110;
                                      // PRBS_DATA_MODE        =    4'b0111;
  parameter TST_MEM_INSTR_MODE      = "R_W_INSTR_MODE";
                                      // available instruction modes:
                                      //"FIXED_INSTR_R_MODE"
                                      // "FIXED_INSTR_W_MODE"
                                      // "R_W_INSTR_MODE"
  parameter DATA_PATTERN            = "DGEN_ALL";
                                      // DATA_PATTERN shoule be set to "DGEN_ALL"
                                      // unless it is targeted for S6 small device.
                                      // "DGEN_HAMMER", "DGEN_WALKING1",
                                      // "DGEN_WALKING0","DGEN_ADDR","
                                      // "DGEN_NEIGHBOR","DGEN_PRBS","DGEN_ALL"
  parameter CMD_PATTERN             = "CGEN_ALL";
                                      // CMD_PATTERN shoule be set to "CGEN_ALL"
                                      // unless it is targeted for S6 small device.
                                      // "CGEN_RPBS","CGEN_FIXED","CGEN_BRAM",
                                      // "CGEN_SEQUENTIAL", "CGEN_ALL"

  parameter BEGIN_ADDRESS           = 32'h00000000;
  parameter PRBS_SADDR_MASK_POS     = 32'h00000000;
  parameter END_ADDRESS             = 32'h000003ff;
  parameter PRBS_EADDR_MASK_POS     = 32'hfffffc00;
  parameter SEL_VICTIM_LINE         = 11;

  //**************************************************************************//
  // Local parameters Declarations
  //**************************************************************************//
  localparam real TPROP_DQS          = 0.00;  // Delay for DQS signal during Write Operation
  localparam real TPROP_DQS_RD       = 0.00;  // Delay for DQS signal during Read Operation
  localparam real TPROP_PCB_CTRL     = 0.00;  // Delay for Address and Ctrl signals
  localparam real TPROP_PCB_DATA     = 0.00;  // Delay for data signal during Write operation
  localparam real TPROP_PCB_DATA_RD  = 0.00;  // Delay for data signal during Read operation

  localparam MEMORY_WIDTH = 8;
  localparam NUM_COMP = DQ_WIDTH/MEMORY_WIDTH;
  localparam real CLK_PERIOD = tCK;
  localparam real REFCLK_PERIOD = (1000000.0/(2*REFCLK_FREQ));
  localparam DRAM_DEVICE = "SODIMM";
                         // DRAM_TYPE: "UDIMM", "RDIMM", "COMPS"

   // VT delay change options/settings
  localparam VT_ENABLE                  = "OFF";
                                        // Enable VT delay var's
  localparam VT_RATE                    = CLK_PERIOD/500;
                                        // Size of each VT step
  localparam VT_UPDATE_INTERVAL         = CLK_PERIOD*50;
                                        // Update interval
  localparam VT_MAX                     = CLK_PERIOD/40;
                                        // Maximum VT shift


  function integer STR_TO_INT;
    input [7:0] in;
    begin
      if(in == "8")
        STR_TO_INT = 8;
      else if(in == "4")
        STR_TO_INT = 4;
      else
        STR_TO_INT = 0;
    end
  endfunction

  localparam APP_DATA_WIDTH = PAYLOAD_WIDTH * 4;
  localparam APP_MASK_WIDTH = APP_DATA_WIDTH / 8;
  localparam BURST_LENGTH   = STR_TO_INT(BURST_MODE);


  //**************************************************************************//
  // Wire Declarations
  //**************************************************************************//
/*
  reg app_en;
  wire app_ack;
  reg[31:0] app_instr; 
  wire iq_full;
  wire processing_iseq;
*/

  //Data read back Interface
/*
  wire rdback_fifo_empty;
  reg rdback_fifo_rden;
  wire[255:0] rdback_data;
*/
  reg sys_clk;
  reg clk_ref;
  reg sys_rst_n;

  wire sys_clk_p;
  wire sys_clk_n;
  wire clk_ref_p;
  wire clk_ref_n;


  reg [DM_WIDTH-1:0]                 ddr3_dm_sdram_tmp;

  wire sys_rst;

  wire                               error;
  wire                               phy_init_done;
  wire                               ddr3_parity;
  wire                               ddr3_reset_n;
  wire                               sda;
  wire                               scl;

  wire [DQ_WIDTH-1:0]                ddr3_dq_fpga;
  wire [ROW_WIDTH-1:0]               ddr3_addr_fpga;
  wire [BANK_WIDTH-1:0]              ddr3_ba_fpga;
  wire                               ddr3_ras_n_fpga;
  wire                               ddr3_cas_n_fpga;
  wire                               ddr3_we_n_fpga;
  wire [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n_fpga;
  wire [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt_fpga;
  wire [CKE_WIDTH-1:0]               ddr3_cke_fpga;
  wire [DM_WIDTH-1:0]                ddr3_dm_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_fpga;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_fpga;
  wire [CK_WIDTH-1:0]                ddr3_ck_p_fpga;
  wire [CK_WIDTH-1:0]                ddr3_ck_n_fpga;

  wire [DQ_WIDTH-1:0]                ddr3_dq_sdram;
  reg [ROW_WIDTH-1:0]                ddr3_addr_sdram;
  reg [BANK_WIDTH-1:0]               ddr3_ba_sdram;
  reg                                ddr3_ras_n_sdram;
  reg                                ddr3_cas_n_sdram;
  reg                                ddr3_we_n_sdram;
  reg [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_cs_n_sdram;
  reg [(CS_WIDTH*nCS_PER_RANK)-1:0]  ddr3_odt_sdram;
  reg [CKE_WIDTH-1:0]                ddr3_cke_sdram;
  wire [DM_WIDTH-1:0]                ddr3_dm_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_p_sdram;
  wire [DQS_WIDTH-1:0]               ddr3_dqs_n_sdram;
  reg [CK_WIDTH-1:0]                 ddr3_ck_p_sdram;
  reg [CK_WIDTH-1:0]                 ddr3_ck_n_sdram;

  reg [ROW_WIDTH-1:0]               ddr3_addr_r;
  reg [BANK_WIDTH-1:0]              ddr3_ba_r;
  reg                               ddr3_ras_n_r;
  reg                               ddr3_cas_n_r;
  reg                               ddr3_we_n_r;
  reg [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n_r;
  reg [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt_r;
  reg [CKE_WIDTH-1:0]               ddr3_cke_r;

  //**************************************************************************//
  // Clock generation and reset
  //**************************************************************************//

  initial begin
    sys_clk   = 1'b0;
    clk_ref   = 1'b1;
    sys_rst_n = 1'b0;

    #120000
      sys_rst_n = 1'b1;
  end

   assign sys_rst = RST_ACT_LOW ? sys_rst_n : ~sys_rst_n;

  // Generate system clock = twice rate of CLK
  always
    sys_clk = #(CLK_PERIOD/2.0) ~sys_clk;

  // Generate IDELAYCTRL reference clock (200MHz)
  always
    clk_ref = #REFCLK_PERIOD ~clk_ref;

  assign sys_clk_p = sys_clk;
  assign sys_clk_n = ~sys_clk;

  assign clk_ref_p = clk_ref;
  assign clk_ref_n = ~clk_ref;


  //**************************************************************************//

  always @( * ) begin
    ddr3_ck_p_sdram   <=  #(TPROP_PCB_CTRL) ddr3_ck_p_fpga;
    ddr3_ck_n_sdram   <=  #(TPROP_PCB_CTRL) ddr3_ck_n_fpga;
    ddr3_addr_sdram   <=  #(TPROP_PCB_CTRL) ddr3_addr_fpga;
    ddr3_ba_sdram     <=  #(TPROP_PCB_CTRL) ddr3_ba_fpga;
    ddr3_ras_n_sdram  <=  #(TPROP_PCB_CTRL) ddr3_ras_n_fpga;
    ddr3_cas_n_sdram  <=  #(TPROP_PCB_CTRL) ddr3_cas_n_fpga;
    ddr3_we_n_sdram   <=  #(TPROP_PCB_CTRL) ddr3_we_n_fpga;
    ddr3_cs_n_sdram   <=  #(TPROP_PCB_CTRL) ddr3_cs_n_fpga;
    ddr3_cke_sdram    <=  #(TPROP_PCB_CTRL) ddr3_cke_fpga;
    ddr3_odt_sdram    <=  #(TPROP_PCB_CTRL) ddr3_odt_fpga;
    ddr3_dm_sdram_tmp <=  #(TPROP_PCB_DATA) ddr3_dm_fpga;//DM signal generation
  end

  assign ddr3_dm_sdram = {DM_WIDTH{1'b0}};

// Controlling the bi-directional BUS
  genvar dqwd;
  generate
    for (dqwd = 1;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
      WireDelay #
       (
        .Delay_g  (TPROP_PCB_DATA),
        .Delay_rd (TPROP_PCB_DATA_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dq
       (
        .A     (ddr3_dq_fpga[dqwd]),
        .B     (ddr3_dq_sdram[dqwd]),
        .reset (sys_rst_n),
        .phy_init_done (phy_init_done)
       );
     end
      WireDelay #
       (
        .Delay_g  (TPROP_PCB_DATA),
        .Delay_rd (TPROP_PCB_DATA_RD),
        .ERR_INSERT (ECC)
       )
      u_delay_dq_0
       (
        .A     (ddr3_dq_fpga[0]),
        .B     (ddr3_dq_sdram[0]),
        .reset (sys_rst_n),
        .phy_init_done (phy_init_done)
       );

  endgenerate

  genvar dqswd;
  generate
    for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
      WireDelay #
       (
        .Delay_g  (TPROP_DQS),
        .Delay_rd (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_p
       (
        .A     (ddr3_dqs_p_fpga[dqswd]),
        .B     (ddr3_dqs_p_sdram[dqswd]),
        .reset (sys_rst_n),
        .phy_init_done (phy_init_done)
       );

      WireDelay #
       (
        .Delay_g  (TPROP_DQS),
        .Delay_rd (TPROP_DQS_RD),
        .ERR_INSERT ("OFF")
       )
      u_delay_dqs_n
       (
        .A     (ddr3_dqs_n_fpga[dqswd]),
        .B     (ddr3_dqs_n_sdram[dqswd]),
        .reset (sys_rst_n),
        .phy_init_done (phy_init_done)
       );
    end
  endgenerate
  assign sda = 1'b1;
  assign scl = 1'b1;
  

   // Extra one clock pipelining for RDIMM address and
   // control signals is implemented here (Implemented external to memory model)
   always @( posedge ddr3_ck_p_sdram[0] ) begin
     if ( ddr3_reset_n == 1'b0 ) begin
       ddr3_ras_n_r <= 1'b1;
       ddr3_cas_n_r <= 1'b1;
       ddr3_we_n_r  <= 1'b1;
       ddr3_cs_n_r  <= {(CS_WIDTH*nCS_PER_RANK){1'b1}};
       ddr3_odt_r   <= 1'b0;
     end
     else begin
       ddr3_addr_r  <= #(CLK_PERIOD/2) ddr3_addr_sdram;
       ddr3_ba_r    <= #(CLK_PERIOD/2) ddr3_ba_sdram;
       ddr3_ras_n_r <= #(CLK_PERIOD/2) ddr3_ras_n_sdram;
       ddr3_cas_n_r <= #(CLK_PERIOD/2) ddr3_cas_n_sdram;
       ddr3_we_n_r  <= #(CLK_PERIOD/2) ddr3_we_n_sdram;
       if (~(ddr3_cs_n_sdram[0] | ddr3_cs_n_sdram[1]) & ~phy_init_done)
         ddr3_cs_n_r  <= #(CLK_PERIOD/2) {(CS_WIDTH*nCS_PER_RANK){1'b1}};
       else
         ddr3_cs_n_r  <= #(CLK_PERIOD/2) ddr3_cs_n_sdram;
       ddr3_odt_r   <= #(CLK_PERIOD/2) ddr3_odt_sdram;
     end
   end

   // to avoid tIS violations on CKE when reset is deasserted
   always @( posedge ddr3_ck_n_sdram[0] )
     if ( ddr3_reset_n == 1'b0 )
       ddr3_cke_r <= 1'b0;
     else
       ddr3_cke_r <= #(CLK_PERIOD) ddr3_cke_sdram;



  //***************************************************************************
  // Instantiate memories
  //***************************************************************************

  genvar r,i,dqs_x;
  generate
    for (r = 0; r < CS_WIDTH; r = r+1) begin: mem_rnk
      for (i = 0; i < NUM_COMP; i = i + 1) begin: gen_mem
        ddr3_model u_comp_ddr3
          (
           .rst_n   (ddr3_reset_n),
           .ck      (ddr3_ck_p_sdram[(i*MEMORY_WIDTH)/72]),
           .ck_n    (ddr3_ck_n_sdram[(i*MEMORY_WIDTH)/72]),
           .cke     (ddr3_cke_sdram[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
           .cs_n    (ddr3_cs_n_sdram[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)]),
           .ras_n   (ddr3_ras_n_sdram),
           .cas_n   (ddr3_cas_n_sdram),
           .we_n    (ddr3_we_n_sdram),
           .dm_tdqs (ddr3_dm_sdram[i]),
           .ba      (ddr3_ba_sdram),
           .addr    (ddr3_addr_sdram),
           .dq      (ddr3_dq_sdram[MEMORY_WIDTH*(i+1)-1:MEMORY_WIDTH*(i)]),
           .dqs     (ddr3_dqs_p_sdram[i]),
           .dqs_n   (ddr3_dqs_n_sdram[i]),
           .tdqs_n  (),
           .odt     (ddr3_odt_sdram[((i*MEMORY_WIDTH)/72)+(nCS_PER_RANK*r)])
           );
      end
    end
  endgenerate
	


////////////////////////////////////////// From SoftMC_top //////////////////////////////////////////

  parameter DRAM_TYPE       = "DDR3";  // Memory I/F type: "DDR3", "DDR2"

  // Slot Conifg parameters
  parameter [7:0] SLOT_0_CONFIG = 8'b0000_0001;
  parameter [7:0] SLOT_1_CONFIG = 8'b0000_0000;
  // DRAM bus widths
  parameter DQ_CNT_WIDTH    = 6;       // = ceil(log2(DQ_WIDTH))
  parameter DRAM_WIDTH      = 8;       // # of DQ per DQS
  parameter CAL_WIDTH       = "HALF";  // # of DRAM ranks to be calibrated
                                       // CAL_WIDTH = CS_WIDTH when "FULL"
                                       // CAL_WIDTH = CS_WIDTH/2 when "HALF"          
  // calibration Address. The address given below will be used for calibration
  // read and write operations. 
  parameter CALIB_ROW_ADD   = 16'h0000;// Calibration row address
  parameter CALIB_COL_ADD   = 12'h000; // Calibration column address
  parameter CALIB_BA_ADD    = 3'h0;    // Calibration bank address 
  // DRAM mode settings
  parameter AL              = "0";     // Additive Latency option
  parameter BURST_TYPE      = "SEQ";   // Burst type
  parameter nAL             = 0;       // Additive latency (in clk cyc)
  parameter nCL             = 5;       // Read CAS latency (in clk cyc)
  parameter nCWL            = 5;       // Write CAS latency (in clk cyc)
  parameter tRFC            = 110000;  // Refresh-to-command delay
  parameter WRLVL           = "ON";    // Enable write leveling
  // Phase Detector/Read Leveling options
  parameter PHASE_DETECT    = "ON";    // Enable read phase detector
  parameter PD_TAP_REQ      = 0;       // # of IODELAY taps reserved for PD
  parameter PD_MSB_SEL      = 8;       // # of bits in PD response cntr
  parameter PD_DQS0_ONLY    = "ON";    // Enable use of DQS[0] only for
                                       // phase detector
  parameter PD_LHC_WIDTH    = 16;      // sampling averaging cntr widths   
  parameter PD_CALIB_MODE   = "PARALLEL";  // parallel/seq PD calibration
  // IODELAY/BUFFER options
  parameter IBUF_LPWR_MODE  = "OFF";   // Input buffer low power mode
  parameter IODELAY_HP_MODE = "ON";    // IODELAY High Performance Mode
                                             // when mult IP cores in design
  // Pin-out related parameters
  parameter nDQS_COL0       = 3;  // # DQS groups in I/O column #1
  parameter nDQS_COL1       = 5;          // # DQS groups in I/O column #2
  parameter nDQS_COL2       = 0;          // # DQS groups in I/O column #3
  parameter nDQS_COL3       = 0;          // # DQS groups in I/O column #4
  parameter DQS_LOC_COL0    = 24'h020100;
                                          // DQS grps in col #1
  parameter DQS_LOC_COL1    = 40'h0706050403;          // DQS grps in col #2
  parameter DQS_LOC_COL2    = 0;          // DQS grps in col #3
  parameter DQS_LOC_COL3    = 0;          // DQS grps in col #4
  parameter USE_DM_PORT     = 0;          // DM instantation enable
  // Simulation /debug options
  parameter SIM_INIT_OPTION = "NONE"; // Skip various initialization steps
  parameter SIM_CAL_OPTION  = "NONE"; // Skip various calibration steps

	 
	 assign ddr_dm = {DM_WIDTH{1'b0}};
	 
	 /*** CLOCK MANAGEMENT ***/
	 
	 localparam SYSCLK_PERIOD = tCK * nCK_PER_CLK;
	 localparam MMCM_ADV_BANDWIDTH = "OPTIMIZED";
	 
	 wire clk_mem, clk, clk_rd_base;
	 //wire clk_ref = 0;
	 wire rst;
	 wire pd_PSDONE, pd_PSEN, pd_PSINCDEC; //phase detector interface
	 wire iodelay_ctrl_rdy;
	 wire mmcm_clk;
	 //wire sys_clk = 0;

	 //use 200MHZ refrence clock to generate mmcm_clk
	 iodelay_ctrl #
    (
     .TCQ            (TCQ),
     .IODELAY_GRP    (IODELAY_GRP),
     .INPUT_CLK_TYPE (INPUT_CLK_TYPE),
     .RST_ACT_LOW    (RST_ACT_LOW)
     )
    u_iodelay_ctrl
      (
       .clk_ref_p        (clk_ref_p), //input
       .clk_ref_n        (clk_ref_n), //input
       .clk_ref          (0), //input
       .sys_rst          (sys_rst), //input
		   .clk_200			     (mmcm_clk), //output
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy) //output
       );
		 
	 infrastructure #
    (
     .TCQ                (TCQ),
     .CLK_PERIOD         (SYSCLK_PERIOD),
     .nCK_PER_CLK        (nCK_PER_CLK),
     .MMCM_ADV_BANDWIDTH (MMCM_ADV_BANDWIDTH),
     .CLKFBOUT_MULT_F    (CLKFBOUT_MULT_F),
     .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
     .CLKOUT_DIVIDE      (CLKOUT_DIVIDE),
     .RST_ACT_LOW        (RST_ACT_LOW)
     )
    u_infrastructure
      (
       .clk_mem          (clk_mem), //output
       .clk              (clk), //output
       .clk_rd_base      (clk_rd_base), //output
       .rstdiv0          (rst), //output
		 
       .mmcm_clk         (mmcm_clk), //input
       .sys_rst          (sys_rst), //input
       .iodelay_ctrl_rdy (iodelay_ctrl_rdy), //input
       .PSDONE           (pd_PSDONE), //output
       .PSEN             (pd_PSEN), //input
       .PSINCDEC         (pd_PSINCDEC) //input
       );
		 
   wire [ROW_WIDTH-1:0]              dfi_address0;
   wire [ROW_WIDTH-1:0]              dfi_address1;
   wire [BANK_WIDTH-1:0]             dfi_bank0;
   wire [BANK_WIDTH-1:0]             dfi_bank1;
   wire 										 dfi_cas_n0;
   wire 										 dfi_cas_n1;
   wire [CKE_WIDTH-1:0]              dfi_cke0;
   wire [CKE_WIDTH-1:0]              dfi_cke1;
   wire [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_cs_n0;
   wire [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_cs_n1;
   wire [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_odt0;
   wire [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_odt1;
   wire                              dfi_ras_n0;
   wire                              dfi_ras_n1;
   wire                              dfi_reset_n;
	assign dfi_reset_n = 1;
   wire                              dfi_we_n0;
   wire                              dfi_we_n1;
   // DFI Write
   wire                              dfi_wrdata_en;
   wire [4*DQ_WIDTH-1:0]             dfi_wrdata;
   wire [4*(DQ_WIDTH/8)-1:0]         dfi_wrdata_mask;
   // DFI Read
   wire                              dfi_rddata_en;
	 wire                              dfi_rddata_en_even;
	 wire                              dfi_rddata_en_odd;
   wire [4*DQ_WIDTH-1:0]             dfi_rddata;
   wire                              dfi_rddata_valid;
   wire                              dfi_rddata_valid_even;
   wire                              dfi_rddata_valid_odd;

   // DFI Initialization Status / CLK Disable
   wire                              dfi_dram_clk_disable;
   // sideband signals
   wire                              io_config_strobe;
   wire [RANK_WIDTH:0]               io_config;
	 
	 //localparam CLK_PERIOD = tCK * nCK_PER_CLK;
	 phy_top  #(
     .TCQ                               (TCQ),
     .REFCLK_FREQ                       (REFCLK_FREQ),
     .nCS_PER_RANK                      (nCS_PER_RANK),
     .CAL_WIDTH                         (CAL_WIDTH),
     .CALIB_ROW_ADD                     (CALIB_ROW_ADD),
     .CALIB_COL_ADD                     (CALIB_COL_ADD),
     .CALIB_BA_ADD                      (CALIB_BA_ADD),
     .CS_WIDTH                          (CS_WIDTH),
     .nCK_PER_CLK                       (nCK_PER_CLK),
     .CKE_WIDTH                         (CKE_WIDTH),
     .DRAM_TYPE                         (DRAM_TYPE),
     .SLOT_0_CONFIG                     (SLOT_0_CONFIG),
     .SLOT_1_CONFIG                     (SLOT_1_CONFIG),
     //.CLK_PERIOD                        (CLK_PERIOD),
     .CLK_PERIOD                        (tCK * nCK_PER_CLK),
     .BANK_WIDTH                        (BANK_WIDTH),
     .CK_WIDTH                          (CK_WIDTH),
     .COL_WIDTH                         (COL_WIDTH),
     .DM_WIDTH                          (DM_WIDTH),
     .DQ_CNT_WIDTH                      (DQ_CNT_WIDTH),
     .DQ_WIDTH                          (DQ_WIDTH),
     .DQS_CNT_WIDTH                     (DQS_CNT_WIDTH),
     .DQS_WIDTH                         (DQS_WIDTH),
     .DRAM_WIDTH                        (DRAM_WIDTH),
     .ROW_WIDTH                         (ROW_WIDTH),
     .RANK_WIDTH                        (RANK_WIDTH),
     .AL                                (AL),
     .BURST_MODE                        (BURST_MODE),
     .BURST_TYPE                        (BURST_TYPE),
     .nAL                               (nAL),
     .nCL                               (nCL),
     .nCWL                              (nCWL),
     .tRFC                              (tRFC),
     .OUTPUT_DRV                        (OUTPUT_DRV),
     .REG_CTRL                          (REG_CTRL),
     .RTT_NOM                           (RTT_NOM),
     .RTT_WR                            (RTT_WR),
     .WRLVL                             (WRLVL),
     .PHASE_DETECT                      (PHASE_DETECT),
     .IODELAY_HP_MODE                   (IODELAY_HP_MODE),
     .IODELAY_GRP                       (IODELAY_GRP),
     // Prevent the following simulation-related parameters from
     // being overridden for synthesis - for synthesis only the
     // default values of these parameters should be used
     // synthesis translate_off
     .SIM_BYPASS_INIT_CAL               (SIM_BYPASS_INIT_CAL),
	   .SIM_INIT_OPTION(SIM_INIT_OPTION),
	   .SIM_CAL_OPTION(SIM_CAL_OPTION),
	  
     // synthesis translate_on
     .nDQS_COL0                         (nDQS_COL0),
     .nDQS_COL1                         (nDQS_COL1),
     .nDQS_COL2                         (nDQS_COL2),
     .nDQS_COL3                         (nDQS_COL3),
     .DQS_LOC_COL0                      (DQS_LOC_COL0),
     .DQS_LOC_COL1                      (DQS_LOC_COL1),
     .DQS_LOC_COL2                      (DQS_LOC_COL2),
     .DQS_LOC_COL3                      (DQS_LOC_COL3),
     .USE_DM_PORT                       (USE_DM_PORT),
     .DEBUG_PORT                        (DEBUG_PORT)
   ) xil_phy (
    .clk_mem(clk_mem), //input
    .clk(clk), //input
    .clk_rd_base(clk_rd_base), //input
    .rst(rst), //input
    .slot_0_present(SLOT_0_CONFIG), //input
    .slot_1_present(SLOT_1_CONFIG), //input
	 
    .dfi_address0(dfi_address0), //Note: '0' versions are used for row commands, '1' versions for column commands
    .dfi_address1(dfi_address1), 
    .dfi_bank0(dfi_bank0), 
    .dfi_bank1(dfi_bank1), 
    .dfi_cas_n0(dfi_cas_n0), 
    .dfi_cas_n1(dfi_cas_n1), 
    .dfi_cke0(dfi_cke0), 
    .dfi_cke1(dfi_cke1), 
    .dfi_cs_n0(dfi_cs_n0), 
    .dfi_cs_n1(dfi_cs_n1), 
    .dfi_odt0(dfi_odt0), 
    .dfi_odt1(dfi_odt1), 
    .dfi_ras_n0(dfi_ras_n0), 
    .dfi_ras_n1(dfi_ras_n1), 
    .dfi_reset_n(dfi_reset_n), 
    .dfi_we_n0(dfi_we_n0), 
    .dfi_we_n1(dfi_we_n1), 
    .dfi_wrdata_en(dfi_wrdata_en), 
    .dfi_wrdata(dfi_wrdata), 
    .dfi_wrdata_mask(dfi_wrdata_mask), 
    .dfi_rddata_en(dfi_rddata_en), 
	  .dfi_rddata_en_even(dfi_rddata_en_even),
	  .dfi_rddata_en_odd(dfi_rddata_en_odd),
    .dfi_rddata(dfi_rddata), 
    .dfi_rddata_valid(dfi_rddata_valid), 
	  .dfi_rddata_valid_even(dfi_rddata_valid_even),
    .dfi_rddata_valid_odd(dfi_rddata_valid_odd), 
    .dfi_dram_clk_disable(dfi_dram_clk_disable), 
    .dfi_init_complete(phy_init_done), 
	 
	 //sideband signals
    .io_config_strobe(io_config_strobe), //input
    .io_config(io_config), //input [RANK_WIDTH:0]
	 
	 //DRAM signals
    .ddr_ck_p(ddr3_ck_p_fpga), 
    .ddr_ck_n(ddr3_ck_n_fpga), 
    .ddr_addr(ddr3_addr_fpga), 
    .ddr_ba(ddr3_ba_fpga), 
    .ddr_ras_n(ddr3_ras_n_fpga), 
    .ddr_cas_n(ddr3_cas_n_fpga), 
    .ddr_we_n(ddr3_we_n_fpga), 
    .ddr_cs_n(ddr3_cs_n_fpga), 
    .ddr_cke(ddr3_cke_fpga), 
    .ddr_odt(ddr3_odt_fpga), 
    .ddr_reset_n(ddr3_reset_n_fpga), 
    //.ddr_parity(ddr_parity), 
    .ddr_dm(ddr_dm), 
    .ddr_dqs_p(ddr3_dqs_p_fpga), 
    .ddr_dqs_n(ddr3_dqs_n_fpga), 
    .ddr_dq(ddr3_dq_fpga), 
	 
	 //phase detection signals
    .pd_PSDONE(pd_PSDONE), 
    .pd_PSEN(pd_PSEN), 
    .pd_PSINCDEC(pd_PSINCDEC)
    );



//////////////////////////////////////// jhpark ////////////////////////////////////////

  //reg clk;
  //reg rst;

  reg periodic_read_lock;

  //There are two instructions queues to fetch from. Since PHY issues DDR commands at both pos and neg edges, 
  //we dispatch two instructions in the same cycle, running at half of the frequency of the DDR bus
  reg en_in0;
  wire en_ack0;
  reg[31:0] instr_in0;

  reg en_in1;
  wire en_ack1;
  reg[31:0] instr_in1;

  //DFI Interface
  // DFI Control/Address
  reg 											       dfi_ready;
  //wire [ROW_WIDTH-1:0]             dfi_address0;
  //wire [ROW_WIDTH-1:0]             dfi_address1;
  //wire [BANK_WIDTH-1:0]            dfi_bank0;
  //wire [BANK_WIDTH-1:0]            dfi_bank1;
  //wire									           dfi_cke0;
  //wire 									           dfi_cke1;
  //wire									           dfi_cas_n0;
  //wire										         dfi_cas_n1;
  //wire [CS_WIDTH*nCS_PER_RANK-1:0] dfi_cs_n0;
  //wire [CS_WIDTH*nCS_PER_RANK-1:0] dfi_cs_n1;
  //wire [CS_WIDTH*nCS_PER_RANK-1:0] dfi_odt0;
  //wire [CS_WIDTH*nCS_PER_RANK-1:0] dfi_odt1;
  //wire										         dfi_ras_n0;
  //wire										         dfi_ras_n1;
  //wire										         dfi_we_n0;
  //wire										         dfi_we_n1;
  // DFI Write
  //wire                             dfi_wrdata_en;
  //wire [4*DQ_WIDTH-1:0]            dfi_wrdata;
  //wire [4*(DQ_WIDTH/8)-1:0]        dfi_wrdata_mask;
  // DFI Read
  //wire                             dfi_rddata_en;
  //wire										         dfi_rddata_en_even;
  //wire 										         dfi_rddata_en_odd;

  //Bus Command
  //wire io_config_strobe;
  //wire [1:0] io_config;

  //Misc.
  //wire pr_rd_ack;

  //auto-refresh
  wire        aref_set_interval;
  wire [27:0] aref_interval; 
  wire        aref_set_trfc;
  wire [27:0] aref_trfc;


  //***************************************************************************
  // Instantiate the Unit Under Test (UUT)
  //***************************************************************************

  instr_dispatcher #
  (
    .ROW_WIDTH    ( 15 ),
    .BANK_WIDTH   ( 3  ),
    .CKE_WIDTH    ( 1  ),
    .RANK_WIDTH   ( 1  ),
    .CS_WIDTH     ( 1  ),
    .nCS_PER_RANK ( 1  ),
    .DQ_WIDTH     ( 64 )
  )
    uut
  (
    .clk                ( clk                ),
    .rst                ( rst                ),
    .periodic_read_lock ( periodic_read_lock ),
    .en_in0             ( en_in0             ),
    .en_ack0            ( en_ack0            ), 
    .instr_in0          ( instr_in0          ),
    .en_in1             ( en_in1             ),
    .en_ack1            ( en_ack1            ),
    .instr_in1          ( instr_in1          ),
	  // DFI Interface
	  // DFI Control/Address
    .dfi_ready          ( dfi_ready          ),
    .dfi_address0       ( dfi_address0       ),
    .dfi_address1       ( dfi_address1       ),
    .dfi_bank0          ( dfi_bank0          ),
    .dfi_bank1          ( dfi_bank1          ),
    .dfi_cke0           ( dfi_cke0           ),
    .dfi_cke1           ( dfi_cke1           ),
    .dfi_cas_n0         ( dfi_cas_n0         ),
    .dfi_cas_n1         ( dfi_cas_n1         ),
    .dfi_cs_n0          ( dfi_cs_n0          ),
    .dfi_cs_n1          ( dfi_cs_n1          ),
    .dfi_odt0           ( dfi_odt0           ),
    .dfi_odt1           ( dfi_odt1           ),
    .dfi_ras_n0         ( dfi_ras_n0         ),
    .dfi_ras_n1         ( dfi_ras_n1         ),
    .dfi_we_n0          ( dfi_we_n0          ),
    .dfi_we_n1          ( dfi_we_n1          ),
    // DFI Write
    .dfi_wrdata_en      ( dfi_wrdata_en      ),
    .dfi_wrdata         ( dfi_wrdata         ),
    .dfi_wrdata_mask    ( dfi_wrdata_mask    ),
    // DFI Read
    .dfi_rddata_en      ( dfi_rddata_en      ),
    .dfi_rddata_en_even ( dfi_rddata_en_even ),
    .dfi_rddata_en_odd  ( dfi_rddata_en_odd  ),
    // Bus Command
    .io_config_strobe   ( io_config_strobe   ),
    .io_config          ( io_config          ),
    // Misc.
    .pr_rd_ack          ( pr_rd_ack          ),
    // auto-refresh
    .aref_set_interval  ( aref_set_interval  ),
    .aref_interval      ( aref_interval      ),
    .aref_set_trfc      ( aref_set_trfc      ),
    .aref_trfc          ( aref_trfc          )
   );


	//***************************************************************************
  // Reporting the test case status
  //***************************************************************************
  localparam APP_CLK_PERIOD = tCK * nCK_PER_CLK;
  initial begin
    wait (phy_init_done);
    $display("Calibration Done");
  
    #1000000;


    // Implement Test Code


			  
	  #(APP_CLK_PERIOD*1000);
    $display("[JHPARK] Simulation Done");
    $finish;
  end


  `ifdef WAVE 
    initial begin
      $shm_open("WAVE");
      $shm_probe("ASM");
    end  
  `endif

     
endmodule

