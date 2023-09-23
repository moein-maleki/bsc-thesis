module wavelet_pe_controller #(
    parameter IBUFF_CELL_COUNT  = 2048,
    parameter OBUFF_CELL_COUNT  = 4096,

    parameter MAX_FILTER_SIZE = 32,

    parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT),
    parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE)
) (
    input                           clk,
    input                           rst,

    // core signals
    input                           core_downsample,
    input [1:0]                     core_dec_level,
    input [FS_WIDTH-1:0]            core_filter_size,
    input [1:0]                     core_inputs_len,
    input [1:0]                     cur_dec_level,

    input                           pe_init,
    input                           pe_go,
    input                           fir_force_freeze,
    input                           ibuff_r_data_available,
    input [IBUFF_ADDR_WIDTH-1:0]    cur_inputs_len,
    input [OBUFF_ADDR_WIDTH-1:0]    cur_outputs_len,
    
    // fir control signals
    input                           fir_hp_output_valid,
    output reg                      fir_flush_pipeline,
    output reg                      fir_init,
    output reg                      fir_hp_input_valid,
    output reg                      fir_lp_input_valid,

    // obuff write control signals
    output reg                      obuff_w_offset_rst,
    output reg                      obuff_w_hp_base_reg_rst,
    output reg                      obuff_w_lp_base_reg_rst,
    output reg                      obuff_w_hp_force_cen,
  

    // ibuff read control signals
    output reg                      ibuff_r_addr_offset_rst,
    output reg                      ibuff_r_addr_offset_upcount,
    output reg                      ibuff_r_addr_base_reg_rst,
    output reg                      ibuff_r_addr_offset_cen,
    output reg                      ibuff_r_en,

    // general outputs 
    output                          init_in_progress,
    output reg                      job_done
);


// base_reg controls whether if we have read all of the ibuff contents
// ibuff_r_data_available controls whether there exists a valid input data in the ibuff 

localparam IDLE         = 2'b00;
localparam READ_IBUFF   = 2'b01;
localparam CLEAR_UP     = 2'b10;

reg [1:0] present_state;
reg [1:0] next_state;

reg                     clear_init_in_progress;
reg                     set_init_in_progress;
reg                     clear_outputs_produced_len;
reg                     clear_inputs_read_len;
reg                     set_initialized;
reg                     clear_initialized;

wire [IBUFF_ADDR_WIDTH-1:0] filter_size; 


wire [OBUFF_ADDR_WIDTH-1:0] outputs_produced_len; // unncessary.
wire [IBUFF_ADDR_WIDTH-1:0] inputs_read_len;
wire                        last_output; 
wire                        last_input; // unncessary
wire                        ibuff_r_data_available_d1;
wire                        initialized;

assign filter_size = core_filter_size;

always@(posedge clk) begin
    if(rst) present_state <= IDLE;
    else    present_state <= next_state;
end

always@(present_state, pe_init, pe_go, init_in_progress,
    last_output, last_input, ibuff_r_data_available) begin
    
    next_state <= IDLE;
    case (present_state)
        IDLE:       next_state <= (pe_init | pe_go) ? (READ_IBUFF) : (IDLE);
        READ_IBUFF: next_state <=
            (init_in_progress) ?
            (
                (last_input) ?
                    (
                    CLEAR_UP
                    ) : (
                    READ_IBUFF
                    )
            ) :
            (
                (last_output) ?
                    (
                    CLEAR_UP
                    ) : (
                    READ_IBUFF
                    )
            );
        CLEAR_UP:   next_state <= IDLE;
    endcase
end

