`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/10/2026 03:28:30 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(
    parameter CLK_FREQ = 10_000_000,
    parameter BAUD_RATE = 115200
)(
    input logic clk,
    input logic rst_n,
    input logic tx_valid,
    input logic [7:0] tx_data,
    output logic tx_ready,
    output logic tx_out
    );
    
    localparam CLOCKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    
    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state, next_state;
    
    logic [15:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  tx_shift_reg;

    assign tx_ready = (state == IDLE);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            clk_count    <= 0;
            bit_index    <= 0;
            tx_shift_reg <= 0;
            tx_out       <= 1'b1; // Idle line is HIGH
        end else begin
            case (state)
                IDLE: begin
                    tx_out    <= 1'b1;
                    clk_count <= 0;
                    bit_index <= 0;
                    if (tx_valid) begin
                        tx_shift_reg <= tx_data;
                        state        <= START;
                    end
                end
                
                START: begin
                    tx_out <= 1'b0; // Start bit is LOW
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        state     <= DATA;
                    end
                end
                
                DATA: begin
                    tx_out <= tx_shift_reg[bit_index]; 
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                        end else begin
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx_out <= 1'b1; // Stop bit is HIGH
                    if (clk_count < CLOCKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule
