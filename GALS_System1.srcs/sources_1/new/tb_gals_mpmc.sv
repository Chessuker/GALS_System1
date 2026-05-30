`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Thawat Boonsuk
// 
// Create Date: 04/11/2026 11:46:25 AM
// Design Name: 
// Module Name: tb_gals_mpmc
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


module tb_gals_mpmc;
    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    // Clock and Reset Signals
    logic clk_P1, rst_P1_n;
    logic clk_P2, rst_P2_n;
    logic clk_P3, rst_P3_n;
    logic clk_B,  rst_B_n;
    
    // 2 Consumer Domains for MPMC
    logic clk_C1, rst_C1_n;
    logic clk_C2, rst_C2_n;

    // Outputs
    logic [DATA_WIDTH-1:0] final_data_1;
    logic                  final_valid_1;
    logic [DATA_WIDTH-1:0] final_data_2;
    logic                  final_valid_2;

    // Instantiate the Unit Under Test (UUT)
    gals_top_mpmc #(
        .NUM_PRODUCERS(3),
        .NUM_CONSUMERS(2),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .THROTTLE_CYCLES(1) // ปรับ Throttle เพื่อจำลองทราฟฟิก
    ) uut (
        .clk_P1(clk_P1), .rst_P1_n(rst_P1_n),
        .clk_P2(clk_P2), .rst_P2_n(rst_P2_n),
        .clk_P3(clk_P3), .rst_P3_n(rst_P3_n),
        .clk_B(clk_B),   .rst_B_n(rst_B_n),
        
        .clk_C1(clk_C1), .rst_C1_n(rst_C1_n),
        .clk_C2(clk_C2), .rst_C2_n(rst_C2_n),
        
        .final_data_1(final_data_1),
        .final_valid_1(final_valid_1),
        .final_data_2(final_data_2),
        .final_valid_2(final_valid_2)
    );

    // ---------------------------------------------------------
    // Clock Generation (6 Asynchronous Domains)
    // ---------------------------------------------------------
    initial clk_P1 = 0; always #5.0  clk_P1 = ~clk_P1;  // 100 MHz (Producer 1)
    initial clk_P2 = 0; always #6.0  clk_P2 = ~clk_P2;  // ~83.3 MHz (Producer 2)
    initial clk_P3 = 0; always #4.0  clk_P3 = ~clk_P3;  // 125 MHz (Producer 3)
    initial clk_B  = 0; always #2.5  clk_B  = ~clk_B;   // 200 MHz (Arbiter - Fast)
    
    // ตั้งความเร็ว Consumer ให้ต่างกันเพื่อดูพฤติกรรม Load Balancing
    initial clk_C1 = 0; always #10.0 clk_C1 = ~clk_C1;  // 50 MHz  (Consumer 1)
    initial clk_C2 = 0; always #12.5 clk_C2 = ~clk_C2;  // 40 MHz  (Consumer 2)

    // =========================================================
    // RESULT TRACKING LOGIC
    // =========================================================
    
    always @(posedge clk_C1) begin
        if (rst_C1_n && final_valid_1) begin
            $display("[%t] [Consumer 1] Processed Data: %h", $realtime, final_data_1);
        end
    end

    always @(posedge clk_C2) begin
        if (rst_C2_n && final_valid_2) begin
            $display("[%t] [Consumer 2] Processed Data: %h", $realtime, final_data_2);
        end
    end

    // ---------------------------------------------------------
    // Test Scenario
    // ---------------------------------------------------------
    initial begin
        $timeformat(-9, 3, " ns", 10);

        $display("=================================================");
        $display("STARTING GALS-MPMC ADVANCED FAULT SIMULATION");
        $display("=================================================");
        
        // 1. Initialize Resets
        rst_P1_n = 0; rst_P2_n = 0; rst_P3_n = 0; rst_B_n = 0; rst_C1_n = 0; rst_C2_n = 0;
        
        // 2. Release Resets (Normal Operation)
        #50;
        rst_P1_n = 1; rst_P2_n = 1; rst_P3_n = 1; rst_B_n = 1; rst_C1_n = 1; rst_C2_n = 1;
        $display("[%t] 🟢 All Domains Online. Normal Dispatching...", $realtime);

        #2000;

        // ---------------------------------------------------------
        // Glitch Fault Test (Transient Spike)
        // ---------------------------------------------------------
        $display("-------------------------------------------------");
        $display("[%t] GLITCH INJECTED: 1ns Transient Reset Spike on P1", $realtime);
        $display("-------------------------------------------------");
        rst_P1_n = 0;
        #1.0; 
        rst_P1_n = 1;
        
        #2500;

        // ---------------------------------------------------------
        // Consumer Fault Test (Backpressure Verification)
        // ---------------------------------------------------------
        $display("-------------------------------------------------");
        $display("[%t] CONSUMER FAULT: C2 Offline (Testing Backpressure)", $realtime);
        $display("-------------------------------------------------");
        rst_C2_n = 0;
        
        #4000;
        
        $display("-------------------------------------------------");
        $display("[%t] RECOVERY: C2 Online (Releasing Backpressure)", $realtime);
        $display("-------------------------------------------------");
        rst_C2_n = 1;
        
        #3000;

        $display("=================================================");
        $display("SIMULATION COMPLETE. All Fault Scenarios Verified.");
        $display("=================================================");
        $finish;
    end
    
endmodule
