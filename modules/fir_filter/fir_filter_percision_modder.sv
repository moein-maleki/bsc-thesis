module fir_filter_percision_modder #(
    parameter OFFSET_BITS = 1, // number of extra bits to the left of data, til the fractions begin
    parameter INPUT_WIDTH = 64,
    parameter OUTPUT_WIDTH = 32
) (
    input           [INPUT_WIDTH-1:0] bus_in,

    output          [OUTPUT_WIDTH-1:0] bus_out    
);

localparam START_BIT =
    (INPUT_WIDTH == OUTPUT_WIDTH) ? (INPUT_WIDTH-1) : (INPUT_WIDTH-1-OFFSET_BITS);
localparam END_BIT =
    (INPUT_WIDTH > OUTPUT_WIDTH) ? (INPUT_WIDTH-OFFSET_BITS-OUTPUT_WIDTH) : (0);
    
assign bus_out = bus_in[START_BIT:END_BIT] + 1;

// assign bus_out = (INPUT_WIDTH > OUTPUT_WIDTH) ?
//     (
//         bus_in[INPUT_WIDTH-1-OFFSET_BITS : INPUT_WIDTH-OFFSET_BITS-OUTPUT_WIDTH]
//     ) : (INPUT_WIDTH == OUTPUT_WIDTH) ? (bus_in) :
//     (
//         (bus_in[INPUT_WIDTH-1]) ?
//         ({bus_in[INPUT_WIDTH-1-OFFSET_BITS:0], {(OUTPUT_WIDTH-INPUT_WIDTH){1'b0}}}) :
//         ({bus_in[INPUT_WIDTH-1-OFFSET_BITS:0], {(OUTPUT_WIDTH-INPUT_WIDTH){1'b1}}})
//     );  

endmodule
