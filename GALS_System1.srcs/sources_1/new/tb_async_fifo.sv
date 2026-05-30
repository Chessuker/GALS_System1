`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/07/2026 10:36:45 PM
// Design Name: 
// Module Name: tb_async_fifo
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


module tb_async_fifo();
    // 1. Parameters & Signals
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;

    logic                  wclk = 0;
    logic                  wrst_n = 0;
    logic                  w_en = 0;
    logic [DATA_WIDTH-1:0] wdata = 0;
    logic                  wfull;
    logic [ADDR_WIDTH:0]   w_level;

    logic                  rclk = 0;
    logic                  rrst_n = 0;
    logic                  r_en = 0;
    logic [DATA_WIDTH-1:0] rdata;
    logic                  rempty;

    // 2. Clock Generation (Clock Drift Simulation)
    // wclk: 100 MHz (Period = 10 ns -> Half Period = 5 ns)
    always #5 wclk = ~wclk;

    // rclk: ~67 MHz (Period ≈ 14.92 ns -> Half Period = 7.46 ns)
    always #7.46 rclk = ~rclk;

    // 3. DUT Instantiation
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk(wclk), .wrst_n(wrst_n), .w_en(w_en), .wdata(wdata), .wfull(wfull), .w_level(w_level),
        .rclk(rclk), .rrst_n(rrst_n), .r_en(r_en), .rdata(rdata), .rempty(rempty)
    );

    // 4. Test Scenario (Stimulus & Self-Checking)
    integer i, j;
    logic [DATA_WIDTH-1:0] expected_data = 0;
    int error_count = 0;

    initial begin
        // Reset System
        $display("=== Start Testbench Asynchronous FIFO ===");
        wrst_n = 0; rrst_n = 0;
        #50;
        wrst_n = 1; rrst_n = 1;
        #50;

        fork
            // Thread 1: Producer (Write)
            begin
                int i = 0;
                w_en = 0;
                while (i < 50) begin
                    @(posedge wclk);
                    #1;
                    
                    if ($urandom_range(0, 100) > 30) begin 
                        if (!wfull) begin
                            w_en = 1;  
                            wdata = i;
                            i++;
                        end else begin
                            w_en = 0;
                        end
                    end else begin
                        w_en = 0;
                    end
                end
                @(posedge wclk);
                #1 w_en = 0;
                $display("Producer: done send all 50");
            end

            // Thread 2: Consumer (Read & Verify)
            begin
                int j = 0;
                r_en = 0; // 초기화
                while (j < 50) begin
                    @(posedge rclk);
                    #1;
                    
                    if (!rempty) begin
                        r_en = 1;
                        @(posedge rclk); #1;
                        r_en = 0;
                        @(posedge rclk); #1; 
                        
                        if (rdata !== expected_data) begin
                            $display("ERROR: Expected %0d, Got %0d", expected_data, rdata);
                            error_count++;
                        end else begin
                            $display("Read OK: %0d (FIFO Level: %0d)", rdata, w_level);
                        end
                        expected_data++;
                        j++;
                        
                    end else begin
                        r_en = 0;
                    end
                end
                $display("Consumer: 50 done");
            end
        join

        #100;
        $display("=== Ending Testbench ===");
        if (error_count == 0)
            $display(">> PASSED");
        else
            $display(">> FAILED: total failed %0d", error_count);
            
        $finish;
    end
endmodule
