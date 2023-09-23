module multiplier #(
    parameter INPUT_WIDTH = 32
) (
    input signed        [INPUT_WIDTH-1:0] data_ina,
    input signed        [INPUT_WIDTH-1:0] data_inb,

    output signed       [2*INPUT_WIDTH-1:0] result
);

    assign result = data_ina * data_inb;

endmodule
