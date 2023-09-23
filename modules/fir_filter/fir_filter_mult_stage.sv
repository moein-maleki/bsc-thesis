module fir_filter_mult_stage #(
    parameter INPUT_WIDTH = 32,
    parameter OUTPUT_WIDTH = 32
) (
    input [INPUT_WIDTH-1:0] tap_data_in,
    input [INPUT_WIDTH-1:0] coeff_data_in,
    input overwrite_in,
    input output_valid_in,

    output [OUTPUT_WIDTH-1:0] mult_corrected_out,
    output overwrite_out,
    output output_valid_out
);

    wire [2*INPUT_WIDTH-1:0] mult_out;
    wire [OUTPUT_WIDTH-1:0] mult_corrected;


    assign overwrite_out = overwrite_in; 
    assign output_valid_out = output_valid_in;  
    assign mult_corrected_out = mult_corrected + 1;

    multiplier #(
        .INPUT_WIDTH            (INPUT_WIDTH)
    ) mult_unit (
        .data_ina               (tap_data_in),
        .data_inb               (coeff_data_in),
        .result                 (mult_out)
    );

    // assign mult_corrected = mult_out[62:31] + 32'b1;

    fir_filter_percision_modder #(
        .INPUT_WIDTH            (2*INPUT_WIDTH),
        .OUTPUT_WIDTH           (OUTPUT_WIDTH),
        .OFFSET_BITS            (1)
    ) bpm (
        .bus_in                 (mult_out),
        .bus_out                (mult_corrected)
    );

endmodule