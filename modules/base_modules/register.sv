module register #(
    parameter INPUT_WIDTH = 32
) (
    input                           clk,
    input                           rst,
    input                           manual_rst,
    input                           en,
    input       [INPUT_WIDTH-1:0]   rst_value,
    input                           load_data,
    input       [INPUT_WIDTH-1:0]   input_data,

    output reg  [INPUT_WIDTH-1:0]   output_data
);

    wire sync_rst;

    assign sync_rst = manual_rst | rst;

    always @(posedge clk) begin
        if(sync_rst)                output_data <= rst_value;
        else if(en)
            if(load_data)           output_data <= input_data;
        else                        output_data <= output_data;
    end

endmodule