module fir_filter #(
    parameter MAX_FILTER_SIZE   = 64,
    parameter INPUT_WIDTH       = 32,
    parameter OUTPUT_WIDTH      = 32,
    parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE)
) (
    input                       clk,
    input                       rst,
    input                       flush_pipeline,
    input                       input_valid,
    input                       init_filter,
    input                       disable_freezing,
    input                       force_freeze,
    input [INPUT_WIDTH-1:0]     fir_input,
    input [FS_WIDTH-1:0]        filter_size,
    input [1:0]                 cur_dec_level,
    input                       downsample,
    output                      output_valid,
    output [OUTPUT_WIDTH-1:0]   fir_output,
    output                      error_flag
);

// get data stage wires
wire [INPUT_WIDTH-1:0]  gd_in_fir_input;
wire [INPUT_WIDTH-1:0]  gd_out_fir_input;
wire [INPUT_WIDTH-1:0]  gd_out_coeff_data;
wire                    gd_out_overwrite;
wire                    gd_out_output_valid;
wire                    gd_out_freeze_pipeline;

// mult stage wires
wire [INPUT_WIDTH-1:0]  ms_in_tap_data;
wire [INPUT_WIDTH-1:0]  ms_in_coeff_data;
wire                    ms_in_overwrite;
wire                    ms_in_output_valid;
wire [OUTPUT_WIDTH-1:0] ms_out_mult_corrected;
wire                    ms_out_overwrite;
wire                    ms_out_output_valid;

// add stage wires
wire [OUTPUT_WIDTH-1:0] as_in_mult_corrected;
wire                    as_in_output_valid;
wire                    as_in_overwrite;
wire [OUTPUT_WIDTH-1:0] as_out_accum_value;
wire                    as_out_overflow;
wire                    as_reg_out_output_valid;
wire [OUTPUT_WIDTH-1:0] as_reg_out_accum_value;

assign output_valid         = as_reg_out_output_valid; 
assign gd_in_fir_input      = fir_input;
assign fir_output           = as_reg_out_accum_value;

fir_filter_get_data_stage #(
    .FS_WIDTH                   (FS_WIDTH),
    .INPUT_WIDTH                (INPUT_WIDTH)
) get_data_stage (
    .clk                        (clk),
    .rst                        (rst),
    .input_valid_in             (input_valid),
    .init_filter_in             (init_filter),
    .flush_pipeline_in          (flush_pipeline),
    .disable_freezing           (disable_freezing),
    .force_freeze               (force_freeze),
    .fir_input_in               (gd_in_fir_input),
    .downsample_in              (downsample),
    .cur_dec_level              (cur_dec_level),
    .filter_size_in             (filter_size),
    .overflow_in                (as_out_overflow),
    .error_flag                 (error_flag),
    .fir_input_out              (gd_out_fir_input),
    .coeff_data_out             (gd_out_coeff_data),
    .overwrite_out              (gd_out_overwrite), 
    .output_valid_out           (gd_out_output_valid),
    .freeze_pipeline_out        (gd_out_freeze_pipeline)
);

fir_filter_gd_ms_reg #(
    .INPUT_WIDTH                (INPUT_WIDTH)
) gd_ms_reg (
    .clk                        (clk),
    .rst                        (rst),
    .freeze                     (gd_out_freeze_pipeline),
    .flush                      (flush_pipeline),
    .fir_input_in               (gd_out_fir_input),
    .coeff_data_in              (gd_out_coeff_data),
    .overwrite_in               (gd_out_overwrite),
    .output_valid_in            (gd_out_output_valid),
    .fir_input_out              (ms_in_tap_data),
    .coeff_data_out             (ms_in_coeff_data),
    .overwrite_out              (ms_in_overwrite),
    .output_valid_out           (ms_in_output_valid)
);

fir_filter_mult_stage #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .OUTPUT_WIDTH               (OUTPUT_WIDTH)
) mult_stage (
    .tap_data_in                (ms_in_tap_data),
    .coeff_data_in              (ms_in_coeff_data),
    .overwrite_in               (ms_in_overwrite),
    .output_valid_in            (ms_in_output_valid),
    .mult_corrected_out         (ms_out_mult_corrected),
    .overwrite_out              (ms_out_overwrite),
    .output_valid_out           (ms_out_output_valid)
);

fir_filter_ms_as_reg #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .OUTPUT_WIDTH               (OUTPUT_WIDTH)
) ms_as_reg (
    .clk                        (clk),
    .rst                        (rst),
    .freeze                     (gd_out_freeze_pipeline),
    .flush                      (flush_pipeline),
    .mult_corrected_in          (ms_out_mult_corrected),
    .overwrite_in               (ms_out_overwrite),
    .output_valid_in            (ms_out_output_valid),
    .mult_corrected_out         (as_in_mult_corrected),
    .overwrite_out              (as_in_overwrite),
    .output_valid_out           (as_in_output_valid)
);

fir_filter_add_stage #(
    .OUTPUT_WIDTH               (OUTPUT_WIDTH)
) add_stage (
    .mult_corrected_in          (as_in_mult_corrected),
    .accum_value_in             (fir_output),
    .output_valid_in            (as_in_output_valid),
    .overwrite_in               (as_in_overwrite),
    .overflow_out               (as_out_overflow),
    .accum_value_out            (as_out_accum_value),
    .output_valid_out           (as_out_output_valid)
);

fir_filter_as_reg #(
    .OUTPUT_WIDTH               (OUTPUT_WIDTH)
) as_reg (
    .clk                        (clk),
    .rst                        (rst),
    .freeze                     (gd_out_freeze_pipeline),
    .flush                      (flush_pipeline),
    .accum_value_in             (as_out_accum_value),
    .output_valid_in            (as_out_output_valid),
    .accum_value_out            (as_reg_out_accum_value),
    .output_valid_out           (as_reg_out_output_valid)
);

endmodule

