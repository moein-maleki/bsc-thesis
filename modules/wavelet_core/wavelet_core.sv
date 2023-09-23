module wavelet_core #(
    parameter INPUT_WIDTH           = 32, 
    parameter IBUFF_CELL_COUNT      = 2048,
    parameter OBUFF_CELL_COUNT      = 4096,
    parameter MAX_FILTER_SIZE       = 32,

    parameter FS_WIDTH              = $clog2(MAX_FILTER_SIZE),
    parameter IBUFF_ADDR_WIDTH      = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH      = $clog2(OBUFF_CELL_COUNT)
) (
    input                       clk,
    input                       rst,

    // cpu bus signals
    input [INPUT_WIDTH-1:0]     core_data_in,
    output [INPUT_WIDTH-1:0]    core_data_out,

    // configurations
    input                       core_go,
    input                       core_init,
    input [FS_WIDTH-1:0]        core_filter_size,
    input [1:0]                 core_dec_level,
    input [1:0]                 core_inputs_len,
    input                       core_downsample,
    input                       core_r_addr_rst,
    output                      core_r_data_available,
    output                      clear_core_go,
    output                      clear_core_init,

    // address decoder wires
    input                       core_input_reg_en,
    input                       core_output_reg_en_pulse
);


wire [1:0]                  cur_dec_level;
wire                        pe_init;
wire                        pe_go;
wire                        pe_job_done;
wire                        cur_dec_level_cen;
wire                        clear_cur_dec_level;
wire                        last_dec_level;
wire                        ibuff_w_sel_obuff_r_data;
wire                        ibuff_w_sel_input_reg;
wire                        ibuff_w_en;
wire                        ibuff_w_offset_cen;
wire                        ibuff_w_offset_rst;
wire                        ibuff_w_base_reg_rst;
wire                        obuff_r_en;
wire                        obuff_r_offset_rst;
wire                        obuff_r_offset_cen;
wire                        obuff_r_base_reg_rst;
wire                        obuff_r_last_input;
wire                        ibuff_w_sel_erase;
wire [IBUFF_ADDR_WIDTH-1:0] ibuff_w_offset;
wire [IBUFF_ADDR_WIDTH-1:0] cur_abs_inputs_len;
wire                        core_r_addr_rst_cu;
wire                        core_r_addr_rst_dp;
wire                        fir_disable_freezing;
wire                        fir_force_freeze;
wire                        pause_work;

assign core_r_addr_rst_dp = core_r_addr_rst_cu | core_r_addr_rst;

wavelet_core_datapath #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
) core_dp (
    .clk                            (clk),
    .rst                            (rst),
    
    // cpu bus
    .core_data_in                    (core_data_in),
    .core_data_out                   (core_data_out),
    
    // config reg signals
    .clear_core_go                  (clear_core_go), 
    .clear_core_init                (clear_core_init), 
    .core_go                        (core_go),
    .core_init                      (core_init),
    .core_filter_size               (core_filter_size),
    .core_dec_level                 (core_dec_level),
    .core_inputs_len                (core_inputs_len),
    .core_downsample                (core_downsample),
    .cur_dec_level                  (cur_dec_level),

    // address decoder wires
    .core_output_reg_en_pulse       (core_output_reg_en_pulse),

    // pe control
    .pe_init                        (pe_init),
    .pe_go                          (pe_go),
    .pe_job_done                    (pe_job_done),
    .fir_disable_freezing           (fir_disable_freezing),
    .fir_force_freeze               (fir_force_freeze),

    // dec_level control
    .cur_dec_level_cen              (cur_dec_level_cen),
    .clear_cur_dec_level            (clear_cur_dec_level),
    .last_dec_level                 (last_dec_level),

    // ibuff signals
    .ibuff_w_sel_obuff_r_data       (ibuff_w_sel_obuff_r_data),
    .ibuff_w_sel_input_reg          (ibuff_w_sel_input_reg),
    .ibuff_w_en                     (ibuff_w_en),
    .ibuff_w_offset_cen             (ibuff_w_offset_cen),
    .ibuff_w_offset_rst             (ibuff_w_offset_rst),
    .ibuff_w_base_reg_rst           (ibuff_w_base_reg_rst),
    .ibuff_w_sel_erase              (ibuff_w_sel_erase),
    .ibuff_w_offset                 (ibuff_w_offset),
    .cur_abs_inputs_len             (cur_abs_inputs_len),

    // obuff signals
    .obuff_r_en                     (obuff_r_en),
    .obuff_r_offset_rst             (obuff_r_offset_rst),
    .obuff_r_offset_cen             (obuff_r_offset_cen),
    .obuff_r_base_reg_rst           (obuff_r_base_reg_rst),
    .obuff_r_service_rst            (core_r_addr_rst_dp),
    .obuff_r_last_input             (obuff_r_last_input),
    .obuff_r_data_available         (core_r_data_available),

    // general
    .pause_work                     (pause_work)
);

wavelet_core_controller #(
    .INPUT_WIDTH                    (INPUT_WIDTH), 
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT               (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)
) core_cu (
    .clk                            (clk),
    .rst                            (rst),
    
    // config signals               
    .core_filter_size               (core_filter_size),
    .core_dec_level                 (core_dec_level),
    .core_inputs_len                (core_inputs_len),
    .core_downsample                (core_downsample),
    .cur_dec_level                  (cur_dec_level),
    
    // config register bits         
    .clear_core_init                (clear_core_init),
    .clear_core_go                  (clear_core_go),
    .core_go                        (core_go),
    .core_init                      (core_init),

    // address decoder wires
    .core_input_reg_en              (core_input_reg_en),
    .core_output_reg_en_pulse       (core_output_reg_en_pulse),
    
    // pe control                   
    .pe_init                        (pe_init),
    .pe_go                          (pe_go),
    .pe_job_done                    (pe_job_done),
    .fir_disable_freezing           (fir_disable_freezing),
    .fir_force_freeze               (fir_force_freeze),
    
    // dec_level control            
    .cur_dec_level_cen              (cur_dec_level_cen),
    .clear_cur_dec_level            (clear_cur_dec_level),
    .last_dec_level                 (last_dec_level),
    
    // ibuff signals                
    .ibuff_w_sel_obuff_r_data       (ibuff_w_sel_obuff_r_data),
    .ibuff_w_sel_input_reg          (ibuff_w_sel_input_reg),
    .ibuff_w_en                     (ibuff_w_en),
    .ibuff_w_offset_cen             (ibuff_w_offset_cen),
    .ibuff_w_offset_rst             (ibuff_w_offset_rst),
    .ibuff_w_base_reg_rst           (ibuff_w_base_reg_rst),
    .ibuff_w_sel_erase              (ibuff_w_sel_erase),
    .ibuff_w_offset                 (ibuff_w_offset),
    .cur_abs_inputs_len             (cur_abs_inputs_len),
    
    // obuff signals                
    .obuff_r_en                     (obuff_r_en),
    .obuff_r_offset_rst             (obuff_r_offset_rst),
    .obuff_r_offset_cen             (obuff_r_offset_cen),
    .obuff_r_base_reg_rst           (obuff_r_base_reg_rst),
    .obuff_r_last_input             (obuff_r_last_input),
    .core_r_addr_rst_cu             (core_r_addr_rst_cu),

    // general signals
    .pause_work                     (pause_work)
);




endmodule