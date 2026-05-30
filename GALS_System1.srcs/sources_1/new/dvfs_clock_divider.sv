`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/11/2026 11:59:11 AM
// Design Name: 
// Module Name: dvfs_clock_divider
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


module dvfs_clock_divider(
    input logic clk,
    input logic rst_n,
    input logic [1:0] mode,
    output logic clk_en
    );
    
    logic [2:0] counter;
    logic [2:0] max_count;

    always_comb begin
        case (mode)
            2'b00: max_count = 3'd0; // Turbo: work at all clock
            2'b01: max_count = 3'd1; // Normal: work 1 rest 1 (speed/2)
            2'b10: max_count = 3'd3; // Eco: work 1 rest 3 (speed/4)
            2'b11: max_count = 3'd7; // Sleep: work 1 rest 7 (speed/8)
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 3'd0;
            clk_en  <= 1'b1;
        end else begin
            if (counter >= max_count) begin
                counter <= 3'd0;
                clk_en  <= 1'b1;
            end else begin
                counter <= counter + 3'd1;
                clk_en  <= 1'b0;
            end
        end
    end
endmodule
