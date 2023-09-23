module wavelet_pe #(
    parameter INPUT_WIDTH       = 32,

    parameter IBUFF_CELL_COUNT  = 2048,
    parameter OBUFF_CELL_COUNT  = 4096,

    parameter MAX_FILTER_SIZE   = 32,

    parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE),
    parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT)
) (
    input                           clk,
    input                           rst,

    // core signals
    input                           pe_init,
    input                           pe_go,
    input                           fir_force_freeze,
    input                           fir_disable_freezing,
    input                           ibuff_r_data_available,

    // general configuration signals
    input                           core_downsample,
    input [1:0]                     core_dec_level,
    input [FS_WIDTH-1:0]            core_filter_size,
    input [1:0]                     core_inputs_len,
    input [1:0]                     cur_dec_level,
    input [IBUFF_ADDR_WIDTH-1:0]    cur_inputs_len,
    input [OBUFF_ADDR_WIDTH-1:0]    cur_outputs_len,
    input [OBUFF_ADDR_WIDTH-1:0]    prev_outputs_len,   

    // ibuff read port
    input [INPUT_WIDTH-1:0]         ibuff_r_data,
    output [IBUFF_ADDR_WIDTH-1:0]   ibuff_r_addr,
    output                          ibuff_r_en,

    // obuff write port
    input [OBUFF_ADDR_WIDTH-1:0]    obuff_w_approx_addr,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_addr,
    output [INPUT_WIDTH-1:0]        obuff_w_data,
    output                          obuff_w_en,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_lp_abs_address,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_hp_address,

    output                          job_done
);

wire                            init_in_progress;

// obuff signals
wire                            obuff_w_offset_rst;
wire                            obuff_w_hp_base_reg_rst;
wire                            obuff_w_lp_base_reg_rst;
wire                            obuff_w_hp_force_cen;

// ibuff signals
wire                            ibuff_r_addr_offset_rst;
wire                            ibuff_r_addr_offset_upcount;
wire                            ibuff_r_addr_base_reg_rst;
wire                            ibuff_r_addr_offset_cen;

// fir signals
wire                            fir_hp_output_valid;
wire                            fir_lp_output_valid;
wire [INPUT_WIDTH-1:0]          fir_hp_output;
wire [INPUT_WIDTH-1:0]          fir_lp_output;
wire                            fir_init;
wire                            fir_flush_pipeline;
wire                            fir_hp_input_valid;
wire                            fir_lp_input_valid;

wavelet_pe_datapath #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
) pe_dp (
    .clk                            (clk),
    .rst                            (rst),
    .core_downsample                (core_downsample),
    .cur_dec_level                  (cur_dec_level),
    .core_filter_size               (core_filter_size),
    .pe_init                        (pe_init),
    .init_in_progress               (init_in_progress),
    .cur_outputs_len                (cur_outputs_len),
    .prev_outputs_len               (prev_outputs_len),
    
    .obuff_w_hp_base_reg_rst        (obuff_w_hp_base_reg_rst),
    .obuff_w_lp_base_reg_rst        (obuff_w_lp_base_reg_rst),
    .obuff_w_offset_rst             (obuff_w_offset_rst),
    .obuff_w_addr                   (obuff_w_addr),
    .obuff_w_data                   (obuff_w_data),
    .obuff_w_en                     (obuff_w_en),
    .obuff_w_approx_addr            (obuff_w_approx_addr),
    .obuff_w_lp_abs_address         (obuff_w_lp_abs_address),
    .obuff_w_hp_address             (obuff_w_hp_address),
    .obuff_w_hp_force_cen           (obuff_w_hp_force_cen),

    .ibuff_r_addr_offset_rst        (ibuff_r_addr_offset_rst),
    .ibuff_r_addr_offset_upcount    (ibuff_r_addr_offset_upcount),
    .ibuff_r_addr_base_reg_rst      (ibuff_r_addr_base_reg_rst),
    .ibuff_r_addr_offset_cen        (ibuff_r_addr_offset_cen),
    .ibuff_r_data                   (ibuff_r_data),
    .ibuff_r_addr                   (ibuff_r_addr),

    .fir_flush_pipeline             (fir_flush_pipeline),
    .fir_init                       (fir_init),
    .fir_disable_freezing           (fir_disable_freezing),
    .fir_force_freeze               (fir_force_freeze),
    .fir_hp_input_valid             (fir_hp_input_valid),
    .fir_lp_input_valid             (fir_lp_input_valid),
    .fir_hp_output_valid            (fir_hp_output_valid),
    .fir_lp_output_valid            (fir_lp_output_valid),
    .fir_hp_output                  (fir_hp_output),
    .fir_lp_output                  (fir_lp_output)
);

wavelet_pe_controller #(
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
) pe_cu (
    .clk                            (clk),
    .rst                            (rst),

    // core signals
    .core_downsample                (core_downsample),
    .core_dec_level                 (core_dec_level),
    .cur_dec_level                  (cur_dec_level),
    .core_filter_size               (core_filter_size),
    .core_inputs_len                (core_inputs_len),

    .pe_init                        (pe_init),
    .pe_go                          (pe_go),
    .ibuff_r_data_available         (ibuff_r_data_available),
    .cur_outputs_len                (cur_outputs_len),
    .cur_inputs_len                 (cur_inputs_len),

    
    // fir control signals
    .fir_flush_pipeline             (fir_flush_pipeline),
    .fir_init                       (fir_init),
    .fir_force_freeze               (fir_force_freeze),
    .fir_hp_input_valid             (fir_hp_input_valid),
    .fir_lp_input_valid             (fir_lp_input_valid),
    .fir_hp_output_valid            (fir_hp_output_valid),

    // obuff write control signals
    .obuff_w_offset_rst             (obuff_w_offset_rst),
    .obuff_w_hp_base_reg_rst        (obuff_w_hp_base_reg_rst),
    .obuff_w_lp_base_reg_rst        (obuff_w_lp_base_reg_rst),
    .obuff_w_hp_force_cen           (obuff_w_hp_force_cen),

    // ibuff read control signals
    .ibuff_r_addr_offset_rst        (ibuff_r_addr_offset_rst),
    .ibuff_r_addr_offset_upcount    (ibuff_r_addr_offset_upcount),
    .ibuff_r_addr_base_reg_rst      (ibuff_r_addr_base_reg_rst),
    .ibuff_r_addr_offset_cen        (ibuff_r_addr_offset_cen),
    .ibuff_r_en                     (ibuff_r_en),
    
    // general control signals 
    .init_in_progress               (init_in_progress),
    .job_done                       (job_done)
);

endmodule