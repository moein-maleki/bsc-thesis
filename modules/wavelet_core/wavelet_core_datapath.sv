module wavelet_core_datapath #(
    parameter INPUT_WIDTH           = 32, 
    parameter IBUFF_CELL_COUNT      = 2048,
    parameter OBUFF_CELL_COUNT      = 4096,
    parameter MAX_FILTER_SIZE       = 32,

    parameter FS_WIDTH              = $clog2(MAX_FILTER_SIZE),
    parameter IBUFF_ADDR_WIDTH      = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH      = $clog2(OBUFF_CELL_COUNT)
) (
    input                           clk,
    input                           rst,
    
    // cpu bus
    input [INPUT_WIDTH-1:0]         core_data_in,
    output [INPUT_WIDTH-1:0]        core_data_out,

    // configurations
    input [FS_WIDTH-1:0]            core_filter_size,
    input                           core_go,
    input                           core_init,
    input                           core_downsample,
    input [1:0]                     core_dec_level,
    input [1:0]                     core_inputs_len,

    // decoder
    input                           core_output_reg_en_pulse,
    
    // config reg signals
    input                           clear_core_go,
    input                           clear_core_init,
    output [1:0]                    cur_dec_level,

    // pe control
    input                           pe_init,
    input                           pe_go,
    input                           fir_disable_freezing,
    input                           fir_force_freeze,
    output                          pe_job_done,

    // dec_level control
    input                           cur_dec_level_cen,
    input                           clear_cur_dec_level,
    output                          last_dec_level,

    // ibuff signals
    input                           ibuff_w_sel_obuff_r_data,
    input                           ibuff_w_sel_input_reg,
    input                           ibuff_w_en,
    input                           ibuff_w_offset_cen,
    input                           ibuff_w_offset_rst,
    input                           ibuff_w_base_reg_rst,
    input                           ibuff_w_sel_erase,
    output [IBUFF_ADDR_WIDTH-1:0]   ibuff_w_offset,
    output [IBUFF_ADDR_WIDTH-1:0]   cur_abs_inputs_len,

    // obuff signals
    input                           obuff_r_en,
    input                           obuff_r_offset_rst,
    input                           obuff_r_offset_cen,
    input                           obuff_r_base_reg_rst,
    input                           obuff_r_service_rst,
    output                          obuff_r_last_input,
    output                          obuff_r_data_available,

    // general signals
    output                          pause_work
);

// ibuff signals
wire [INPUT_WIDTH-1:0]          ibuff_w_data;
wire [IBUFF_ADDR_WIDTH-1:0]     ibuff_w_base_reg_init_value;
wire [IBUFF_ADDR_WIDTH-1:0]     ibuff_w_addr;
wire [IBUFF_ADDR_WIDTH-1:0]     ibuff_w_offset_max_count;
wire                            ibuff_w_done;
wire                            ibuff_r_en;
wire [IBUFF_ADDR_WIDTH-1:0]     ibuff_r_addr;
wire [INPUT_WIDTH-1:0]          ibuff_r_data;
wire                            ibuff_w_en_d1;
wire [11:0]                     ibuff_w_addr_d1;
wire [31:0]                     ibuff_w_data_d1;
wire                            ibuff_r_data_available;


// obuff signals
wire                            obuff_w_en;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_addr;
wire [INPUT_WIDTH-1:0]          obuff_w_data;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_lp_abs_address;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_approx_addr;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_r_addr;
wire [INPUT_WIDTH-1:0]          obuff_r_data;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_r_base_reg_init_value;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_r_offset;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_last_output;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_r_addr_;
wire                            obuff_r_en_;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_hp_address;
wire                            obuff_r_service_cen;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_r_service_addr;


// general signals
wire [IBUFF_ADDR_WIDTH-1:0]     cur_inputs_len;
wire [OBUFF_ADDR_WIDTH-1:0]     cur_outputs_len;
wire [OBUFF_ADDR_WIDTH-1:0]     prev_outputs_len;   
wire [IBUFF_ADDR_WIDTH-1:0]     core_filter_size_;
wire                            core_ready_to_be_read;
wire                            core_output_reg_en_pulse_d1;
wire                            core_output_reg_en_pulse_dp;

