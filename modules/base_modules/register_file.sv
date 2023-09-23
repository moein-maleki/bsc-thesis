module register_file #(
    parameter INPUT_WIDTH       = 32,
    parameter CELL_COUNT        = 64,
    
    parameter ADDR_LINE_WIDTH = $clog2(CELL_COUNT - 1)
) (
    input                               clk,
    input                               rst,

    // write port
    input                               w_en_in,
    input       [ADDR_LINE_WIDTH-1:0]   w_addr_in,
    input       [INPUT_WIDTH-1:0]       w_data_in,

    // read port
    input                               r_en_in,
    input       [ADDR_LINE_WIDTH-1:0]   r_addr_in,
    output reg  [INPUT_WIDTH-1:0]       r_data_out
);

integer i = 0;
(* ramstyle = "M4K" *) reg [INPUT_WIDTH-1:0] mem [0:CELL_COUNT-1];

always @(posedge clk) begin
    if(rst) r_data_out <= {(INPUT_WIDTH){1'bz}};
    else begin
        if(w_en_in) mem[w_addr_in] <= w_data_in;
        if(r_en_in) r_data_out <= mem[r_addr_in];
        else        r_data_out <= {(INPUT_WIDTH){1'bz}};
    end
end

endmodule
