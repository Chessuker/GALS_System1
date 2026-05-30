`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/07/2026 08:27:10 PM
// Design Name: 
// Module Name: gray_counter
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


module gray_counter #(
    parameter ADDR_WIDTH = 4
)(
    input logic clk,
    input logic rst,
    input logic en,
    output logic [ADDR_WIDTH:0] ptr_g,
    output logic [ADDR_WIDTH-1:0] addr
    );
    
    logic [ADDR_WIDTH:0] bin;
    logic [ADDR_WIDTH:0] bin_next;
    logic [ADDR_WIDTH:0] gray_next;
    
    assign bin_next = bin + (en);
    assign gray_next = bin_next ^ (bin_next >> 1);
    assign addr = bin[ADDR_WIDTH-1:0];
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            bin <= 0;
            ptr_g <= 0;
        end else begin
            bin <= bin_next;
            ptr_g <= gray_next;
        end
    end
endmodule
