`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/09/2026 04:39:35 PM
// Design Name: 
// Module Name: tb_gals_top_3domain
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


module tb_gals_top_3domain();

    // ----------------------------------------------------
    // Parameters
    // ----------------------------------------------------
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter HIGH_THRESH = 12;
    parameter LOW_THRESH = 8;

    // ----------------------------------------------------
    // Signals & Variables
    // ----------------------------------------------------
    logic clk_A = 0; logic rst_A_n = 0;
    logic clk_B = 0; logic rst_B_n = 0;
    logic clk_C = 0; logic rst_C_n = 0;

    logic [DATA_WIDTH-1:0] final_data;
    logic                  final_valid;
    logic [ADDR_WIDTH:0]   debug_fifo1_level;
    logic [ADDR_WIDTH:0]   debug_fifo2_level;

    // Variables for storing Metrics
    int expected_val = 8'h10; 
    int valid_count = 0;
    int error_count = 0;
    int throttle_count_AB = 0;
    int throttle_count_BC = 0;
    int total_cycles_A = 0;

    // ----------------------------------------------------
    // Clock Generation
    // ----------------------------------------------------
    always #5  clk_A = ~clk_A; // 100 MHz
    always #10 clk_B = ~clk_B; // 50 MHz
    always #50 clk_C = ~clk_C; // 10 MHz

    // ----------------------------------------------------
    // Metric Monitors
    // ----------------------------------------------------
    // Detect throttling of A
    always @(posedge clk_A) begin
        if (rst_A_n) begin
            total_cycles_A++;
            // แอบดูสายไฟที่อยู่ใน Top module ได้เลยโดยตรง!
            if (dut.req_raw_A == 1'b1 && dut.ack_sync_A == 1'b0) begin
                throttle_count_AB++;
            end
        end
    end

    // Detect throttling of B
    always @(posedge clk_B) begin
        if (rst_B_n) begin
            if (dut.req_raw_C == 1'b1 && dut.ack_sync_C == 1'b0) begin
                throttle_count_BC++;
            end
        end
    end

    // ----------------------------------------------------
    // DUT Instantiation
    // ----------------------------------------------------
    gals_top_3domain #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) dut (
        .clk_A(clk_A), .rst_A_n(rst_A_n),
        .clk_B(clk_B), .rst_B_n(rst_B_n),
        .clk_C(clk_C), .rst_C_n(rst_C_n),
        .final_data(final_data),
        .final_valid(final_valid),
        .debug_fifo1_level(debug_fifo1_level),
        .debug_fifo2_level(debug_fifo2_level)
    );

    // ----------------------------------------------------
    // Test Scenario & Verification
    // ----------------------------------------------------
    initial begin
        $display("=== Start Testbench 3-Domain GALS (Cascade Backpressure) ===");

        #200;
        @(posedge clk_C) rst_C_n = 1;
        #50;
        @(posedge clk_B) rst_B_n = 1;
        #50;
        @(posedge clk_A) rst_A_n = 1;

        // Data Checking Loop
        fork
            begin
                while (valid_count < 100) begin
                    @(posedge clk_C);
                    #1;
                    
                    if (final_valid) begin
                        if (final_data !== expected_val) begin
                            $display("[Error] T=%0t | Expected: %0d, Got: %0d", $time, expected_val, final_data);
                            error_count++;
                        end else begin
                            if (valid_count % 10 == 0)
                                $display("[Pass] %0d Correct (FIFO1: %0d, FIFO2: %0d)", 
                                         valid_count, debug_fifo1_level, debug_fifo2_level);
                        end
                        expected_val++;
                        valid_count++;
                    end
                end
            end

            begin
                #1000000;
                $display(">> TIMEOUT: too long, might have Deadlock");
                $finish;
            end
        join_any

        #500;
        $display("=== End Testbench ===");
        if (error_count == 0)
            $display(">> PASSED: Cascade Backpressure done 100%%");
        else
            $display(">> FAILED: %0d times", error_count);

        $display("========================================");
        $display("         PERFORMANCE METRICS            ");
        $display("========================================");
        $display("- Total clk_A Cycles : %0d", total_cycles_A);
        $display("- A->B Throttle Wait : %0d cycles", throttle_count_AB);
        $display("- B->C Throttle Wait : %0d cycles", throttle_count_BC);
        $display("- Data Throughput    : 100 items / %0t", $time);
        $display("========================================");

        $finish;
    end
endmodule
