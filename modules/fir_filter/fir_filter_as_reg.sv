module fir_filter_as_reg #(
    parameter OUTPUT_WIDTH       = 32
) (
    input                       clk,
    input                       rst,
    input                       freeze,
    input                       flush,

    input [OUTPUT_WIDTH-1:0]    accum_value_in,
    input                       output_valid_in,
    
    output reg [OUTPUT_WIDTH-1:0] accum_value_out,
    output reg                  output_valid_out
);

    always@(posedge clk) begin
        if(rst | flush) begin
            accum_value_out         <= 0;
            output_valid_out        <= 0;
        end
        else if(~freeze) begin
            accum_value_out         <= accum_value_in;
            output_valid_out        <= output_valid_in;
        end
    end

endmodule