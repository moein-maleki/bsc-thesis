module fir_filter_gd_ms_reg #(
    parameter INPUT_WIDTH       = 32
) (
    input                       clk,
    input                       rst,
    input                       freeze,
    input                       flush,

    input [INPUT_WIDTH-1:0]     fir_input_in,
    input [INPUT_WIDTH-1:0]     coeff_data_in,
    input                       overwrite_in,
    input                       output_valid_in,

    output reg [INPUT_WIDTH-1:0] fir_input_out,
    output reg [INPUT_WIDTH-1:0] coeff_data_out,
    output reg                  overwrite_out,
    output reg                  output_valid_out
);

    always@(posedge clk) begin
        if(rst | flush) begin
            fir_input_out           <= 0;
            coeff_data_out          <= 0;
            overwrite_out           <= 0;
            output_valid_out        <= 0;
        end
        else if(~freeze) begin
            fir_input_out           <= fir_input_in;
            coeff_data_out          <= coeff_data_in;
            overwrite_out           <= overwrite_in;
            output_valid_out        <= output_valid_in;
        end
    end

endmodule