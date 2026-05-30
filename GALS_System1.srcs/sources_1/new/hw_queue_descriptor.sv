`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2026 11:09:34 AM
// Design Name: 
// Module Name: hw_queue_descriptor
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


module hw_queue_descriptor #(
    parameter NUM_PRODUCERS = 3,
    parameter NUM_CONSUMERS = 2,
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic rst_n,
    input logic [NUM_PRODUCERS-1:0] req,
    output logic [NUM_PRODUCERS-1:0] grant,
    input logic [(NUM_PRODUCERS*DATA_WIDTH)-1:0] prod_data_in, // flat wire 24-bit
    input logic [NUM_CONSUMERS-1:0] fifo_wfull,
    output logic [NUM_CONSUMERS-1:0] fifo_w_en,
    output logic [DATA_WIDTH-1:0] fifo_wdata
);

logic [DATA_WIDTH-1:0] prod_data [NUM_PRODUCERS-1:0];
generate
    genvar i;
    for (i = 0; i < NUM_PRODUCERS; i++) begin : gen_prod_data
        assign prod_data[i] = prod_data_in[(i*DATA_WIDTH) +: DATA_WIDTH];
    end
endgenerate
    
    logic [$clog2(NUM_PRODUCERS)-1:0] turn, next_turn;
    logic dest, next_dest;
    
    // FSM: Manage Delay of BRAM 1 Cycle
    typedef enum logic [1:0] {
        IDLE       = 2'b00,
        READ_FIFO  = 2'b01,
        WRITE_OUT  = 2'b10
    } state_t;
    state_t current_state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            turn          <= '0;
            dest          <= '0;
        end else begin
            current_state <= next_state;
            turn          <= next_turn;
            dest          <= next_dest;
        end
    end

    always_comb begin
        next_state = current_state;
        next_turn  = turn;
        next_dest  = dest;
        grant      = '0;
        fifo_w_en  = '0;
        fifo_wdata = '0;

        case (current_state)
            IDLE: begin
                if (req != 0 && (fifo_wfull != 2'b11)) begin
                    if (req[turn]) begin
                        next_state = READ_FIFO;
                    end else begin
                        if (turn == NUM_PRODUCERS - 1) next_turn = 0;
                        else next_turn = turn + 1;
                    end
                end
            end

            READ_FIFO: begin
                grant[turn] = 1'b1; 
                next_state  = WRITE_OUT;
            end

            WRITE_OUT: begin
                fifo_wdata = prod_data[turn];
                
                if (!fifo_wfull[dest]) begin
                    fifo_w_en[dest] = 1'b1;
                    next_dest = ~dest;
                end else if (!fifo_wfull[~dest]) begin
                    fifo_w_en[~dest] = 1'b1;
                end
                
                if (turn == NUM_PRODUCERS - 1) next_turn = 0;
                else next_turn = turn + 1;
                next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule
