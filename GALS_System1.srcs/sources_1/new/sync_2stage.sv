`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2026 09:02:54 PM
// Design Name: 
// Module Name: sync_2stage
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


module sync_2stage #(
    parameter WIDTH = 5  // ADDR_WIDTH + 1 ~ Gray Pointer
)(
    input logic clk,
    input logic rst,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
    );
    
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] q1;
    (* ASYNC_REG = "TRUE" *) logic [WIDTH-1:0] q;
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            q1 <= '0;
            q <= '0;
        end else begin
            q1 <= d;
            q <= q1;
        end   
    end
endmodule
