module wavelet_pe_datapath #(
    parameter INPUT_WIDTH       = 32,

    parameter IBUFF_CELL_COUNT  = 2048,
    parameter OBUFF_CELL_COUNT  = 2048,
    parameter MAX_FILTER_SIZE   = 16,

    parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE),
    parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT)
) (
    input                           clk,
    input                           rst,

    // general configuration signals
    input                           pe_init,
    input                           core_downsample,
    input [FS_WIDTH-1:0]            core_filter_size,
    input [1:0]                     cur_dec_level,
    input                           init_in_progress,
    input [OBUFF_ADDR_WIDTH-1:0]    cur_outputs_len,
    input [OBUFF_ADDR_WIDTH-1:0]    prev_outputs_len,   


    input                           obuff_w_offset_rst,
    input                           obuff_w_hp_base_reg_rst,
    input                           obuff_w_lp_base_reg_rst,
    input [OBUFF_ADDR_WIDTH-1:0]    obuff_w_approx_addr,
    input                           obuff_w_hp_force_cen,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_addr,
    output [INPUT_WIDTH-1:0]        obuff_w_data,
    output                          obuff_w_en,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_lp_abs_address,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_hp_address,

    // ibuff signals
    input                           ibuff_r_addr_offset_rst,
    input                           ibuff_r_addr_offset_upcount,
    input                           ibuff_r_addr_base_reg_rst,
    input                           ibuff_r_addr_offset_cen,
    input [INPUT_WIDTH-1:0]         ibuff_r_data,
    output [IBUFF_ADDR_WIDTH-1:0]   ibuff_r_addr,

    // fir signals
    input                           fir_flush_pipeline,
    input                           fir_init,
    input                           fir_disable_freezing,
    input                           fir_force_freeze,
    input                           fir_hp_input_valid,
    input                           fir_lp_input_valid,
    output                          fir_hp_output_valid,
    output                          fir_lp_output_valid,
    output [INPUT_WIDTH-1:0]        fir_hp_output,
    output [INPUT_WIDTH-1:0]        fir_lp_output

);

    wavelet_pe_feeder #( 
        .INPUT_WIDTH                    (INPUT_WIDTH),
        .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
        .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
    ) feeder (
        .clk                            (clk),
        .rst                            (rst),
        .downsample                     (core_downsample),
        .cur_dec_level                  (cur_dec_level),
        .filter_size                    (core_filter_size),
        .pe_init                        (pe_init),
        .init_in_progress               (init_in_progress),
        .ibuff_r_addr                   (ibuff_r_addr),
        .ibuff_r_addr_offset_rst        (ibuff_r_addr_offset_rst),
        .ibuff_r_addr_offset_upcount    (ibuff_r_addr_offset_upcount),
        .ibuff_r_addr_offset_cen        (ibuff_r_addr_offset_cen),
        .ibuff_r_addr_base_reg_rst      (ibuff_r_addr_base_reg_rst)
    );

    fir_filter #(
        .MAX_FILTER_SIZE                (MAX_FILTER_SIZE),
        .INPUT_WIDTH                    (INPUT_WIDTH),
        .OUTPUT_WIDTH                   (INPUT_WIDTH)
    ) hp_filter (
        .clk                            (clk),
        .rst                            (rst),
        .filter_size                    (core_filter_size),
        .cur_dec_level                  (cur_dec_level),
        .downsample                     (core_downsample),
        .flush_pipeline                 (fir_flush_pipeline),
        .input_valid                    (fir_hp_input_valid),
        .init_filter                    (fir_init),
        .disable_freezing               (fir_disable_freezing),
        .force_freeze                   (fir_force_freeze),
        .fir_input                      (ibuff_r_data),
        .output_valid                   (fir_hp_output_valid),
        .fir_output                     (fir_hp_output),
        .error_flag                     ()
    );

    fir_filter #(
        .MAX_FILTER_SIZE                (MAX_FILTER_SIZE),
        .INPUT_WIDTH                    (INPUT_WIDTH),
        .OUTPUT_WIDTH                   (INPUT_WIDTH)
    ) lp_filter (
        .clk                            (clk),
        .rst                            (rst),
        .filter_size                    (core_filter_size),
        .cur_dec_level                  (cur_dec_level),
        .downsample                     (core_downsample),
        .flush_pipeline                 (fir_flush_pipeline),
        .input_valid                    (fir_lp_input_valid),
        .init_filter                    (fir_init),
        .disable_freezing               (fir_disable_freezing),
        .force_freeze                   (fir_force_freeze),
        .fir_input                      (ibuff_r_data),
        .output_valid                   (fir_lp_output_valid),
        .fir_output                     (fir_lp_output),
        .error_flag                     ()
    );

    wavelet_pe_sink #(
        .INPUT_WIDTH                    (INPUT_WIDTH),
        .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
        .IBUFF_ADDR_WIDTH               (IBUFF_ADDR_WIDTH)
    ) sink (
        .clk                            (clk),
        .rst                            (rst),

        .fir_hp_output_valid            (fir_hp_output_valid),
        .fir_lp_output_valid            (fir_lp_output_valid),
        .fir_hp_output                  (fir_hp_output),
        .fir_lp_output                  (fir_lp_output),

        .cur_outputs_len                (cur_outputs_len),
        .prev_outputs_len               (prev_outputs_len),
        .obuff_w_offset_rst             (obuff_w_offset_rst),
        .obuff_w_hp_base_reg_rst        (obuff_w_hp_base_reg_rst),
        .obuff_w_lp_base_reg_rst        (obuff_w_lp_base_reg_rst),
        .obuff_w_hp_force_cen           (obuff_w_hp_force_cen),
        .obuff_w_approx_addr            (obuff_w_approx_addr),
        .obuff_w_lp_abs_address         (obuff_w_lp_abs_address),
        .obuff_w_hp_address             (obuff_w_hp_address),

        .obuff_w_addr                   (obuff_w_addr),
        .obuff_w_data                   (obuff_w_data),
        .obuff_w_en                     (obuff_w_en)
    );

endmodule