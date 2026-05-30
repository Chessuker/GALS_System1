`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/09/2026 03:45:48 PM
// Design Name: 
// Module Name: consumer_core
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


module consumer_core #(
    parameter DATA_WIDTH = 8
)(
    input logic clk,
    input logic rst_n,
    input logic fifo_rempty,
    input logic [DATA_WIDTH-1:0] fifo_rdata,
    output logic fifo_r_en,
    input logic req_sync,
    output logic ack,
    output logic [DATA_WIDTH-1:0] final_data,
    output logic final_valid
    );
    
    typedef enum logic {
        NORMAL_RUN = 1'b0,
        ACK_HIGH   = 1'b1
    } state_t;
    
    state_t current_state, next_state;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) current_state <= NORMAL_RUN;
        else        current_state <= next_state;
    end
    
    always_comb begin
        next_state = current_state;
        ack        = 1'b0;
        fifo_r_en  = 1'b0;
        
        case (current_state)
            NORMAL_RUN: begin
                if (req_sync == 1'b1) begin
                    next_state = ACK_HIGH;
                end 
                else if (!fifo_rempty) begin
                    fifo_r_en = 1'b1;
                end
            end

            ACK_HIGH: begin
                ack = 1'b1; 
                if (!fifo_rempty) begin
                    fifo_r_en = 1'b1;
                end
                
                if (req_sync == 1'b0) begin
                    next_state = NORMAL_RUN;
                end
            end
        endcase
    end

    logic r_en_pipeline;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_en_pipeline <= 1'b0;
            final_data    <= '0;
            final_valid   <= 1'b0;
        end else begin
            r_en_pipeline <= fifo_r_en;
            
            if (r_en_pipeline) begin
                final_data  <= fifo_rdata; 
                final_valid <= 1'b1;
            end else begin
                final_valid <= 1'b0; 
            end
        end
    end
endmodule
