# ===================================================================
# 1. Clock Definitions & Asynchronous Groups
# ===================================================================
create_clock -period 10.000 -name clk_B_virt [get_ports clk_B]
create_clock -period 50.000 -name clk_C1_virt [get_ports clk_C1]
create_clock -period 50.000 -name clk_C2_virt [get_ports clk_C2]
create_clock -period 10.000 -name clk_P1_virt [get_ports clk_P1]
create_clock -period 14.000 -name clk_P2_virt [get_ports clk_P2]
create_clock -period 20.000 -name clk_P3_virt [get_ports clk_P3]

set_clock_groups -asynchronous \
    -group [get_clocks clk_B_virt] \
    -group [get_clocks clk_C1_virt] \
    -group [get_clocks clk_C2_virt] \
    -group [get_clocks clk_P1_virt] \
    -group [get_clocks clk_P2_virt] \
    -group [get_clocks clk_P3_virt]

# ===================================================================
# 2. Global IO Standard
# ===================================================================
set_property IOSTANDARD LVCMOS33 [get_ports *]

# ===================================================================
# 3. Bypass Clock Routing (แก้ปัญหา IO Clock Placer failed)
# ===================================================================
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_P1_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_P2_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_P3_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_B_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_C1_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk_C2_IBUF]

# ===================================================================
# 4. Ignore Timing for Outputs
# ===================================================================
set_false_path -to [get_ports final_valid_1]
set_false_path -to [get_ports final_valid_2]
set_false_path -to [get_ports {final_data_1[*]}]
set_false_path -to [get_ports {final_data_2[*]}]