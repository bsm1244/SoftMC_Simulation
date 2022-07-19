`timescale 1ns / 1ps

`include "softMC.inc"

module RH_generator #(parameter CS_WIDTH = 1)(

    input clk,
    input rst,

    input rh_start,
    input [31:0] rh_instr,

    input ready_in0,
    input ready_in1,


    output reg [31:0] rh_instr0_out,
    output reg [31:0] rh_instr1_out,
    output reg rh_out_en0,
    output reg rh_out_en1,
    output reg rh_end
);

localparam HIGH = 1'b1;
localparam LOW = 1'b0;

localparam ACT = 3'b000;
localparam ACT_WAIT = 3'b001;
localparam WRITE = 3'b010;
localparam WRITE_WAIT = 3'b011;
localparam PRE = 3'b100;
localparam PRE_WAIT = 3'b101;
localparam BUS_DIR = 3'b110;
localparam BUS_DIR_WAIT = 3'b111;

// 6, 7, 0, 1, 2, 3, 4, 5


reg [2:0] rh_state_ns, rh_state;

reg update_signal;

reg [14:0] rh_row;
reg [5:0] rh_count;
reg [7:0] rh_pattern;

reg [5:0] hammerCount;
reg [14:0] subCounter;

reg [31:0] output_instr0, output_instr1;

initial begin
    rh_end = 1'b0;
end

always@(posedge clk) begin
    if(rh_start & rh_end) rh_end = 1'b0;
end

always@(posedge rh_start) begin
    update_signal = 1'b0;
    rh_state = BUS_DIR;

    subCounter = 15'b0;
    hammerCount = 8'b0;
    output_instr0 = 32'b0;
    output_instr1 = 32'b0;

    rh_count = rh_instr[5:0];
    rh_row = rh_instr[20:6];
    rh_pattern = rh_instr[28:21];
end

