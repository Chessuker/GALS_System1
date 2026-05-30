`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2026 12:03:26 PM
// Design Name: 
// Module Name: dvfs_controller_fsm
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


module dvfs_controller_fsm#(
    parameter ADDR_WIDTH = 4,
    parameter HIGH_THRESH = 12,
    parameter LOW_THRESH = 4
)(
    input logic clk,
    input logic rst_n,
    input logic [ADDR_WIDTH:0] fifo_level,
    output logic [1:0] dvfs_mode
    );
    
    typedef enum logic [1:0] {
        MODE_SLEEP  = 2'b11, // 1:8 Speed
        MODE_ECO    = 2'b10, // 1:4 Speed
        MODE_NORMAL = 2'b01, // 1:2 Speed
        MODE_TURBO  = 2'b00  // 1:1 Speed
    } state_t;

    state_t current_state, next_state;

    // Sequential logic for state update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            current_state <= MODE_NORMAL;
        else        
            current_state <= next_state;
    end

    // Combinational logic with Hysteresis (Dual Watermarks)
    always_comb begin
        next_state = current_state;
        dvfs_mode  = current_state; 

        case (current_state)
            MODE_SLEEP: begin
                // Wake up to ECO only when level is significantly > 0
                if (fifo_level >= 2) 
                    next_state = MODE_ECO;
            end
            
            MODE_ECO: begin
                // Scale up to NORMAL when level is well above LOW_THRESH
                // Creates a deadband of 2 spaces
                if (fifo_level >= LOW_THRESH + 2) 
                    next_state = MODE_NORMAL;
                // Scale down to SLEEP when completely empty
                else if (fifo_level == 0) 
                    next_state = MODE_SLEEP;
            end
            
            MODE_NORMAL: begin
                // Scale up to TURBO when hitting HIGH_THRESH
                if (fifo_level >= HIGH_THRESH) 
                    next_state = MODE_TURBO;
                // Scale down to ECO only when level drops well below LOW_THRESH
                // Fixes the ping-pong thrashing bug!
                else if (fifo_level <= LOW_THRESH - 1) 
                    next_state = MODE_ECO;
            end
            
            MODE_TURBO: begin
                // Scale down to NORMAL only when level drops safely below HIGH_THRESH
                // Creates a deadband of 3 spaces
                if (fifo_level <= HIGH_THRESH - 3) 
                    next_state = MODE_NORMAL;
            end
            
            default: next_state = MODE_NORMAL;
        endcase
    end    
endmodule
