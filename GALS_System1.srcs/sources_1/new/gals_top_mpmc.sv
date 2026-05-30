`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/11/2026 11:32:40 AM
// Design Name: 
// Module Name: gals_top_mpmc
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


module gals_top_mpmc #(
    parameter NUM_PRODUCERS = 3,
    parameter NUM_CONSUMERS = 2,
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter THROTTLE_CYCLES = 0 // 0 = Scenario A, 3 = Scenario B
)(
    input  logic clk_P1, input logic rst_P1_n, // Domain P1
    input  logic clk_P2, input logic rst_P2_n, // Domain P2
    input  logic clk_P3, input logic rst_P3_n, // Domain P3
    input  logic clk_B,  input logic rst_B_n,  // Arbiter
    input  logic clk_C1, input logic rst_C1_n,  
    input  logic clk_C2, input logic rst_C2_n,  // Consumer
    
    output logic [DATA_WIDTH-1:0] final_data_1,
    output logic                  final_valid_1,
    output logic [DATA_WIDTH-1:0] final_data_2,
    output logic                  final_valid_2
    );
       
    // 1. Producer
    logic [NUM_PRODUCERS-1:0] p_w_en, p_wfull;
    logic [DATA_WIDTH-1:0] p_wdata [NUM_PRODUCERS-1:0];
    
    logic [3:0] p1_throttle, p2_throttle, p3_throttle;

    // P1: (Hex 10...)
    always_ff @(posedge clk_P1 or negedge rst_P1_n) begin
        if (!rst_P1_n) begin 
            p_wdata[0] <= 8'h0F; p_w_en[0] <= 0; p1_throttle <= 0; 
        end else begin
            if (!p_wfull[0] && p1_throttle >= THROTTLE_CYCLES) begin 
                p_wdata[0] <= p_wdata[0] + 1; 
                p_w_en[0] <= 1; 
                p1_throttle <= 0;
            end else begin 
                p_w_en[0] <= 0;
                if (p1_throttle < THROTTLE_CYCLES) p1_throttle <= p1_throttle + 1;
            end
        end
    end

    // P2: (Hex 20...)
    always_ff @(posedge clk_P2 or negedge rst_P2_n) begin
        if (!rst_P2_n) begin 
            p_wdata[1] <= 8'h1F; p_w_en[1] <= 0; p2_throttle <= 0; 
        end else begin
            if (!p_wfull[1] && p2_throttle >= THROTTLE_CYCLES) begin 
                p_wdata[1] <= p_wdata[1] + 1; 
                p_w_en[1] <= 1; 
                p2_throttle <= 0; 
            end else begin 
                p_w_en[1] <= 0;
                if (p2_throttle < THROTTLE_CYCLES) p2_throttle <= p2_throttle + 1;
            end
        end
    end

    // P3: (Hex 30...)
    always_ff @(posedge clk_P3 or negedge rst_P3_n) begin
        if (!rst_P3_n) begin 
            p_wdata[2] <= 8'h2F; p_w_en[2] <= 0; p3_throttle <= 0; 
        end else begin
            if (!p_wfull[2] && p3_throttle >= THROTTLE_CYCLES) begin 
                p_wdata[2] <= p_wdata[2] + 1; 
                p_w_en[2] <= 1; 
                p3_throttle <= 0; 
            end else begin 
                p_w_en[2] <= 0;
                if (p3_throttle < THROTTLE_CYCLES) p3_throttle <= p3_throttle + 1;
            end
        end
    end

    // 2. Input Async FIFOs
    logic [NUM_PRODUCERS-1:0] p_r_en, p_rempty;
    logic [DATA_WIDTH-1:0] p_rdata [NUM_PRODUCERS-1:0];
    
    genvar i;
    generate
        for (i = 0; i < NUM_PRODUCERS; i++) begin : gen_input_fifos
            logic input_clk;
            logic input_rst;
            if (i==0) begin assign input_clk = clk_P1; assign input_rst = rst_P1_n; end
            if (i==1) begin assign input_clk = clk_P2; assign input_rst = rst_P2_n; end
            if (i==2) begin assign input_clk = clk_P3; assign input_rst = rst_P3_n; end
            
            async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_in_fifo (
                .wclk(input_clk), .wrst_n(input_rst),
                .w_en(p_w_en[i]), .wdata(p_wdata[i]), .wfull(p_wfull[i]),
                .rclk(clk_B), .rrst_n(rst_B_n),
                .r_en(p_r_en[i]), .rdata(p_rdata[i]), .rempty(p_rempty[i])
            );
        end
    endgenerate

    // 3. MPMC Arbiter (The NoI Router) run on clk_B
    logic [NUM_CONSUMERS-1:0] out_w_en, out_wfull;
    logic [DATA_WIDTH-1:0] out_wdata;
    
    // if !rempty means there is a Request
    logic [NUM_PRODUCERS-1:0] arb_req;
    assign arb_req = ~p_rempty;

    hw_queue_descriptor #(
        .NUM_PRODUCERS(NUM_PRODUCERS),
        .NUM_CONSUMERS(NUM_CONSUMERS),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_arbiter (
        .clk(clk_B), .rst_n(rst_B_n),
        .req(arb_req),
        .grant(p_r_en),
        .prod_data_in( {p_rdata[2], p_rdata[1], p_rdata[0]} ),  
        .fifo_wfull(out_wfull),
        .fifo_w_en(out_w_en),
        .fifo_wdata(out_wdata)
    );

    // 4. Output Async FIFO for Consumer 1
    logic out_r_en_1, out_rempty_1;
    logic [DATA_WIDTH-1:0] out_rdata_1;
    logic [ADDR_WIDTH:0] out_w_level_1;
    
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_out_fifo_1 (
        .wclk(clk_B), .wrst_n(rst_B_n), .w_en(out_w_en[0]), .wdata(out_wdata), .wfull(out_wfull[0]), .w_level(out_w_level_1),
        .rclk(clk_C1), .rrst_n(rst_C1_n), .r_en(out_r_en_1), .rdata(out_rdata_1), .rempty(out_rempty_1)
    );

    logic [1:0] acg_mode_B_1, acg_mode_C_1, acg_mode_gray_B_1, acg_mode_gray_C_1;
    logic consumer_ce_1;

    dvfs_controller_fsm #(.ADDR_WIDTH(ADDR_WIDTH)) u_acg_ctrl_1 (
        .clk(clk_B), .rst_n(rst_B_n), .fifo_level(out_w_level_1), .dvfs_mode(acg_mode_B_1)
    );

    assign acg_mode_gray_B_1 = acg_mode_B_1 ^ (acg_mode_B_1 >> 1);
    sync_2stage #(2) u_sync_mode_1 (.clk(clk_C1), .rst(!rst_C1_n), .d(acg_mode_gray_B_1), .q(acg_mode_gray_C_1));
    assign acg_mode_C_1[1] = acg_mode_gray_C_1[1];
    assign acg_mode_C_1[0] = acg_mode_gray_C_1[1] ^ acg_mode_gray_C_1[0];

    dvfs_clock_divider u_acg_div_1 (.clk(clk_C1), .rst_n(rst_C1_n), .mode(acg_mode_C_1), .clk_en(consumer_ce_1));

    assign out_r_en_1 = !out_rempty_1 && consumer_ce_1;
    
    logic out_r_en_1_pipe;
    
    always_ff @(posedge clk_C1 or negedge rst_C1_n) begin
        if (!rst_C1_n) begin 
            out_r_en_1_pipe <= 1'b0;
            final_data_1    <= '0; 
            final_valid_1   <= 1'b0; 
        end else begin
            out_r_en_1_pipe <= out_r_en_1;           // Delay 1 cycle เพื่อรอ RAM
            final_valid_1   <= out_r_en_1_pipe;      // Valid จะขึ้นพร้อม Data
            if (out_r_en_1_pipe) 
                final_data_1 <= out_rdata_1;         // Capture Data ที่ถูกต้อง
        end
    end

    // 5. Output Async FIFOs & ACG (DVFS) for Consumer 2
    logic out_r_en_2, out_rempty_2;
    logic [DATA_WIDTH-1:0] out_rdata_2;
    logic [ADDR_WIDTH:0] out_w_level_2;
    
    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_out_fifo_2 (
        .wclk(clk_B), .wrst_n(rst_B_n), .w_en(out_w_en[1]), .wdata(out_wdata), .wfull(out_wfull[1]), .w_level(out_w_level_2),
        .rclk(clk_C2), .rrst_n(rst_C2_n), .r_en(out_r_en_2), .rdata(out_rdata_2), .rempty(out_rempty_2)
    );

    logic [1:0] acg_mode_B_2, acg_mode_C_2, acg_mode_gray_B_2, acg_mode_gray_C_2;
    logic consumer_ce_2;

    dvfs_controller_fsm #(.ADDR_WIDTH(ADDR_WIDTH)) u_acg_ctrl_2 (
        .clk(clk_B), .rst_n(rst_B_n), .fifo_level(out_w_level_2), .dvfs_mode(acg_mode_B_2)
    );

    assign acg_mode_gray_B_2 = acg_mode_B_2 ^ (acg_mode_B_2 >> 1);
    sync_2stage #(2) u_sync_mode_2 (.clk(clk_C2), .rst(!rst_C2_n), .d(acg_mode_gray_B_2), .q(acg_mode_gray_C_2));
    assign acg_mode_C_2[1] = acg_mode_gray_C_2[1];
    assign acg_mode_C_2[0] = acg_mode_gray_C_2[1] ^ acg_mode_gray_C_2[0];

    dvfs_clock_divider u_acg_div_2 (.clk(clk_C2), .rst_n(rst_C2_n), .mode(acg_mode_C_2), .clk_en(consumer_ce_2));

    assign out_r_en_2 = !out_rempty_2 && consumer_ce_2;
    
    logic out_r_en_2_pipe;
    
    always_ff @(posedge clk_C2 or negedge rst_C2_n) begin
        if (!rst_C2_n) begin 
            out_r_en_2_pipe <= 1'b0;
            final_data_2    <= '0; 
            final_valid_2   <= 1'b0; 
        end else begin
            out_r_en_2_pipe <= out_r_en_2;
            final_valid_2   <= out_r_en_2_pipe;
            if (out_r_en_2_pipe) 
                final_data_2 <= out_rdata_2;
        end
    end    
endmodule