always@(*) begin
    rh_state_ns = rh_state;
    
    if(rh_start && ~rh_end) begin

        case(rh_state)
            BUS_DIR: begin
                output_instr0[31:28] = `SET_BUSDIR;
                output_instr0[1:0] = 2'b01;

                output_instr1[31:28] = `WAIT;
                output_instr1[27:0] = `DEF_TRCD;
                
                if(ready_in0 & ready_in1) begin
                    rh_out_en0 = 1'b1;
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = BUS_DIR_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = BUS_DIR_WAIT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end

            BUS_DIR_WAIT: begin
                output_instr0[31:28] = `WAIT;
                output_instr0[27:0] = `DEF_TRCD;
                //output_instr0[27:0] = 16;
                
                output_instr1[31:28] = `DDR_INSTR;
                output_instr1[`CKE_OFFSET] = HIGH;
                output_instr1[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr1[`RAS_OFFSET] = LOW;
                output_instr1[`CAS_OFFSET] = HIGH;
                output_instr1[`WE_OFFSET] = HIGH;
                output_instr1[`ROW_OFFSET - 1:0] = rh_row;
                output_instr0[`ROW_OFFSET +: 3] = 3'b0;
                
                
                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = ACT_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end
            
                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end

            ACT: begin
                
                output_instr0[31:28] = `DDR_INSTR;
                output_instr0[`CKE_OFFSET] = HIGH;
                output_instr0[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr0[`RAS_OFFSET] = LOW;
                output_instr0[`CAS_OFFSET] = HIGH;
                output_instr0[`WE_OFFSET] = HIGH;
                output_instr0[`ROW_OFFSET - 1:0] = rh_row;
                output_instr0[`ROW_OFFSET +: 3] = 3'b0;
                

                output_instr1[31:28] = `WAIT;
                output_instr1[27:0] = `DEF_TRCD;
                //output_instr1[27:0] = 16;

                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = WRITE;//PRE;//
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = ACT_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = ACT_WAIT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end
            
            ACT_WAIT: begin
                output_instr0[31:28] = `WAIT;
                output_instr0[27:0] = `DEF_TRCD;
                //output_instr0[27:0] = 16;

                
                output_instr1[31:28] = `DDR_INSTR;
                output_instr1[`CKE_OFFSET] = HIGH;
                output_instr1[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr1[`RAS_OFFSET] = HIGH;
                output_instr1[`CAS_OFFSET] = LOW;
                output_instr1[`WE_OFFSET] = LOW;
                output_instr1[30:25] = rh_pattern[7:2];
                output_instr1[15:14] = rh_pattern[1:0];
                output_instr0[`ROW_OFFSET +: 3] = 3'b0;
                //write_burst_data_ns = {instr0[30:25], instr0[(`ROW_OFFSET - 1) -:2]};
                output_instr1[9:0] = 10'd0;

                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = WRITE_WAIT;//PRE_WAIT;//
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = WRITE;//PRE;//WRITE;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = WRITE;//PRE;//WRITE;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end
            
            WRITE: begin

                output_instr0[31:28] = `DDR_INSTR;
                output_instr0[`CKE_OFFSET] = HIGH;
                output_instr0[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr0[`RAS_OFFSET] = HIGH;
                output_instr0[`CAS_OFFSET] = LOW;
                output_instr0[`WE_OFFSET] = LOW;
                output_instr0[30:25] = rh_pattern[7:2];
                output_instr0[15:14] = rh_pattern[1:0];
                output_instr0[`ROW_OFFSET +: 3] = 3'b0;
                //write_burst_data_ns = {instr0[30:25], instr0[(`ROW_OFFSET - 1) -:2]};
                output_instr0[9:0] = 10'd0;

                output_instr1[31:28] = `WAIT;
                output_instr1[27:0] = `DEF_TRAS - `DEF_TRCD;
                
                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = PRE;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = WRITE_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = WRITE_WAIT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end
            
            WRITE_WAIT: begin
                output_instr0[31:28] = `WAIT;
                output_instr0[27:0] = `DEF_TRAS - `DEF_TRCD;
                //output_instr0[27:0] = 16;

                output_instr1[31:28] = `DDR_INSTR;
                output_instr1[`CKE_OFFSET] = HIGH;
                output_instr1[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr1[`RAS_OFFSET] = LOW;
                output_instr1[`CAS_OFFSET] = HIGH;
                output_instr1[`WE_OFFSET] = LOW;
                output_instr1[10] = LOW;
                
                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = PRE_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = PRE;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = PRE;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end
            
            PRE: begin
                output_instr0[31:28] = `DDR_INSTR;
                output_instr0[`CKE_OFFSET] = HIGH;
                output_instr0[`CS_OFFSET +: CS_WIDTH] = LOW;
                output_instr0[`RAS_OFFSET] = LOW;
                output_instr0[`CAS_OFFSET] = HIGH;
                output_instr0[`WE_OFFSET] = LOW;
                output_instr0[10] = LOW;

                output_instr1[31:28] = `WAIT;
                output_instr1[27:0] = `DEF_TRP;
                //output_instr1[27:0] = 16;

                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                    
                    update_signal = 1'b1;

                    subCounter = subCounter + 1;
                
                    if(subCounter == 300) begin
                        subCounter = 0;
                        hammerCount = hammerCount + 1;
                    end

                    if(hammerCount >= rh_count) begin
                        rh_end = 1'b1;
                    end
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = PRE_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = PRE_WAIT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
            end
            
            
            PRE_WAIT: begin
                output_instr0[31:28] = `WAIT;
                output_instr0[27:0] = `DEF_TRP;
                //output_instr0[27:0] = 16;

                output_instr1[31:28] = `DDR_INSTR;
                output_instr1[`CKE_OFFSET] = HIGH;
                output_instr1[`CS_OFFSET +: CS_WIDTH] = {{CS_WIDTH-1{HIGH}}, LOW};
                output_instr1[`RAS_OFFSET] = LOW;
                output_instr1[`CAS_OFFSET] = HIGH;
                output_instr1[`WE_OFFSET] = HIGH;
                output_instr1[`ROW_OFFSET - 1:0] = rh_row;
                
                if(ready_in0 & ready_in1) begin
                    rh_instr0_out = output_instr0;
                    rh_instr1_out = output_instr1;
                    rh_state_ns = ACT_WAIT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b1;
                end
                
                else if(ready_in0) begin
                    rh_instr0_out = output_instr0;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b1;
                    rh_out_en1 = 1'b0;
                end

                else if(ready_in1) begin
                    rh_instr1_out = output_instr0;
                    rh_state_ns = ACT;
                    rh_out_en0 = 1'b0;
                    rh_out_en1 = 1'b1;
                end

                else rh_state_ns = rh_state;
                
                if(update_signal) update_signal = ~update_signal;
                else begin
                    subCounter = subCounter + 1;
                    
                    if(subCounter == 300) begin
                        subCounter = 0;
                        hammerCount = hammerCount + 1;
                    end

                    if(hammerCount == rh_count) begin
                        rh_end = 1'b1;
                    end
                end
            end
        endcase
    end
end

always@(posedge clk) begin
		if(rst) begin
			rh_state <= 4'b100;
		end
		else begin
			rh_state <= rh_state_ns;
		end
end

endmodule




