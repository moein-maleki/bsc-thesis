module wavelet_pe_sink #(
    parameter INPUT_WIDTH = 32,
    parameter OBUFF_CELL_COUNT  = 2048,
    parameter IBUFF_ADDR_WIDTH  = 15,

    parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT)
) (
    input                           clk,
    input                           rst,

    input [OBUFF_ADDR_WIDTH-1:0]    cur_outputs_len,
    input [OBUFF_ADDR_WIDTH-1:0]    prev_outputs_len,   

    input                           fir_hp_output_valid,
    input                           fir_lp_output_valid,
    input [INPUT_WIDTH-1:0]         fir_hp_output,
    input [INPUT_WIDTH-1:0]         fir_lp_output,

    input                           obuff_w_offset_rst,
    input                           obuff_w_hp_base_reg_rst,
    input                           obuff_w_lp_base_reg_rst,
    input                           obuff_w_hp_force_cen,
    input [OBUFF_ADDR_WIDTH-1:0]    obuff_w_approx_addr,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_lp_abs_address,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_hp_address,

    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_addr,
    output [INPUT_WIDTH-1:0]        obuff_w_data,
    output                          obuff_w_en
);

    wire                            fir_lp_output_valid_d1;
    wire [INPUT_WIDTH-1:0]          fir_lp_output_reg_out;
    wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_lp_address;
    wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_hp_base_reg_in;
    wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_hp_base_reg_out;

    assign obuff_w_hp_base_reg_in   = (obuff_w_hp_base_reg_out + cur_outputs_len);
    assign obuff_w_addr             =
        (fir_hp_output_valid)       ? (obuff_w_hp_address) :
        (fir_lp_output_valid_d1)    ? (obuff_w_lp_address) : ({(OBUFF_ADDR_WIDTH){1'bz}});
    assign obuff_w_en               = fir_hp_output_valid | fir_lp_output_valid_d1;
    assign obuff_w_data             =
        (fir_hp_output_valid)       ? (fir_hp_output) :
        (fir_lp_output_valid_d1)    ? (fir_lp_output_reg_out) : ({(INPUT_WIDTH){1'bz}});

    register #(
        .INPUT_WIDTH            (INPUT_WIDTH)
    ) fir_lp_data_register (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              ({(INPUT_WIDTH){1'b0}}),
        .load_data              (fir_lp_output_valid),
        .input_data             (fir_lp_output),
        .output_data            (fir_lp_output_reg_out)
    );

    register #(
        .INPUT_WIDTH            (1)
    ) fir_lp_co_register (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              (1'b0),
        .load_data              (1'b1),
        .input_data             (fir_lp_output_valid),
        .output_data            (fir_lp_output_valid_d1)
    );

    address_generator #(
        .CELL_COUNT             (OBUFF_CELL_COUNT),
        .MAX_OFFSET             (OBUFF_CELL_COUNT)
    ) hp_address_gen (
        .clk                    (clk),
        .rst                    (rst),
        .offset_rst             (obuff_w_offset_rst),
        .offset_upcount         (1'b1),
        .offset_cen             (fir_hp_output_valid | obuff_w_hp_force_cen),
        .offset_max_count       (cur_outputs_len),
        .base_reg_rst           (obuff_w_hp_base_reg_rst),
        .base_reg_init_value    ({(OBUFF_ADDR_WIDTH){1'b0}}),
        .base_reg_in            (obuff_w_hp_base_reg_in),
        .offset_co              (),
        .offset                 (),
        .base_reg_out           (obuff_w_hp_base_reg_out),
        .addr                   (obuff_w_hp_address)
    );

    address_generator #(
        .CELL_COUNT             (OBUFF_CELL_COUNT),
        .MAX_OFFSET             (OBUFF_CELL_COUNT)
    ) lp_address_gen (
        .clk                    (clk),
        .rst                    (rst),
        .offset_rst             (obuff_w_offset_rst),
        .offset_upcount         (1'b1),
        .offset_cen             (fir_lp_output_valid_d1),
        .offset_max_count       (prev_outputs_len),
        .base_reg_rst           (obuff_w_lp_base_reg_rst),
        .base_reg_init_value    (obuff_w_approx_addr),
        .base_reg_in            (obuff_w_approx_addr),
        .offset_co              (),
        .offset                 (obuff_w_lp_abs_address),
        .base_reg_out           (),
        .addr                   (obuff_w_lp_address)
    );

endmodule