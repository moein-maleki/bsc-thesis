module adder #(
    parameter INPUT_WIDTH = 32
) (
    input signed  [INPUT_WIDTH-1:0] data_ina,
    input signed  [INPUT_WIDTH-1:0] data_inb,
    input                           carry_in,
    
    output signed [INPUT_WIDTH-1:0] result,
    output                          carry_out,
    output                          overflow
);
    
    assign {carry_out, result} = data_ina + data_inb + carry_in;

    assign overflow =
        (data_ina[INPUT_WIDTH-1] == data_inb[INPUT_WIDTH-1]) &
        (result[INPUT_WIDTH-1] != data_inb[INPUT_WIDTH-1]);

endmodule
