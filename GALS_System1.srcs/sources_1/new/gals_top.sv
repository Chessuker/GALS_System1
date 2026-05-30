`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 04:47:54 PM
// Design Name: 
// Module Name: gals_top
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


module gals_top #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter HIGH_THRESH = 12,
    parameter LOW_THRESH = 8
)(
    input logic clk_A,
    input logic rst_A_n,
    input logic clk_B,
    input logic rst_B_n,
    output logic [DATA_WIDTH-1:0] final_data,
    output logic final_valid,
    output logic [ADDR_WIDTH:0] debug_fifo_level
    );
    
    logic gen_valid;
    logic [DATA_WIDTH-1:0] gen_data;
    
    logic fifo_w_en;
    logic [DATA_WIDTH-1:0] fifo_wdata;
    logic fifo_wfull;
    logic [ADDR_WIDTH:0] w_level;
    
    logic fifo_r_en;
    logic [DATA_WIDTH-1:0] fifo_rdata;
    logic fifo_rempty;

    logic req_raw, req_sync;
    logic ack_raw, ack_sync;

    assign debug_fifo_level = w_level;
    
    always_ff @(posedge clk_A or negedge rst_A_n) begin
        if (!rst_A_n) begin
            gen_data  <= '0;
            gen_valid <= 1'b0;
        end else begin
            gen_valid <= 1'b1; 
            if (fifo_w_en) begin
                gen_data <= gen_data + 1'b1;
            end
        end
    end
    
    producer_adaptive_fsm #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) u_producer (
        .clk(clk_A),
        .rst_n(rst_A_n),
        .gen_valid(gen_valid),
        .gen_data(gen_data),
        .w_level(w_level),
        .fifo_wfull(fifo_wfull),
        .fifo_w_en(fifo_w_en),
        .fifo_wdata(fifo_wdata),
        .req(req_raw),
        .ack_sync(ack_sync)
    );
    
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_fifo (
        .wclk(clk_A),
        .wrst_n(rst_A_n),
        .w_en(fifo_w_en),
        .wdata(fifo_wdata),
        .wfull(fifo_wfull),
        .w_level(w_level),
        .rclk(clk_B),
        .rrst_n(rst_B_n),
        .r_en(fifo_r_en),
        .rdata(fifo_rdata),
        .rempty(fifo_rempty)
    );
    
    processor_core #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_processor (
        .clk(clk_B),
        .rst_n(rst_B_n),
        .fifo_rempty(fifo_rempty),
        .fifo_rdata(fifo_rdata),
        .fifo_r_en(fifo_r_en),
        .req_sync(req_sync),
        .ack(ack_raw),
        .proc_data(final_data),
        .proc_valid(final_valid)
    );
    
    sync_2stage #(1) sync_req (
        .clk(clk_B),
        .rst(!rst_B_n),
        .d(req_raw),
        .q(req_sync)
    );
    
    sync_2stage #(1) sync_ack (
        .clk(clk_A),
        .rst(!rst_A_n),
        .d(ack_raw),
        .q(ack_sync)
    );
endmodule
