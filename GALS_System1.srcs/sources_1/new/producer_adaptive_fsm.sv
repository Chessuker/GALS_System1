`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 03:50:26 PM
// Design Name: 
// Module Name: producer_adaptive_fsm
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


module producer_adaptive_fsm #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter HIGH_THRESH = 12,
    parameter LOW_THRESH = 8
)(
    input logic clk,
    input logic rst_n,
    input logic gen_valid,
    input logic [DATA_WIDTH-1:0] gen_data,
    input logic [ADDR_WIDTH:0] w_level,
    input logic fifo_wfull,
    output logic fifo_w_en,
    output logic [DATA_WIDTH-1:0] fifo_wdata,
    output logic req,
    input logic ack_sync
    );
    
    typedef enum logic [1:0] {
        FAST_MODE          = 2'b00,
        THROTTLE_REQ           = 2'b01,
        THROTTLE_WAIT_HIGH = 2'b10,
        THROTTLE_WAIT_LOW  = 2'b11
    } state_t;
    
    state_t current_state, next_state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= FAST_MODE;
        end else begin
            current_state <= next_state;
        end
    end
    
    always_comb begin
        next_state = current_state;
        fifo_w_en  = 1'b0;
        fifo_wdata = gen_data;
        req        = 1'b0;

        case (current_state)
            FAST_MODE: begin
                req = 1'b0;
                if (w_level >= HIGH_THRESH) begin
                    next_state = THROTTLE_REQ;
                end 
                else if (gen_valid && !fifo_wfull) begin
                    fifo_w_en = 1'b1;
                end
            end

            THROTTLE_REQ: begin
                req = 1'b1; 
                // [SEMANTIC: BACKPRESSURE THROTTLE]
                if (gen_valid && !fifo_wfull) begin
                    fifo_w_en = 1'b1;
                    next_state = THROTTLE_WAIT_HIGH;
                end
            end

            THROTTLE_WAIT_HIGH: begin
                req = 1'b1;
                if (ack_sync == 1'b1) begin
                    req = 1'b0;
                    next_state = THROTTLE_WAIT_LOW;
                end
            end

            THROTTLE_WAIT_LOW: begin
                req = 1'b0;
                if (ack_sync == 1'b0) begin
                    if (w_level <= LOW_THRESH)
                        next_state = FAST_MODE;
                    else
                        next_state = THROTTLE_REQ;
                end
            end
            
            default: next_state = FAST_MODE;
        endcase
    end
endmodule
