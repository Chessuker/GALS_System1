`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 04:38:27 PM
// Design Name: 
// Module Name: processor_core
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


module processor_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter HIGH_THRESH = 12,
    parameter LOW_THRESH = 8
)(
    input logic clk,
    input logic rst_n,
    
    input logic fifo1_rempty,
    input logic [DATA_WIDTH-1:0] fifo1_rdata,
    output logic fifo1_r_en,
    input logic req_sync_A,
    output logic ack_A,
    
    input logic fifo2_wfull,
    input logic [ADDR_WIDTH:0] fifo2_w_level,
    output logic [DATA_WIDTH-1:0] fifo2_wdata,
    output logic fifo2_w_en,
    output logic req_C,
    input logic ack_sync_C
    );
    
    // Rx FSM, Recieve A
    typedef enum logic { 
        RX_NORMAL = 1'b0, 
        RX_ACK_HIGH = 1'b1 
    } rx_state_t;
    rx_state_t rx_curr, rx_next;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) rx_curr <= RX_NORMAL;
        else        rx_curr <= rx_next;
    end
    
    always_comb begin
        rx_next = rx_curr;
        ack_A   = 1'b0; 
        case (rx_curr)
            RX_NORMAL:   if (req_sync_A)  rx_next = RX_ACK_HIGH;
            RX_ACK_HIGH: begin
                ack_A = 1'b1;
                if (!req_sync_A) rx_next = RX_NORMAL;
            end
        endcase
    end
    
    //Tx FSM, Send to C
    typedef enum logic [1:0] {
        TX_FAST_MODE       = 2'b00,
        TX_THROTTLE_REQ    = 2'b01,
        TX_THROTTLE_WAIT_H = 2'b10,
        TX_THROTTLE_WAIT_L = 2'b11
    } tx_state_t;
    
    tx_state_t tx_curr, tx_next;
    logic tx_allow;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) tx_curr <= TX_FAST_MODE;
        else        tx_curr <= tx_next;
    end
    
    always_comb begin
        tx_next = tx_curr;
        req_C   = 1'b0;
        tx_allow = 1'b0;
        
        case (tx_curr)
            TX_FAST_MODE: begin
                tx_allow = 1'b1;
                if (fifo2_w_level >= HIGH_THRESH)
                    tx_next = TX_THROTTLE_REQ;
            end
            
            TX_THROTTLE_REQ: begin
                req_C = 1'b1;
                tx_next = TX_THROTTLE_WAIT_H;
            end
            
            TX_THROTTLE_WAIT_H: begin
                req_C = 1'b1;
                if (ack_sync_C) tx_next = TX_THROTTLE_WAIT_L;
            end
            
            TX_THROTTLE_WAIT_L: begin
                if (!ack_sync_C) begin
                    if (fifo2_w_level <= LOW_THRESH)
                        tx_next = TX_FAST_MODE;
                    else
                        tx_next = TX_THROTTLE_REQ;
                end
            end
        endcase
    end
    
    // 3. Data Pipeline
    assign fifo1_r_en = (!fifo1_rempty) && (!fifo2_wfull) && tx_allow;
    logic r_en_pipe;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_en_pipe   <= 1'b0;
            fifo2_wdata <= '0;
            fifo2_w_en  <= 1'b0;
        end else begin
            r_en_pipe <= fifo1_r_en;
            
            if (r_en_pipe) begin
                fifo2_wdata <= fifo1_rdata + 8'h10;
                fifo2_w_en  <= 1'b1;
            end else begin
                fifo2_w_en  <= 1'b0;
            end
        end
    end
endmodule