// ibuff signals 
assign ibuff_w_offset_max_count = (core_init) ? (cur_inputs_len) : (core_go) ? (cur_inputs_len + core_filter_size_ ) : (0);
assign ibuff_w_base_reg_init_value  = (core_init) ? ({(IBUFF_ADDR_WIDTH){1'b0}}) : (core_filter_size);
assign ibuff_w_data                 =
    (ibuff_w_sel_erase)         ? ({(INPUT_WIDTH){1'b0}})   :
    (ibuff_w_sel_obuff_r_data)  ? (obuff_r_data)            :
    (ibuff_w_sel_input_reg)     ? (core_data_in)             : ({(INPUT_WIDTH){1'bz}});
assign ibuff_r_data_available       = (ibuff_r_addr < ibuff_w_addr);

// obuff signals
assign obuff_r_base_reg_init_value  = obuff_w_approx_addr;
assign obuff_r_data_available       = (
        (obuff_r_service_addr >= obuff_w_approx_addr) & (obuff_r_service_addr < obuff_last_output)
    ) | (obuff_r_service_addr < obuff_w_hp_address);
assign obuff_r_en_                  = obuff_r_en | core_output_reg_en_pulse_dp;
assign obuff_r_addr_                = (core_output_reg_en_pulse_dp) ? (obuff_r_service_addr) : (obuff_r_addr);
assign obuff_r_service_cen          = (core_output_reg_en_pulse_dp);

// general signals
assign core_data_out                = obuff_r_data;
assign core_filter_size_            = core_filter_size;
assign core_output_reg_en_pulse_dp  = (core_output_reg_en_pulse) & (obuff_r_data_available);

assign pause_work = core_output_reg_en_pulse_dp | core_output_reg_en_pulse_d1;

register #(
    .INPUT_WIDTH            (1)
) output_reg_en_pulse_reg (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (1'b1),
    .input_data             (core_output_reg_en_pulse_dp),
    .output_data            (core_output_reg_en_pulse_d1)
);

wavelet_core_io_len #(
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT)
) io_len (
    .clk                            (clk),
    .rst                            (rst),
    .core_dec_level                 (core_dec_level),
    .core_inputs_len                (core_inputs_len),
    .core_filter_size               (core_filter_size_),
    .core_downsample                (core_downsample),
    .cur_dec_level                  (cur_dec_level),
    .cur_outputs_len                (cur_outputs_len),
    .cur_inputs_len                 (cur_inputs_len),
    .cur_inputs_len_abs             (cur_abs_inputs_len),
    .obuff_w_approx_addr            (obuff_w_approx_addr),
    .core_init                      (core_init),
    .prev_outputs_len               (prev_outputs_len),
    .obuff_last_output              (obuff_last_output)
);

counter #(
    .COUNTER_WIDTH                  (2)
) dec_level_counter (
    .clk                            (clk),
    .rst                            (rst),
    .manual_rst                     (clear_cur_dec_level),
    .count_up                       (1'b1),
    .enable_counter                 (cur_dec_level_cen),
    .max_count                      (core_dec_level),
    .count_value                    (cur_dec_level),
    .co                             (last_dec_level)
);

// register_file_ip ibuff_m4k(
// 	.clock                          (clk),
// 	.data                           (ibuff_w_data),
// 	.rdaddress                      (ibuff_r_addr),
// 	.rden                           (ibuff_r_en),
// 	.wraddress                      (ibuff_w_addr),
// 	.wren                           (ibuff_w_en),
// 	.q                              (ibuff_r_data)
// );

register_file #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .CELL_COUNT                     (IBUFF_CELL_COUNT)
) ibuff (
    .clk                            (clk),
    .rst                            (rst),
    .w_en_in                        (ibuff_w_en),
    .w_addr_in                      (ibuff_w_addr),
    .w_data_in                      (ibuff_w_data),
    .r_en_in                        (ibuff_r_en),
    .r_addr_in                      (ibuff_r_addr),
    .r_data_out                     (ibuff_r_data)
);

// register_file_ip obuff_m4k(
// 	.clock                          (clk),
// 	.data                           (obuff_w_data),
// 	.rdaddress                      (obuff_r_addr_),
// 	.rden                           (obuff_r_en_),
// 	.wraddress                      (obuff_w_addr),
// 	.wren                           (obuff_w_en),
// 	.q                              (obuff_r_data)
// );

register_file #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .CELL_COUNT                     (OBUFF_CELL_COUNT)
) obuff (
    .clk                            (clk),
    .rst                            (rst),
    .w_en_in                        (obuff_w_en),
    .w_addr_in                      (obuff_w_addr),
    .w_data_in                      (obuff_w_data),
    .r_en_in                        (obuff_r_en_),
    .r_addr_in                      (obuff_r_addr_),
    .r_data_out                     (obuff_r_data)
);

wavelet_pe #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
) pe (
    .clk                            (clk),
    .rst                            (rst),

    // core signals
    .pe_init                        (pe_init),
    .pe_go                          (pe_go),
    .ibuff_r_data_available         (ibuff_r_data_available),
    .fir_force_freeze               (fir_force_freeze),
    .fir_disable_freezing           (fir_disable_freezing),

    // general configuration signals
    .core_downsample                (core_downsample),
    .core_dec_level                 (core_dec_level),
    .core_filter_size               (core_filter_size),
    .core_inputs_len                (core_inputs_len),
    .cur_dec_level                  (cur_dec_level),
    .cur_inputs_len                 (cur_inputs_len),
    .cur_outputs_len                (cur_outputs_len),
    .prev_outputs_len               (prev_outputs_len),

    // ibuff read port
    .ibuff_r_data                   (ibuff_r_data),
    .ibuff_r_addr                   (ibuff_r_addr),
    .ibuff_r_en                     (ibuff_r_en),

    // obuff write port
    .obuff_w_approx_addr            (obuff_w_approx_addr),
    .obuff_w_addr                   (obuff_w_addr),
    .obuff_w_data                   (obuff_w_data),
    .obuff_w_en                     (obuff_w_en),
    .obuff_w_lp_abs_address         (obuff_w_lp_abs_address),
    .obuff_w_hp_address             (obuff_w_hp_address),

    .job_done                       (pe_job_done)
);


address_generator #(
    .CELL_COUNT                     (IBUFF_CELL_COUNT),
    .MAX_OFFSET                     (IBUFF_CELL_COUNT)
) ibuff_w_address_gen (
    .clk                            (clk),
    .rst                            (rst),
    .offset_rst                     (ibuff_w_offset_rst),
    .offset_upcount                 (1'b1),
    .offset_cen                     (ibuff_w_offset_cen),
    .offset_max_count               (ibuff_w_offset_max_count),
    .base_reg_rst                   (ibuff_w_base_reg_rst),
    .base_reg_init_value            (ibuff_w_base_reg_init_value),
    .base_reg_in                    (ibuff_w_base_reg_init_value),
    .offset_co                      (ibuff_w_done),
    .offset                         (ibuff_w_offset),
    .base_reg_out                   (),
    .addr                           (ibuff_w_addr)
);

address_generator #(
    .CELL_COUNT                     (OBUFF_CELL_COUNT),
    .MAX_OFFSET                     (OBUFF_CELL_COUNT)
) obuff_r_labour_address_gen (
    .clk                            (clk),
    .rst                            (rst),
    .offset_rst                     (obuff_r_offset_rst),
    .offset_upcount                 (1'b1),
    .offset_cen                     (obuff_r_offset_cen),
    .offset_max_count               (prev_outputs_len),
    .base_reg_rst                   (obuff_r_base_reg_rst),
    .base_reg_init_value            (obuff_r_base_reg_init_value),
    .base_reg_in                    (obuff_r_base_reg_init_value),
    .offset_co                      (obuff_r_last_input),
    .offset                         (obuff_r_offset),
    .base_reg_out                   (),
    .addr                           (obuff_r_addr)
);

counter #(
    .COUNTER_WIDTH                  (OBUFF_ADDR_WIDTH)
) obuff_r_service_address_gen (
    .clk                            (clk),
    .rst                            (rst),
    .manual_rst                     (obuff_r_service_rst),
    .count_up                       (1'b1),
    .enable_counter                 (obuff_r_service_cen),
    .max_count                      (obuff_last_output),
    .count_value                    (obuff_r_service_addr),
    .co                             ()
);


endmodule