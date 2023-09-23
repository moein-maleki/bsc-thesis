module fir_address_generator #(
    parameter FS_WIDTH = 6,
    parameter INPUT_WIDTH = 32 
) (
    input                       clk,
    input                       rst,

    input                       reset_counter,
    input [1:0]                 cur_dec_level,
    input                       downsample,
    input [FS_WIDTH-1:0]        filter_size,
    
    input                       incr_addr,
    input                       init_in_progress,
    
    output [FS_WIDTH-1:0]       coeff_addr,
    output                      sel_zero,
    output                      last_coeff,
    output                      batch_first_data
);

    reg is_us_coeff_addr;

    wire [FS_WIDTH-1:0] max_addr;
    wire [FS_WIDTH-1:0] normal_addr;
    wire [FS_WIDTH-1:0] alt_addr;

    // auxilary addresses
    assign alt_addr             = (normal_addr >> cur_dec_level);   
    assign max_addr             = (downsample) ? (filter_size) : (filter_size << cur_dec_level);
    
    // addr = 0
    assign batch_first_data     = (~|normal_addr);

    // coeff termination
    assign sel_zero             = (~downsample) & (is_us_coeff_addr);
    
    // coeff address
    assign coeff_addr           = (downsample | init_in_progress) ? (normal_addr) : (alt_addr);

    always@(*) begin
        is_us_coeff_addr <= 1'b0;
        case (cur_dec_level)
            2'b00: is_us_coeff_addr <= (1'b0);
            2'b01: is_us_coeff_addr <= (normal_addr[0]);
            2'b10: is_us_coeff_addr <= (|normal_addr[1:0]);
            2'b11: is_us_coeff_addr <= (|normal_addr[2:0]);
        endcase
    end

    counter #(
        .COUNTER_WIDTH          (FS_WIDTH)
    ) counter_unit (
        .clk                    (clk),
        .rst                    (rst),
        .manual_rst             (reset_counter),
        .count_up               (1'b1),
        .enable_counter         (incr_addr),
        .max_count              (max_addr),
        .count_value            (normal_addr),
        .co                     (last_coeff)
    );

endmodule