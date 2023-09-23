module wavelet_accelerator #(
    parameter INPUT_WIDTH           = 32, 
    parameter IBUFF_CELL_COUNT      = 4096,
    parameter OBUFF_CELL_COUNT      = 4096,

    parameter DATA_BUS_WIDTH        = 8,
    parameter ADDR_BUS_WIDTH        = 32,
    parameter BASE_ADDRESS          = 32'h1A100000,
    parameter CONFIG_REG_OFFSET     = 2'b00,
    parameter INPUT_REG_OFFSET      = 2'b01,
    parameter OUTPUT_REG_OFFSET     = 2'b10
) (
    input clk,
    input rst,

    // cpu bus interface
    input [DATA_BUS_WIDTH-1:0]      cpu_data_in,
    input [ADDR_BUS_WIDTH-1:0]      cpu_addr_in,
    input                           cpu_read_en_in,
    input                           cpu_write_en_in,
    output [DATA_BUS_WIDTH-1:0]     cpu_data_out,
    inout                           cpu_data_ready
);

localparam MAX_FILTER_SIZE       = 32;
localparam FS_WIDTH              = $clog2(MAX_FILTER_SIZE);

// core inputs
wire                        core_go;
wire                        core_init;
wire [FS_WIDTH-1:0]         core_filter_size;
wire [1:0]                  core_dec_level;
wire [1:0]                  core_inputs_len;
wire                        core_downsample;
wire                        core_r_addr_rst;
wire                        core_input_reg_w_en;
wire                        core_output_reg_r_en;

// core outputs
wire                        core_clear_go;
wire                        core_clear_init;
wire                        core_r_data_available;
wire [INPUT_WIDTH-1:0]      core_data_out;

// general wires
wire                        config_reg_en;
wire                        input_reg_en;
wire                        output_reg_en;
wire                        core_config_reg_r_en;
wire                        core_config_reg_w_en;
wire [INPUT_WIDTH-1:0]      input_reg_out;
wire [15:0]                 config_reg_out;
wire [INPUT_WIDTH-1:0]      out_signal;
wire [7:0]                  deployer_out;
wire                        accel_talk;
wire                        accel_talk_d1;
wire                        accel_talk_pulse;
wire                        core_output_reg_r_en_d1;
wire                        core_output_reg_en_pulse;

// cpu signals
assign cpu_data_ready = (core_output_reg_en_pulse) ? (1'b0) : (accel_talk) ? ((cpu_read_en_in) ? (1'b1) : (1'bz)) : (1'bz); 
assign cpu_data_out = (accel_talk) ? ((cpu_read_en_in) ? (deployer_out) : (8'bz)) : (8'bz);

// core signals
assign core_output_reg_r_en     = (output_reg_en) & (cpu_read_en_in);
assign core_input_reg_w_en      = (input_reg_en) & (cpu_write_en_in);
assign core_config_reg_r_en     = (config_reg_en) & (cpu_read_en_in);
assign core_config_reg_w_en     = (config_reg_en) & (cpu_write_en_in);
assign core_downsample          = 1'b1;

// internal signals
assign accel_talk               = (core_output_reg_r_en_d1) | (core_config_reg_r_en);
assign out_signal               =
    (core_output_reg_r_en_d1)   ? (core_data_out)           :
    (core_config_reg_r_en)      ? ({16'b0, config_reg_out}) : {(INPUT_WIDTH){1'bz}};
assign core_output_reg_en_pulse = (core_output_reg_r_en == 1'b1) & (core_output_reg_r_en_d1 == 1'b0);
assign accel_talk_pulse         = (accel_talk == 1'b1) & (accel_talk_d1 == 1'b0);

wavelet_accelerator_address_decoder #(
    .ADDR_BUS_WIDTH             (ADDR_BUS_WIDTH),
    .BASE_ADDRESS               (BASE_ADDRESS),
    .CONFIG_REG_OFFSET          (CONFIG_REG_OFFSET),
    .INPUT_REG_OFFSET           (INPUT_REG_OFFSET),
    .OUTPUT_REG_OFFSET          (OUTPUT_REG_OFFSET)       
) address_decoder_ (
    .cpu_addr                   (cpu_addr_in),
    .cpu_read_en                (cpu_read_en_in),
    .cpu_write_en               (cpu_write_en_in),
    .config_reg_en              (config_reg_en),
    .input_reg_en               (input_reg_en),
    .output_reg_en              (output_reg_en)
);

