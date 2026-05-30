`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/08/2026 05:11:47 PM
// Design Name: 
// Module Name: tb_gals_top
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


module tb_gals_top();
    
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter HIGH_THRESH = 12;
    parameter LOW_THRESH = 8;
    
    logic clk_A = 0;
    logic rst_A_n = 0;
    
    logic clk_B = 0;
    logic rst_B_n = 0;
    
    logic [DATA_WIDTH-1:0] final_data;
    logic final_valid;
    logic [4:0] debug_fifo_level;
    
    // clk_A: sender(100 MHz -> Period 10 ns)
    always #5 clk_A = ~clk_A;

    // clk_B: recieve (40 MHz -> Period 25 ns)
    always #12.5 clk_B = ~clk_B;
    
    gals_top #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .HIGH_THRESH(HIGH_THRESH),
        .LOW_THRESH(LOW_THRESH)
    ) dut (
        .clk_A(clk_A),
        .rst_A_n(rst_A_n),
        .clk_B(clk_B),
        .rst_B_n(rst_B_n),
        .final_data(final_data),
        .final_valid(final_valid),
        .debug_fifo_level(debug_fifo_level)
    );
    
    int expected_val = 8'h10; 
    int valid_count = 0;
    int error_count = 0;

    initial begin
        $display("=== Start Testbench Full System GALS ===");

        rst_A_n = 0; rst_B_n = 0;
        #100;
        @(posedge clk_B) rst_B_n = 1;
        #20;
        @(posedge clk_A) rst_A_n = 1;

        fork
            begin
                while (valid_count < 100) begin
                    @(posedge clk_B);
                    #1;
                    
                    if (final_valid) begin
                        if (final_data !== expected_val) begin
                            $display("[Error] T=%0t | Expected: %0d, Got: %0d", $time, expected_val, final_data);
                            error_count++;
                        end else begin
                            if (valid_count % 10 == 0)
                                $display("[Pass] data at %0d is correct (Data: %0d, FIFO Level: %0d)", valid_count, final_data, debug_fifo_level);
                        end
                        expected_val++;
                        valid_count++;
                    end
                end
            end

            begin
                #100000; 
                $display(">> TIMEOUT: FSM might Deadlock");
                $finish;
            end
        join_any

        #100;
        $display("=== End Testbench ===");
        if (error_count == 0)
            $display(">> PASSED: GALS System work successfully in 2 Clock Domains");
        else
            $display(">> FAILED: %0d times", error_count);

        $finish;
    end
endmodule
