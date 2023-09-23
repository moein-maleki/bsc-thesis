module wavelet_accelerator_data_deployer #(
    parameter INPUT_WIDTH = 32,
    parameter PACKET_WIDTH = 8 
) (
    input                       clk,
    input                       rst,
    input                       load_data,

    input                       en,
    input [1:0]                 byte_offset,
    input [INPUT_WIDTH-1:0]     data_in,

    output [PACKET_WIDTH-1:0]   data_out
);

wire [INPUT_WIDTH-1:0] internal_data;

register #(
    .INPUT_WIDTH            (INPUT_WIDTH)
) deploy_register (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              ({(INPUT_WIDTH){1'b0}}),
    .load_data              (load_data),
    .input_data             (data_in),
    .output_data            (internal_data)
);

assign data_out = (en) ? (
    (byte_offset == 2'b00) ? (data_in[7:0]) : 
    (byte_offset == 2'b01) ? (internal_data[15:8]) : 
    (byte_offset == 2'b10) ? (internal_data[23:16]) : 
    (byte_offset == 2'b11) ? (internal_data[31:24]) : ({(PACKET_WIDTH){1'bz}}) 
) : ({(PACKET_WIDTH){1'bz}});

endmodule