wavelet_accelerator_data_deployer #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .PACKET_WIDTH               (DATA_BUS_WIDTH) 
) deployer (
    .clk                        (clk),
    .rst                        (rst),
    .load_data                  (accel_talk_pulse),
    .en                         (accel_talk),
    .byte_offset                (cpu_addr_in[1:0]),
    .data_in                    (out_signal),
    .data_out                   (deployer_out)
);

wavelet_accelerator_data_packer #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .PACKET_WIDTH               (DATA_BUS_WIDTH) 
) input_reg (
    .clk                        (clk),
    .rst                        (rst),
    .en                         (core_input_reg_w_en),
    .byte_offset                (cpu_addr_in[1:0]),
    .data_in                    (cpu_data_in),
    .data_out                   (input_reg_out)
);

wavelet_accelerator_config_reg #(
    .PACKET_WIDTH               (DATA_BUS_WIDTH)
) config_reg (
    .clk                        (clk),
    .rst                        (rst),

    // addr decoder wires
    .data_in                    (cpu_data_in),
    .byte_offset                (cpu_addr_in[1:0]),
    .en                         (core_config_reg_w_en),

    // core controller singals
    .core_clear_go              (core_clear_go),
    .core_clear_init            (core_clear_init),
    .core_r_data_available      (core_r_data_available),

    // configs
    .core_go                    (core_go),
    .core_init                  (core_init),
    .core_r_addr_rst            (core_r_addr_rst),
    .core_inputs_len            (core_inputs_len),
    .core_dec_level             (core_dec_level),
    .core_filter_size           (core_filter_size), 
    .config_reg_out             (config_reg_out)
);

register #(
    .INPUT_WIDTH                (1)
) output_reg_en_pulsor (
    .clk                        (clk),
    .rst                        (rst),
    .manual_rst                 (~core_output_reg_r_en),
    .en                         (1'b1),
    .rst_value                  (1'b0),
    .load_data                  (core_output_reg_r_en),
    .input_data                 (core_output_reg_r_en),
    .output_data                (core_output_reg_r_en_d1)
);

register #(
    .INPUT_WIDTH                (1)
) cpu_ready_pulsor (
    .clk                        (clk),
    .rst                        (rst),
    .manual_rst                 (~accel_talk),
    .en                         (1'b1),
    .rst_value                  (1'b0),
    .load_data                  (accel_talk),
    .input_data                 (accel_talk),
    .output_data                (accel_talk_d1)
);

wavelet_core #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .IBUFF_CELL_COUNT           (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT           (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE            (MAX_FILTER_SIZE)
) core (
    .clk                        (clk),
    .rst                        (rst),
    .core_data_in               (input_reg_out),
    .core_data_out              (core_data_out),
    .core_go                    (core_go),
    .core_init                  (core_init),
    .core_filter_size           (core_filter_size),
    .core_dec_level             (core_dec_level),
    .core_inputs_len            (core_inputs_len),
    .core_downsample            (core_downsample),
    .core_input_reg_en          (core_input_reg_w_en),
    .clear_core_go              (core_clear_go),
    .clear_core_init            (core_clear_init),
    .core_r_addr_rst            (core_r_addr_rst),
    .core_r_data_available      (core_r_data_available),
    .core_output_reg_en_pulse   (core_output_reg_en_pulse)
);

endmodule