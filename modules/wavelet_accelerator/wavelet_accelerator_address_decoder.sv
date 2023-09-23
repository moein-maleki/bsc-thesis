module wavelet_accelerator_address_decoder #(
    parameter ADDR_BUS_WIDTH = 32,
    parameter BASE_ADDRESS = 32'h1A100000,
    parameter CONFIG_REG_OFFSET = 2'b00,
    parameter INPUT_REG_OFFSET = 2'b01,
    parameter OUTPUT_REG_OFFSET = 2'b10
) (
    input [ADDR_BUS_WIDTH-1:0]  cpu_addr,
    input                       cpu_read_en,
    input                       cpu_write_en,

    output                          config_reg_en,
    output                          input_reg_en,
    output                          output_reg_en
);

    wire wavelet_en;

    assign wavelet_en       = (cpu_read_en | cpu_write_en) ? (cpu_addr[ADDR_BUS_WIDTH-1:4] == BASE_ADDRESS[ADDR_BUS_WIDTH-1:4]) : (1'b0);
    assign config_reg_en    = (wavelet_en) & (cpu_addr[3:2] == CONFIG_REG_OFFSET);
    assign input_reg_en     = (wavelet_en) & (cpu_addr[3:2] == INPUT_REG_OFFSET);
    assign output_reg_en    = (wavelet_en) & (cpu_addr[3:2] == OUTPUT_REG_OFFSET);

    // 0001_1010_0001_0000_0000_0000_0000_00xx // config reg
    // 0001 1010 0001 0000 0000 0000 0000 01xx // input data reg
    // 0001 1010 0001 0000 0000 0000 0000 10xx // output data reg
endmodule