`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/07/2026 09:21:46 PM
// Design Name: 
// Module Name: async_fifo
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


module async_fifo#(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input logic wclk,
    input logic wrst_n,
    input logic w_en,
    input logic [DATA_WIDTH-1:0] wdata,
    output logic wfull,
    (* DONT_TOUCH = "TRUE" *) output logic [ADDR_WIDTH:0] w_level,
    
    input logic rclk,
    input logic rrst_n,
    input logic r_en,
    output logic [DATA_WIDTH-1:0]rdata,
    output logic rempty
    );
    
    logic [ADDR_WIDTH-1:0] waddr, raddr;
    logic [ADDR_WIDTH:0] wptr_g, rptr_g;
    logic [ADDR_WIDTH:0] wptr_g_sync, rptr_g_sync;
    
    dual_port_ram #(DATA_WIDTH, ADDR_WIDTH) dp_ram (
        .wclk(wclk), .w_en(w_en && !wfull), .waddr(waddr), .wdata(wdata),
        .rclk(rclk), .r_en(r_en && !rempty), .raddr(raddr), .rdata(rdata)
    );
    
    gray_counter #(ADDR_WIDTH) w_cnt (
        .clk(wclk), .rst(!wrst_n), .en(w_en && !wfull), .ptr_g(wptr_g), .addr(waddr)
    );
    
    gray_counter #(ADDR_WIDTH) r_cnt (
        .clk(rclk), .rst(!rrst_n), .en(r_en && !rempty), .ptr_g(rptr_g), .addr(raddr)
    );
    
    sync_2stage #(ADDR_WIDTH+1) sync_w2r (
        .clk(rclk), .rst(!rrst_n), .d(wptr_g), .q(wptr_g_sync)
    );
    
    sync_2stage #(ADDR_WIDTH+1) sync_r2w (
        .clk(wclk), .rst(!wrst_n), .d(rptr_g), .q(rptr_g_sync)
    );
    
    assign rempty = (wptr_g_sync == rptr_g);
    assign wfull = (wptr_g == {~rptr_g_sync[ADDR_WIDTH], ~rptr_g_sync[ADDR_WIDTH-1], rptr_g_sync[ADDR_WIDTH-2:0]});
        
    logic [ADDR_WIDTH:0] rptr_bin_sync;
    always_comb begin
        rptr_bin_sync[ADDR_WIDTH] = rptr_g_sync[ADDR_WIDTH];
        for (int idx = ADDR_WIDTH-1; idx >= 0; idx--)
            rptr_bin_sync[idx] = rptr_bin_sync[idx+1] ^ rptr_g_sync[idx];
    end
    
    logic [ADDR_WIDTH:0] wptr_bin;
    always_comb begin
        wptr_bin[ADDR_WIDTH] = wptr_g[ADDR_WIDTH];
        for (int idx = ADDR_WIDTH-1; idx >= 0; idx--)
            wptr_bin[idx] = wptr_bin[idx+1] ^ wptr_g[idx];
    end
    
    assign w_level = wptr_bin - rptr_bin_sync;
endmodule