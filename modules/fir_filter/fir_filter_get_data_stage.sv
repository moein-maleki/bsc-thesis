module fir_filter_get_data_stage #(
    parameter FS_WIDTH          = 6,
    parameter INPUT_WIDTH       = 32
) (
    input                       clk,
    input                       rst,

    input                       input_valid_in,
    input                       init_filter_in,
    input                       disable_freezing,
    input                       force_freeze,
    input                       flush_pipeline_in,

    input [INPUT_WIDTH-1:0]     fir_input_in,
    input                       downsample_in,
    input [1:0]                 cur_dec_level,
    input [FS_WIDTH-1:0]        filter_size_in,
    input                       overflow_in,

    output [INPUT_WIDTH-1:0]    fir_input_out,
    output [INPUT_WIDTH-1:0]    coeff_data_out,

    output reg                  error_flag,
    output                      overwrite_out, 
    output                      output_valid_out,
    output                      freeze_pipeline_out
);

    localparam MAX_FILTER_SIZE = 1 << FS_WIDTH;

    wire [FS_WIDTH-1:0]         coeff_addr;
    wire [INPUT_WIDTH-1:0]      coeff_mem_out;
    wire                        last_coeff;
    wire                        batch_first_data;
    wire                        incr_addr;
    wire                        coeff_r_en;
    wire                        coeff_w_en;
    wire                        init_in_progress;
    wire                        sel_zero;
    wire                        input_valid_in_d1;
    wire [INPUT_WIDTH-1:0]      fir_input_in_d1;
    wire                        output_valid;
    wire                        output_valid_d1;
    wire                        overwrite;
    wire                        overwrite_d1;
    wire                        reset_coeff_addr;

    assign overwrite_out        = overwrite_d1; 
    assign output_valid_out     = output_valid_d1; 
    assign freeze_pipeline_out  = (force_freeze) | ((~disable_freezing) & ((~input_valid_in_d1) | (init_filter_in)));
    assign fir_input_out        = fir_input_in_d1;
    assign coeff_data_out       = coeff_mem_out;
    assign reset_coeff_addr     = init_filter_in | flush_pipeline_in;

    always@(posedge clk) begin
        if(rst)                 error_flag <= 0;
        else if (overflow_in)   error_flag <= 1;
    end

    fir_address_generator #(
        .FS_WIDTH               (FS_WIDTH),
        .INPUT_WIDTH            (INPUT_WIDTH)
    ) fir_address_gen (
        .clk                    (clk),
        .rst                    (rst),
        .reset_counter          (reset_coeff_addr),
        .cur_dec_level          (cur_dec_level),
        .downsample             (downsample_in),
        .filter_size            (filter_size_in),
        .incr_addr              (incr_addr),
        .init_in_progress       (init_in_progress),
        .coeff_addr             (coeff_addr),
        .sel_zero               (sel_zero),
        .last_coeff             (last_coeff),
        .batch_first_data       (batch_first_data)
    );

    register #(
        .INPUT_WIDTH            (INPUT_WIDTH)
    ) coeff_w_en_delayer (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              ({(INPUT_WIDTH){1'b0}}),
        .load_data              (1'b1),
        .input_data             (fir_input_in),
        .output_data            (fir_input_in_d1)
    );

    register #(
        .INPUT_WIDTH            (1)
    ) output_valid_delayer (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              (1'b0),
        .load_data              (1'b1),
        .input_data             (output_valid),
        .output_data            (output_valid_d1)
    );

    register #(
        .INPUT_WIDTH            (1)
    ) overwrite_delayer (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              (1'b0),
        .load_data              (1'b1),
        .input_data             (overwrite),
        .output_data            (overwrite_d1)
    );


    register #(
        .INPUT_WIDTH            (1)
    ) coeff_w_addr_delayer (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (1'b0),
        .en                     (1'b1),
        .rst_value              (1'b0),
        .load_data              (1'b1),
        .input_data             (input_valid_in),
        .output_data            (input_valid_in_d1)
    );
    
    register_file #(
        .INPUT_WIDTH            (INPUT_WIDTH),
        .CELL_COUNT             (MAX_FILTER_SIZE)
    ) coeff_mem (
        .clk                    (clk),
        .rst                    (rst),
        .w_en_in                (coeff_w_en),
        .w_addr_in              (coeff_addr),
        .w_data_in              (fir_input_in),
        .r_en_in                (coeff_r_en),
        .r_addr_in              (coeff_addr),
        .r_data_out             (coeff_mem_out)
    );

    fir_filter_controller fir_cu(
        .clk                    (clk),
        .rst                    (rst),
        .input_valid            (input_valid_in),
        .input_valid_d1         (input_valid_in_d1),
        .init_filter            (init_filter_in),
        .last_coeff             (last_coeff),
        .batch_first_data       (batch_first_data), //addr == 0
        .overwrite              (overwrite),
        .incr_addr              (incr_addr),
        .output_valid           (output_valid),
        .coeff_r_en             (coeff_r_en),
        .coeff_w_en             (coeff_w_en),
        .init_in_progress       (init_in_progress)
    );

endmodule