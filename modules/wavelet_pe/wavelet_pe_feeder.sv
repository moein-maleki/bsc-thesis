module wavelet_pe_feeder #(
parameter INPUT_WIDTH       = 32,
parameter IBUFF_CELL_COUNT  = 2048,
parameter MAX_FILTER_SIZE   = 16,

parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE-1),
parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT)
) (
    input                           clk,
    input                           rst,

    input                           downsample,
    input [1:0]                     cur_dec_level,
    input [FS_WIDTH-1:0]            filter_size,
    input                           init_in_progress,
    input                           pe_init,
    
    input                           ibuff_r_addr_offset_rst,
    input                           ibuff_r_addr_offset_upcount,
    input                           ibuff_r_addr_offset_cen,
    input                           ibuff_r_addr_base_reg_rst,
    output [IBUFF_ADDR_WIDTH-1:0]   ibuff_r_addr
);

localparam MAX_FILTER_COEFFS = (MAX_FILTER_SIZE << 1) + 1;
localparam MAX_FILTER_COEFFS_WIDTH = $clog2(MAX_FILTER_COEFFS);

wire [MAX_FILTER_COEFFS_WIDTH-1:0]  ibuff_r_addr_offset_max_count;
wire [IBUFF_ADDR_WIDTH-1:0]         ibuff_r_addr_base_reg_init_value;
wire [IBUFF_ADDR_WIDTH-1:0]         ibuff_r_addr_base_reg_in;
wire [IBUFF_ADDR_WIDTH-1:0]         ibuff_r_addr_base_reg_out;

assign ibuff_r_addr_base_reg_init_value =
    (init_in_progress | pe_init)  ? (0) : (downsample);

assign ibuff_r_addr_offset_max_count =
    (init_in_progress)  ? ((filter_size << 1) + 2) :
    (downsample)        ? (filter_size) : (filter_size << cur_dec_level);

assign ibuff_r_addr_base_reg_in =
    (downsample)        ? (ibuff_r_addr_base_reg_out+2) : (ibuff_r_addr_base_reg_out+1);

address_generator #(
    .CELL_COUNT             (IBUFF_CELL_COUNT),
    .MAX_OFFSET             (MAX_FILTER_COEFFS)
) ibuff_r_addr_gen (
    .clk                    (clk),
    .rst                    (rst),
    .offset_rst             (ibuff_r_addr_offset_rst),
    .offset_upcount         (ibuff_r_addr_offset_upcount),
    .offset_cen             (ibuff_r_addr_offset_cen),
    .offset_max_count       (ibuff_r_addr_offset_max_count),
    .base_reg_rst           (ibuff_r_addr_base_reg_rst),
    .base_reg_init_value    (ibuff_r_addr_base_reg_init_value),
    .base_reg_in            (ibuff_r_addr_base_reg_in),
    .offset_co              (),
    .offset                 (),
    .base_reg_out           (ibuff_r_addr_base_reg_out),
    .addr                   (ibuff_r_addr)
);

endmodule