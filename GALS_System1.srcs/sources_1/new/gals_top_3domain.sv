`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/09/2026 04:27:18 PM
// Design Name: 
// Module Name: gals_top_3domain
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module gals_top_3domain #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter HIGH_THRESH = 12,
    parameter LOW_THRESH = 8
)(
    input logic clk_A,
    input logic rst_A_n,
    
    input logic clk_B,
    input logic rst_B_n,
    
    input logic clk_C,
    input logic rst_C_n,
    
    output logic [DATA_WIDTH-1:0] final_data,
    output logic final_valid,
    output logic [ADDR_WIDTH:0] debug_fifo1_level,
    output logic [ADDR_WIDTH:0] debug_fifo2_level
    );
    
    // Data Generator
    logic gen_valid;
    logic [DATA_WIDTH-1:0] gen_data;
    
    //A -> FIFO_1 -> B
    logic fifo1_w_en, fifo1_wfull;
    logic [DATA_WIDTH-1:0] fifo1_wdata;
    logic [ADDR_WIDTH:0] fifo1_w_level;
    
    logic fifo1_r_en, fifo1_rempty;
    logic [DATA_WIDTH-1:0] fifo1_rdata;
    
    //B -> FIFO_2 -> C
    logic fifo2_w_en, fifo2_wfull;
    logic [DATA_WIDTH-1:0] fifo2_wdata;
    logic [ADDR_WIDTH:0] fifo2_w_level;
    
    logic fifo2_r_en, fifo2_rempty;
    logic [DATA_WIDTH-1:0] fifo2_rdata;
    
    // Handshake A <-> B
    logic req_raw_A, req_sync_A;
    logic ack_raw_A, ack_sync_A;
    
    // Handshake B <-> C
    logic req_raw_C, req_sync_C;
    logic ack_raw_C, ack_sync_C;
    
    // Assign Debug
    assign debug_fifo1_level = fifo1_w_level;
    assign debug_fifo2_level = fifo2_w_level;
    
    always_ff @(posedge clk_A or negedge rst_A_n) begin
        if (!rst_A_n) begin
            gen_data  <= '0;
            gen_valid <= 1'b0;
        end else begin
            gen_valid <= 1'b1; 
            if (fifo1_w_en) gen_data <= gen_data + 1'b1;
        end
    end
    
    // Domain A
    producer_adaptive_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) u_producer (
        .clk(clk_A), .rst_n(rst_A_n),
        .gen_valid(gen_valid), .gen_data(gen_data),
        .w_level(fifo1_w_level), .fifo_wfull(fifo1_wfull),
        .fifo_w_en(fifo1_w_en), .fifo_wdata(fifo1_wdata),
        .req(req_raw_A), .ack_sync(ack_sync_A)
    );
    
    // --- FIFO 1 (A -> B) ---
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_fifo_1 (
        .wclk(clk_A), .wrst_n(rst_A_n), .w_en(fifo1_w_en), .wdata(fifo1_wdata), .wfull(fifo1_wfull), .w_level(fifo1_w_level),
        .rclk(clk_B), .rrst_n(rst_B_n), .r_en(fifo1_r_en), .rdata(fifo1_rdata), .rempty(fifo1_rempty)
    );
    
    // Domain B
    processor_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) u_processor (
        .clk(clk_B), .rst_n(rst_B_n),
        // A
        .fifo1_rempty(fifo1_rempty), .fifo1_rdata(fifo1_rdata), .fifo1_r_en(fifo1_r_en),
        .req_sync_A(req_sync_A), .ack_A(ack_raw_A),
        // C
        .fifo2_wfull(fifo2_wfull), .fifo2_w_level(fifo2_w_level), .fifo2_w_en(fifo2_w_en), .fifo2_wdata(fifo2_wdata),
        .req_C(req_raw_C), .ack_sync_C(ack_sync_C)
    );
    
    // --- FIFO 2 (B -> C) ---
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_fifo_2 (
        .wclk(clk_B), .wrst_n(rst_B_n), .w_en(fifo2_w_en), .wdata(fifo2_wdata), .wfull(fifo2_wfull), .w_level(fifo2_w_level),
        .rclk(clk_C), .rrst_n(rst_C_n), .r_en(fifo2_r_en), .rdata(fifo2_rdata), .rempty(fifo2_rempty)
    );
    
    //Domain C
    consumer_core #(.DATA_WIDTH(DATA_WIDTH)) u_consumer (
        .clk(clk_C), .rst_n(rst_C_n),
        .fifo_rempty(fifo2_rempty), .fifo_rdata(fifo2_rdata), .fifo_r_en(fifo2_r_en),
        .req_sync(req_sync_C), .ack(ack_raw_C),
        .final_data(final_data), .final_valid(final_valid)
    );
    
    // CDC Synchronizers
    // A-B
    sync_2stage #(1) sync_req_A2B (.clk(clk_B), .rst(!rst_B_n), .d(req_raw_A), .q(req_sync_A));
    sync_2stage #(1) sync_ack_B2A (.clk(clk_A), .rst(!rst_A_n), .d(ack_raw_A), .q(ack_sync_A));
    
    // B-C
    sync_2stage #(1) sync_req_B2C (.clk(clk_C), .rst(!rst_C_n), .d(req_raw_C), .q(req_sync_C));
    sync_2stage #(1) sync_ack_C2B (.clk(clk_B), .rst(!rst_B_n), .d(ack_raw_C), .q(ack_sync_C));
endmodule
