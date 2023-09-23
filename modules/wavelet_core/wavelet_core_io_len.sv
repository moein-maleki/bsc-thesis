module wavelet_core_io_len #(
    parameter IBUFF_CELL_COUNT  = 2048,
    parameter OBUFF_CELL_COUNT  = 2048,

    parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT),
    parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT)

) (
    input                           clk,
    input                           rst,

    input [1:0]                     core_dec_level,
    input [1:0]                     cur_dec_level,
    input [1:0]                     core_inputs_len,
    input [IBUFF_ADDR_WIDTH-1:0]    core_filter_size,
    input                           core_downsample,
    input                           core_init,

    output [OBUFF_ADDR_WIDTH-1:0]   cur_outputs_len,
    output [IBUFF_ADDR_WIDTH-1:0]   cur_inputs_len,
    output [IBUFF_ADDR_WIDTH-1:0]   cur_inputs_len_abs,
    output [OBUFF_ADDR_WIDTH-1:0]   prev_outputs_len,   
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_w_approx_addr,
    output [OBUFF_ADDR_WIDTH-1:0]   obuff_last_output
);

// this is ugly as all hell, and an overhaul is needed eventually.
// i dont do stuff like this usually!

wire [OBUFF_ADDR_WIDTH-1:0]     outputs_len_dl1;
wire [OBUFF_ADDR_WIDTH-1:0]     outputs_len_dl2;
wire [OBUFF_ADDR_WIDTH-1:0]     outputs_len_dl3;
wire [OBUFF_ADDR_WIDTH-1:0]     outputs_len_dl4;

wire [IBUFF_ADDR_WIDTH-1:0]     inputs_len_dl1;
wire [IBUFF_ADDR_WIDTH-1:0]     inputs_len_dl2;
wire [IBUFF_ADDR_WIDTH-1:0]     inputs_len_dl3;
wire [IBUFF_ADDR_WIDTH-1:0]     inputs_len_dl4;

wire [IBUFF_ADDR_WIDTH-1:0] abs_1;
wire [IBUFF_ADDR_WIDTH-1:0] abs_2;
wire [IBUFF_ADDR_WIDTH-1:0] abs_3;
wire [IBUFF_ADDR_WIDTH-1:0] abs_4;

assign abs_1 =
    (core_inputs_len == 2'b00) ? (256) :
    (core_inputs_len == 2'b01) ? (512) :
    (core_inputs_len == 2'b10) ? (1024) :
    (core_inputs_len == 2'b11) ? (2048) : ({(IBUFF_ADDR_WIDTH){1'b0}});

assign inputs_len_dl1 = abs_1 + core_filter_size;
assign inputs_len_dl2 = abs_2 + core_filter_size;
assign inputs_len_dl3 = abs_3 + core_filter_size;
assign inputs_len_dl4 = abs_4 + core_filter_size;

assign abs_2 = outputs_len_dl1;
assign abs_3 = outputs_len_dl2;
assign abs_4 = outputs_len_dl3;

assign cur_inputs_len_abs =
    (cur_dec_level == 2'b00) ? (abs_1) :
    (cur_dec_level == 2'b01) ? (abs_2) :
    (cur_dec_level == 2'b10) ? (abs_3) :
    (cur_dec_level == 2'b11) ? (abs_4) : ({(IBUFF_ADDR_WIDTH){1'b0}});

assign outputs_len_dl1 = (core_downsample) ? (inputs_len_dl1 >> 1) : (inputs_len_dl1);
assign outputs_len_dl2 = (core_downsample) ? (inputs_len_dl2 >> 1) : (inputs_len_dl2);
assign outputs_len_dl3 = (core_downsample) ? (inputs_len_dl3 >> 1) : (inputs_len_dl3);
assign outputs_len_dl4 = (core_downsample) ? (inputs_len_dl4 >> 1) : (inputs_len_dl4);

assign cur_inputs_len =
    (core_init) ? ((core_filter_size << 1) + 2)   :
    (cur_dec_level == 2'b00) ? (inputs_len_dl1) :
    (cur_dec_level == 2'b01) ? (inputs_len_dl2) :
    (cur_dec_level == 2'b10) ? (inputs_len_dl3) :
    (cur_dec_level == 2'b11) ? (inputs_len_dl4) : ({(IBUFF_ADDR_WIDTH){1'b0}});

assign cur_outputs_len =
    (cur_dec_level == 2'b00) ? (outputs_len_dl1) :
    (cur_dec_level == 2'b01) ? (outputs_len_dl2) :
    (cur_dec_level == 2'b10) ? (outputs_len_dl3) :
    (cur_dec_level == 2'b11) ? (outputs_len_dl4) : ({(OBUFF_ADDR_WIDTH){1'b0}}); 

assign obuff_w_approx_addr =
    (core_dec_level == 2'b00) ? (outputs_len_dl1) :
    (core_dec_level == 2'b01) ? (outputs_len_dl1 + outputs_len_dl2) :
    (core_dec_level == 2'b10) ? (outputs_len_dl1 + outputs_len_dl2 + outputs_len_dl3) :
    (core_dec_level == 2'b11) ? (outputs_len_dl1 + outputs_len_dl2 + outputs_len_dl3 + outputs_len_dl4) : (0);

assign prev_outputs_len =
    (cur_dec_level == 2'b00) ? (outputs_len_dl1) :
    (cur_dec_level == 2'b01) ? (outputs_len_dl1) :
    (cur_dec_level == 2'b10) ? (outputs_len_dl2) :
    (cur_dec_level == 2'b11) ? (outputs_len_dl3) : ({(OBUFF_ADDR_WIDTH){1'b0}}) - 1; 

assign obuff_last_output = 
    (core_dec_level == 2'b00) ? (obuff_w_approx_addr + outputs_len_dl1) :
    (core_dec_level == 2'b01) ? (obuff_w_approx_addr + outputs_len_dl2) :
    (core_dec_level == 2'b10) ? (obuff_w_approx_addr + outputs_len_dl3) :
    (core_dec_level == 2'b11) ? (obuff_w_approx_addr + outputs_len_dl4) : (0);

endmodule