always@(present_state, pe_init, pe_go, init_in_progress, ibuff_r_data_available,
    inputs_read_len, last_output, filter_size, ibuff_r_data_available_d1, fir_force_freeze, initialized) begin
    {
        fir_init,
        set_init_in_progress,
        fir_hp_input_valid,
        fir_lp_input_valid,
        ibuff_r_addr_offset_upcount,
        ibuff_r_addr_offset_cen,
        ibuff_r_en,
        clear_init_in_progress,
        ibuff_r_addr_base_reg_rst,
        ibuff_r_addr_offset_rst,
        fir_flush_pipeline,
        clear_outputs_produced_len,
        clear_inputs_read_len,
        obuff_w_offset_rst, // <- controls the reset of both, the lp and hp obuff writes.
        obuff_w_hp_base_reg_rst, // <-- should only by asserted once, at the start of the whole thing.
        obuff_w_lp_base_reg_rst, // <-- should be asserted at the start of every dec_level 
        job_done,
        obuff_w_hp_force_cen,
        clear_initialized,
        set_initialized
    } <= 0;

    case (present_state)
        IDLE:       begin
            ibuff_r_addr_base_reg_rst   <= (pe_init | pe_go) & (~initialized);
            ibuff_r_addr_offset_rst     <= (pe_init | pe_go) & (~initialized);
            clear_inputs_read_len       <= (pe_init | pe_go);
            set_initialized             <= (pe_go);
            fir_init                    <= (pe_init);
            set_init_in_progress        <= (pe_init);
            ibuff_r_addr_offset_upcount <= (pe_init);
            obuff_w_hp_base_reg_rst     <= (pe_init);
            clear_outputs_produced_len  <= (pe_go);
            fir_flush_pipeline          <= (pe_go);
            obuff_w_offset_rst          <= (pe_go);
            obuff_w_lp_base_reg_rst     <= (pe_go);
            job_done                    <= (1'b1);
            ibuff_r_en                  <= (pe_init | pe_go) & ((ibuff_r_data_available) & (~fir_force_freeze));
            ibuff_r_addr_offset_cen     <= (pe_go) & ((ibuff_r_data_available) & (~fir_force_freeze));
        end
        READ_IBUFF: begin
            ibuff_r_en                  <= (ibuff_r_data_available) & (~fir_force_freeze);
            ibuff_r_addr_offset_cen     <= (ibuff_r_data_available) & (~fir_force_freeze);
            fir_hp_input_valid          <= (ibuff_r_data_available_d1) & ((init_in_progress) ? (inputs_read_len <= filter_size) : (1'b1));
            fir_lp_input_valid          <= (ibuff_r_data_available_d1) & ((init_in_progress) ? (filter_size < inputs_read_len) : (1'b1));
            ibuff_r_addr_offset_upcount <= (init_in_progress); // counts up in INIT mode. counts down in GO mode.
            obuff_w_hp_force_cen        <= (last_output) & (~fir_force_freeze);
        end
        CLEAR_UP:   begin
            clear_init_in_progress      <= (1'b1);
            ibuff_r_addr_base_reg_rst   <= (1'b1);
            ibuff_r_addr_offset_rst     <= (1'b1);
            fir_flush_pipeline          <= (1'b1);
            job_done                    <= (1'b1);
        end
    endcase
end


register #(
    .INPUT_WIDTH            (1)
) ibuff_r_data_available__delayer (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (1'b1),
    .input_data             (ibuff_r_data_available),
    .output_data            (ibuff_r_data_available_d1)
);

register #(
    .INPUT_WIDTH            (1)
) initialized_register (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (clear_initialized),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (set_initialized),
    .input_data             (1'b1),
    .output_data            (initialized)
);


register #(
    .INPUT_WIDTH            (1)
) init_in_progress_reg (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (clear_init_in_progress),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (set_init_in_progress),
    .input_data             (1'b1),
    .output_data            (init_in_progress)
);

counter #(
    .COUNTER_WIDTH          (OBUFF_ADDR_WIDTH)
) output_production_counter (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (clear_outputs_produced_len),
    .count_up               (1'b1),
    .enable_counter         (fir_hp_output_valid),
    .max_count              (cur_outputs_len),
    .count_value            (outputs_produced_len),
    .co                     (last_output)
);

counter #(
    .COUNTER_WIDTH          (IBUFF_ADDR_WIDTH)
) ibuff_data_counter (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (clear_inputs_read_len),
    .count_up               (1'b1),
    .enable_counter         ((ibuff_r_data_available_d1 & init_in_progress)),
    .max_count              (cur_inputs_len),
    .count_value            (inputs_read_len),
    .co                     (last_input)
);


endmodule