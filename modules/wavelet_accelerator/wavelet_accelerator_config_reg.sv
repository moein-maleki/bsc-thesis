module wavelet_accelerator_config_reg #(
    parameter PACKET_WIDTH = 8
) (
    input                       clk,
    input                       rst,

    // addr decoder wires
    input [PACKET_WIDTH-1:0]    data_in,
    input [1:0]                 byte_offset,
    input                       en,

    // core controller singals
    input                       core_clear_go,
    input                       core_clear_init,
    input                       core_r_data_available,

    // configs
    output                      core_go,
    output                      core_init,
    output                      core_r_addr_rst,
    output [1:0]                core_inputs_len,
    output [1:0]                core_dec_level,
    output [4:0]                core_filter_size,
    
    output [15:0]               config_reg_out
); 

wire [15:0]     config_reg_in;
wire            config_reg_load;
wire [7:0]      config_reg_00;
wire [7:0]      config_reg_01;
wire            reg_00_en;
wire            reg_01_en;
wire            core_r_data_available_d1;
wire            core_ready_set;
wire            core_ready_clear;
wire [7:0]      data_00_in_masked;
wire [7:0]      data_01_in_masked;
wire            core_ready;


assign config_reg_load = (
    core_clear_go |
    core_clear_init |
    core_ready_set |
    core_ready_clear |
    core_r_addr_rst
    );

assign reg_00_en = (en) & (byte_offset == 2'b00);
assign reg_01_en = (en) & (byte_offset == 2'b01);

assign data_00_in_masked =
    (config_reg_load)   ? ({config_reg_in[7:0]}) :
    (core_go)           ? ({core_ready, core_dec_level, core_inputs_len, data_in[2], core_init, 1'b1}) :
    (core_init)         ? ({core_ready, core_dec_level, core_inputs_len, core_r_addr_rst, 1'b1, data_in[0]}) : ({1'b0, data_in[6:0]});
assign data_01_in_masked = (core_init | core_go) ? ({3'b0, core_filter_size}) : {3'b0, data_in[4:0]};

assign core_ready_set       = (core_r_data_available == 1'b1) & (core_r_data_available_d1 == 1'b0);
assign core_ready_clear     = (core_r_data_available == 1'b0) & (core_r_data_available_d1 == 1'b1);

assign config_reg_in        =
    (core_clear_go)     ? ({config_reg_out[15:1], 1'b0}) :
    (core_clear_init)   ? ({config_reg_out[15:2], 1'b0, config_reg_out[0]}) :
    (core_ready_set)    ? ({config_reg_out[15:8], 1'b1, config_reg_out[6:0]}) :
    (core_ready_clear)  ? ({config_reg_out[15:8], 1'b0, config_reg_out[6:0]}) :
    (core_r_addr_rst)   ? ({config_reg_out[15:3], 1'b0, config_reg_out[1:0]}) :
    (config_reg_out); 

assign core_go                  = config_reg_out[0];
assign core_init                = config_reg_out[1];
assign core_r_addr_rst          = config_reg_out[2];
assign core_inputs_len          = config_reg_out[4:3];
assign core_dec_level           = config_reg_out[6:5];
assign core_ready               = config_reg_out[7];
assign core_filter_size         = config_reg_out[12:8];
assign config_reg_out           = {config_reg_01, config_reg_00};

register #(
    .INPUT_WIDTH            (1)
) r_data_available_pulsor (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (~core_r_data_available),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (core_r_data_available),
    .input_data             (1'b1),
    .output_data            (core_r_data_available_d1)
);

register #(
    .INPUT_WIDTH            (8)
) reg00 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en | config_reg_load),
    .rst_value              (8'b0),
    .load_data              (reg_00_en | config_reg_load),
    .input_data             (data_00_in_masked),
    .output_data            (config_reg_00)
);

register #(
    .INPUT_WIDTH            (8)
) reg01 (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (en),
    .rst_value              (8'b0),
    .load_data              (reg_01_en),
    .input_data             (data_01_in_masked),
    .output_data            (config_reg_01)
);

endmodule