module fir_filter_ms_as_reg #(
    parameter INPUT_WIDTH = 32,
    parameter OUTPUT_WIDTH = 32
) (
    input                       clk,
    input                       rst,
    input                       freeze,
    input                       flush,

    input [OUTPUT_WIDTH-1:0]    mult_corrected_in,
    input                       overwrite_in,
    input                       output_valid_in,

    output reg [OUTPUT_WIDTH-1:0] mult_corrected_out,
    output reg                  overwrite_out,
    output reg                  output_valid_out
);

    always@(posedge clk) begin
        if(rst | flush) begin
            mult_corrected_out      <= 0;
            overwrite_out           <= 0;
            output_valid_out        <= 0;
        end
        else if(~freeze) begin
            mult_corrected_out      <= mult_corrected_in;
            overwrite_out           <= overwrite_in;
            output_valid_out        <= output_valid_in;
        end
    end

endmodule