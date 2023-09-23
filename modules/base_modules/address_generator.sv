module address_generator #(
parameter CELL_COUNT        = 2048,
parameter MAX_OFFSET        = 16,

parameter OFFSET_WIDTH      = $clog2(MAX_OFFSET),
parameter ADDR_WIDTH        = $clog2(CELL_COUNT)
) (
    input                           clk,
    input                           rst,
    input                           offset_rst,
    input                           offset_upcount,
    input                           offset_cen,
    input [OFFSET_WIDTH-1:0]        offset_max_count,

    input                           base_reg_rst,
    input [ADDR_WIDTH-1:0]          base_reg_init_value,
    input [ADDR_WIDTH-1:0]          base_reg_in,
    
    output                          offset_co,
    output [OFFSET_WIDTH-1:0]       offset,
    output [ADDR_WIDTH-1:0]         base_reg_out,
    output [ADDR_WIDTH-1:0]         addr
);

wire base_enable;

assign addr = base_reg_out + offset;
assign base_enable = offset_cen & offset_co;

counter #(
    .COUNTER_WIDTH          (OFFSET_WIDTH)
) offset_counter (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (offset_rst),
    .count_up               (offset_upcount),
    .enable_counter         (offset_cen),
    .max_count              (offset_max_count),
    .count_value            (offset),
    .co                     (offset_co)
);

register #(
    .INPUT_WIDTH            (ADDR_WIDTH)
) base_reg (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (base_reg_rst),
    .en                     (base_enable),
    .rst_value              (base_reg_init_value),
    .load_data              (offset_co),
    .input_data             (base_reg_in),
    .output_data            (base_reg_out)
);

endmodule