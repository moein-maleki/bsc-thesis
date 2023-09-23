module fir_filter_add_stage #(
    parameter OUTPUT_WIDTH      = 32
) (
    input [OUTPUT_WIDTH-1:0] mult_corrected_in,
    input [OUTPUT_WIDTH-1:0] accum_value_in,
    input output_valid_in,
    input overwrite_in,
    
    output [OUTPUT_WIDTH-1:0] accum_value_out,
    output overflow_out,
    output output_valid_out
);

    wire [OUTPUT_WIDTH-1:0] adder_result;
    wire [OUTPUT_WIDTH-1:0] adder_input_a;
    
    assign output_valid_out = output_valid_in;
    assign accum_value_out = (overwrite_in) ? (mult_corrected_in) : (adder_result);
    assign adder_input_a = (overwrite_in) ? (0) : (mult_corrected_in);  

    adder #(
        .INPUT_WIDTH            (OUTPUT_WIDTH)
    ) adder_unit (
        .data_ina               (adder_input_a),
        .data_inb               (accum_value_in),
        .carry_in               (1'b0),
        .result                 (adder_result),
        .carry_out              (),
        .overflow               (overflow_out)
    );

endmodule