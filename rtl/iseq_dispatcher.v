`timescale 1ns / 1ps

module iseq_dispatcher #(parameter ROW_WIDTH = 15, BANK_WIDTH = 3, CKE_WIDTH = 1, 
										CS_WIDTH = 1, nCS_PER_RANK = 1, DQ_WIDTH = 64) (
	input clk,
	input rst,
	
	input periodic_read_lock,
	
	input process_iseq,
	
	output dispatcher_busy,
	
	output instr0_fifo_rd,
	input instr0_fifo_empty,
	input[31:0] instr0_fifo_data,
	
	output instr1_fifo_rd,
	input instr1_fifo_empty,
	input[31:0] instr1_fifo_data,
	
	//DFI Interface
	// DFI Control/Address
	input 										dfi_ready,
	input 										dfi_init_complete,
	output [ROW_WIDTH-1:0]              dfi_address0,
	output [ROW_WIDTH-1:0]              dfi_address1,
	output [BANK_WIDTH-1:0]             dfi_bank0,
	output [BANK_WIDTH-1:0]             dfi_bank1,
	output										dfi_cke0,
	output										dfi_cke1,
	output 										dfi_cas_n0,
	output 										dfi_cas_n1,
	output [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_cs_n0,
	output [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_cs_n1,
	output [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_odt0,
	output [CS_WIDTH*nCS_PER_RANK-1:0]  dfi_odt1,
	output 										dfi_ras_n0,
	output 										dfi_ras_n1,
	output 										dfi_we_n0,
	output 										dfi_we_n1,
	// DFI Write
	output                              dfi_wrdata_en,
	output [4*DQ_WIDTH-1:0]             dfi_wrdata,
	output [4*(DQ_WIDTH/8)-1:0]         dfi_wrdata_mask,
	// DFI Read
	output                              dfi_rddata_en,
	output										dfi_rddata_en_even,
	output										dfi_rddata_en_odd,
	
	//Bus Command
	output io_config_strobe,
	output[1:0] io_config,
	
	//Misc.
	output pr_rd_ack,
	
	//auto-refresh
   output aref_set_interval,
   output[27:0] aref_interval, 
   output aref_set_trfc,
   output[27:0] aref_trfc
);

	wire instr0_disp_en, instr1_disp_en;
	wire instr0_disp_ack, instr1_disp_ack;
	reg dispatcher_busy_r = 1'b0, dispatcher_busy_ns;
	////////////////////////////////////////
	wire instr0_en, instr1_en;
	wire [31:0] inter_instr, inter_instr0, inter_instr1;
	reg rh_en0, rh_en1;
	wire rh_end_o;
	wire [31:0] rh_instr0, rh_instr1;
	wire rh_out_en0_o, rh_out_en1_o;
	////////////////////////////////////////
	
	//check conditions and start transaction
	always@*
		dispatcher_busy_ns = ~rst & process_iseq | (dispatcher_busy_r & (~(instr0_fifo_empty & instr1_fifo_empty) 
									| instr0_en | instr1_en));

	always@(posedge clk)
			dispatcher_busy_r <= dispatcher_busy_ns;
	
	wire[31:0] instr0, instr1;
	
	wire instr0_ready, instr1_ready;

	assign instr0_fifo_rd = instr0_ready & dispatcher_busy_r & ~(rh_en0 | rh_en1);
	assign instr1_fifo_rd = instr1_ready & dispatcher_busy_r & ~(rh_en0 | rh_en1);
	
	pipe_reg #(.WIDTH(32)) i_instr0_reg(
        .clk(clk),
        .rst(rst),
        
        .ready_in(instr0_disp_ack),
        .valid_in(dispatcher_busy_r & !instr0_fifo_empty),
        .data_in(instr0_fifo_data),

        //.valid_out(instr0_disp_en),
		.valid_out(instr0_en),
		//.data_out(instr0),
		.data_out(inter_instr0),
        .ready_out(instr0_ready)
    );
	 
	 pipe_reg #(.WIDTH(32)) i_instr1_reg(
        .clk(clk),
        .rst(rst),
        
        .ready_in(instr1_disp_ack),
        .valid_in(dispatcher_busy_r & !instr1_fifo_empty),
        .data_in(instr1_fifo_data),

        //.valid_out(instr1_disp_en),
		.valid_out(instr1_en),
        //.data_out(instr1),
		.data_out(inter_instr1),
        .ready_out(instr1_ready)
    );

	always@(*) begin 
		if(rh_en0 & ~rh_end_o) rh_en0 = 1'b1;
		else rh_en0 = ((inter_instr0[31:29] == `RH) & instr0_en);
		
		if(rh_en1 & ~rh_end_o) rh_en0 = 1'b1;
		else rh_en1 = ((inter_instr1[31:29] == `RH) & instr1_en);
	end

	assign inter_instr = (rh_en1 & ~rh_end_o) ? inter_instr1 : ((rh_en0 & ~rh_end_o) ? inter_instr0 : 32'b0);

	RH_generator i_rh_generator(
		.clk(clk),
        .rst(rst),
		
		.rh_start(rh_en0 | rh_en1),
		.rh_instr(inter_instr),
		.ready_in0(instr0_disp_ack),
		.ready_in1(instr1_disp_ack),

		.rh_instr0_out(rh_instr0),
		.rh_instr1_out(rh_instr1),
		.rh_out_en0(rh_out_en0_o),
		.rh_out_en1(rh_out_en1_o),
		.rh_end(rh_end_o)
	);
	
	assign instr0 = ((rh_en0 | rh_en1) & ~rh_end_o) ? rh_instr0 : inter_instr0;
	assign instr1 = ((rh_en0 | rh_en1) & ~rh_end_o) ? rh_instr1 : inter_instr1;

	always@(*) begin
		if(rh_en0 & rh_end_o) rh_en0 = 1'b0;
		else if(rh_en1 & rh_end_o) rh_en1 = 1'b0;
	end

	wire rh_disp_en0, rh_disp_en1;
	assign rh_disp_en0 = rh_en0 ? (dispatcher_busy_r & rh_out_en0_o) : instr0_en;
	assign rh_disp_en1 = rh_en1 ? (dispatcher_busy_r & rh_out_en1_o) : instr1_en;

	//Command Dispatcher Instantiation
	instr_dispatcher #(.ROW_WIDTH(ROW_WIDTH), .BANK_WIDTH(BANK_WIDTH), .CKE_WIDTH(CKE_WIDTH), 
										.CS_WIDTH(CS_WIDTH), .nCS_PER_RANK(nCS_PER_RANK), .DQ_WIDTH(DQ_WIDTH)) i_instr_dispatcher(
	.clk(clk),
	.rst(rst),
	
	.periodic_read_lock(periodic_read_lock),
	
	//.en_in0(instr0_disp_en),
	.en_in0(rh_disp_en0),
	.en_ack0(instr0_disp_ack),
	.instr_in0(instr0),
	
	
	//.en_in1(instr1_disp_en), 
	.en_in1(rh_disp_en1), 
	.en_ack1(instr1_disp_ack),
	.instr_in1(instr1),

	
	//DFI Interface
	
	// DFI Control/Address
	.dfi_ready(dfi_ready),
	.dfi_address0(dfi_address0),
	.dfi_address1(dfi_address1),
	.dfi_bank0(dfi_bank0),
	.dfi_bank1(dfi_bank1),
	.dfi_cke0(dfi_cke0),
	.dfi_cke1(dfi_cke1),
	.dfi_cas_n0(dfi_cas_n0),
	.dfi_cas_n1(dfi_cas_n1),
	.dfi_cs_n0(dfi_cs_n0),
	.dfi_cs_n1(dfi_cs_n1),
	.dfi_odt0(dfi_odt0),
	.dfi_odt1(dfi_odt1),
	.dfi_ras_n0(dfi_ras_n0),
	.dfi_ras_n1(dfi_ras_n1),
	.dfi_we_n0(dfi_we_n0),
	.dfi_we_n1(dfi_we_n1),
	// DFI Write
	.dfi_wrdata_en(dfi_wrdata_en),
	.dfi_wrdata(dfi_wrdata),
	.dfi_wrdata_mask(dfi_wrdata_mask),
	// DFI Read
	.dfi_rddata_en(dfi_rddata_en),
	.dfi_rddata_en_even(dfi_rddata_en_even),
	.dfi_rddata_en_odd(dfi_rddata_en_odd),
	
	//Bus Command
	.io_config_strobe(io_config_strobe),
	.io_config(io_config),
	
	//Misc.
	.pr_rd_ack(pr_rd_ack),
	
	//auto-refresh
	.aref_set_interval(aref_set_interval),
	.aref_interval(aref_interval),
	.aref_set_trfc(aref_set_trfc),
	.aref_trfc(aref_trfc)
);
	
	assign dispatcher_busy = dispatcher_busy_r;
	
endmodule
