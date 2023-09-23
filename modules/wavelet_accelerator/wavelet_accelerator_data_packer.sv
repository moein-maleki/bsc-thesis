module wavelet_accelerator_data_packer #(
    parameter INPUT_WIDTH = 32,
    parameter PACKET_WIDTH = 8 
) (
    input                       clk,
    input                       rst,
    
    input                       en,
    input [1:0]                 byte_offset,
    input [PACKET_WIDTH-1:0]    data_in,

    output [INPUT_WIDTH-1:0]    data_out
);

wire [PACKET_WIDTH-1:0] p00;
wire [PACKET_WIDTH-1:0] p01;
wire [PACKET_WIDTH-1:0] p10;
wire [PACKET_WIDTH-1:0] p11;

wire [PACKET_WIDTH-1:0] p00_;
wire [PACKET_WIDTH-1:0] p01_;
wire [PACKET_WIDTH-1:0] p10_;
wire [PACKET_WIDTH-1:0] p11_;

wire b00;
wire b01;
wire b10;
wire b11;

assign b00 = (en) & (byte_offset == 2'b00);
assign b01 = (en) & (byte_offset == 2'b01);
assign b10 = (en) & (byte_offset == 2'b10);
assign b11 = (en) & (byte_offset == 2'b11);

assign p00 = (byte_offset == 2'b00) ? (data_in) : (8'bz);
assign p01 = (byte_offset == 2'b01) ? (data_in) : (8'bz);
assign p10 = (byte_offset == 2'b10) ? (data_in) : (8'bz);
assign p11 = (byte_offset == 2'b11) ? (data_in) : (8'bz);

assign data_out = {p11_, p10_, p01_, p00_};

register #(
    .INPUT_WIDTH            (8)
) reg00 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              (8'b0),
    .load_data              (b00),
    .input_data             (p00),
    .output_data            (p00_)
);

register #(
    .INPUT_WIDTH            (8)
) reg01 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              (8'b0),
    .load_data              (b01),
    .input_data             (p01),
    .output_data            (p01_)
);

register #(
    .INPUT_WIDTH            (8)
) reg10 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              (8'b0),
    .load_data              (b10),
    .input_data             (p10),
    .output_data            (p10_)
);

register #(
    .INPUT_WIDTH            (8)
) reg11 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              (8'b0),
    .load_data              (b11),
    .input_data             (p11),
    .output_data            (p11_)
);

endmodule