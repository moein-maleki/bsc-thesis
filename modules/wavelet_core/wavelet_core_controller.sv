module wavelet_core_controller #(
    parameter INPUT_WIDTH           = 32, 
    parameter IBUFF_CELL_COUNT      = 2048,
    parameter OBUFF_CELL_COUNT      = 4096,
    parameter MAX_FILTER_SIZE       = 32,

    parameter FS_WIDTH              = $clog2(MAX_FILTER_SIZE),
    parameter IBUFF_ADDR_WIDTH      = $clog2(IBUFF_CELL_COUNT),
    parameter OBUFF_ADDR_WIDTH      = $clog2(OBUFF_CELL_COUNT)
) (
    input                       clk,
    input                       rst,

    // config signals
    input [FS_WIDTH-1:0]        core_filter_size,
    input [1:0]                 core_dec_level,
    input [1:0]                 core_inputs_len,
    input                       core_downsample,
    input [1:0]                 cur_dec_level,
    
    // config register bits
    output reg                  clear_core_init,
    output reg                  clear_core_go,
    input                       core_go,
    input                       core_init,

    // decoder signals
    input                       core_input_reg_en,
    input                       core_output_reg_en_pulse,

    // pe control
    output reg                  pe_init,
    output reg                  pe_go,
    input                       pe_job_done,
    output                      fir_disable_freezing,
    output                      fir_force_freeze,    
    
    // dec_level control
    output reg                  cur_dec_level_cen,
    output reg                  clear_cur_dec_level,
    input                       last_dec_level,
    
    // ibuff signals
    output reg                  ibuff_w_sel_obuff_r_data,
    output reg                  ibuff_w_sel_input_reg,
    output                      ibuff_w_en,
    output                      ibuff_w_offset_cen,
    output reg                  ibuff_w_offset_rst,
    output reg                  ibuff_w_base_reg_rst,
    output reg                  ibuff_w_sel_erase,
    input [IBUFF_ADDR_WIDTH-1:0] ibuff_w_offset,
    input [IBUFF_ADDR_WIDTH-1:0] cur_abs_inputs_len,

    // obuff signals
    output reg                  obuff_r_en,
    output reg                  obuff_r_offset_rst,
    output reg                  obuff_r_offset_cen,
    output reg                  obuff_r_base_reg_rst,
    output reg                  core_r_addr_rst_cu,
    input                       obuff_r_last_input,

    // general signals
    input                       pause_work
);

localparam IDLE             = 4'b0000;
localparam WAIT_TO_COME     = 4'b0001;
localparam WAIT_TO_END      = 4'b0010;
localparam IBUFF_WRITE      = 4'b0011;
localparam WRITE_BACK       = 4'b0100;
localparam CLEAR_UP_IBUFF   = 4'b0101;
localparam RESET_STATUS     = 4'b0110;
localparam DECIDE_GO        = 4'b0111;
localparam WORK             = 4'b1000; 

reg [3:0] present_state;
reg [3:0] next_state;


reg ibuff_w_offset_cen_cu; 
reg ibuff_w_en_init;
reg ibuff_w_en_wb;
reg ibuff_w_offset_cen_str8;

wire ibuff_w_offset_cen_d1;
wire ibuff_w_en_wb_d1;
wire ibuff_w_zombie;
wire last_coeff;
wire ibuff_last_w_offset_cen;
wire pe_go_first_chance;
wire ibuff_w_rest;

assign ibuff_w_offset_cen       = (~pause_work) & (ibuff_w_offset_cen_str8 | ibuff_w_offset_cen_d1) & (~ibuff_last_w_offset_cen); 
assign ibuff_w_en               = (~pause_work) & (ibuff_w_en_init | ibuff_w_en_wb_d1) & (~fir_disable_freezing); //(~obuff_r_last_input) & 
assign pe_go_first_chance       = (ibuff_w_offset == 2);
assign last_coeff               = (ibuff_w_offset == ((core_filter_size << 1) + 1));
assign ibuff_last_w_offset_cen  = (ibuff_w_offset == (cur_abs_inputs_len + core_filter_size));
assign ibuff_w_zombie           = (~core_init) & (ibuff_w_offset >= cur_abs_inputs_len);
assign ibuff_w_rest             = (ibuff_w_offset == (cur_abs_inputs_len + (core_filter_size << 1)));
assign fir_disable_freezing     = 
    (ibuff_w_offset == (cur_abs_inputs_len + core_filter_size));
assign fir_force_freeze         = pause_work;


always @(posedge clk) begin
    if(rst)         present_state <= IDLE;
    else            present_state <= (pause_work) ? (present_state) : (next_state);
end

always@(present_state, core_init, core_go, core_input_reg_en, pause_work,
    pe_job_done, ibuff_w_zombie, last_coeff, last_dec_level, ibuff_last_w_offset_cen) begin
    
    next_state <= IDLE;
    case (present_state)
        IDLE:               next_state <= (core_init | core_go) ? (WAIT_TO_COME) : (IDLE);
        WAIT_TO_COME:       next_state <= 
            (pe_job_done)           ? (
                (core_init) ? (CLEAR_UP_IBUFF)  :
                (core_go)   ? (DECIDE_GO)       : (RESET_STATUS)
            ) :
            (ibuff_w_zombie)        ? (IBUFF_WRITE) :
            (core_input_reg_en)     ? (WAIT_TO_END) : (WAIT_TO_COME);        
        WAIT_TO_END:        next_state <= (~core_input_reg_en) ? (IBUFF_WRITE) : (WAIT_TO_END);
        IBUFF_WRITE:        next_state <= (WAIT_TO_COME);
        DECIDE_GO:          next_state <= (last_dec_level) ? (RESET_STATUS) : (WRITE_BACK);
        WRITE_BACK:         next_state <= (ibuff_last_w_offset_cen) ? (WORK) : (WRITE_BACK);
        WORK:               next_state <= (pe_job_done) ? (DECIDE_GO) : (WORK);
        CLEAR_UP_IBUFF:     next_state <= (last_coeff) ? (RESET_STATUS) : (CLEAR_UP_IBUFF);
        RESET_STATUS:       next_state <= IDLE;
    endcase
end

always @(present_state, core_init, core_go, ibuff_w_zombie,
    ibuff_last_w_offset_cen, pause_work, pe_go_first_chance,
    cur_dec_level, ibuff_w_rest, obuff_r_last_input) begin
    {
        pe_init,
        pe_go,
        cur_dec_level_cen,
        clear_cur_dec_level,
        ibuff_w_sel_obuff_r_data,
        ibuff_w_sel_input_reg,
        ibuff_w_en_init,
        ibuff_w_en_wb,
        ibuff_w_offset_cen_cu,
        ibuff_w_offset_cen_str8,
        ibuff_w_offset_rst,
        ibuff_w_base_reg_rst,
        obuff_r_en,
        obuff_r_offset_rst,
        obuff_r_offset_cen,
        obuff_r_base_reg_rst,
        clear_core_init,
        clear_core_go,
        ibuff_w_sel_erase,
        core_r_addr_rst_cu
    } <= 0;
    case (present_state)
        IDLE:               begin
            ibuff_w_base_reg_rst        <= (core_init | core_go);
            ibuff_w_offset_rst          <= (core_init | core_go);
            obuff_r_base_reg_rst        <= (core_go);
            obuff_r_offset_rst          <= (core_go);
            pe_init                     <= (core_init);
            pe_go                       <= (core_go);
            clear_cur_dec_level         <= (core_go);
            core_r_addr_rst_cu          <= (core_go);
        end    
        WAIT_TO_COME:       begin
            ;
        end      
        WAIT_TO_END:        begin
            ;
        end 
        IBUFF_WRITE:        begin
            ibuff_w_sel_input_reg       <= (core_init) | (core_go & (~ibuff_w_zombie));
            ibuff_w_sel_erase           <= (ibuff_w_zombie);
            ibuff_w_en_init             <= (~pause_work) & ((core_init | core_go) & (~ibuff_last_w_offset_cen));
            ibuff_w_offset_cen_str8     <= (~pause_work) & ((core_init | core_go) & (~ibuff_w_rest) & (~ibuff_last_w_offset_cen));
        end
        DECIDE_GO:          begin
            ibuff_w_base_reg_rst        <= (~pause_work);
            ibuff_w_offset_rst          <= (~pause_work);
            obuff_r_offset_rst          <= (~pause_work);
            obuff_r_base_reg_rst        <= (~pause_work); 
            cur_dec_level_cen           <= (~pause_work);
        end
        WRITE_BACK: begin 
            obuff_r_en                  <= (~pause_work) & (~ibuff_w_zombie) & (~obuff_r_last_input);
            obuff_r_offset_cen          <= (~pause_work) & (~ibuff_w_zombie) & (~ibuff_last_w_offset_cen);
            ibuff_w_sel_obuff_r_data    <= (~ibuff_w_zombie);
            ibuff_w_sel_erase           <= (ibuff_w_zombie) & (~ibuff_last_w_offset_cen);
            ibuff_w_en_wb               <= (~pause_work) & (~ibuff_last_w_offset_cen);
            ibuff_w_offset_cen_cu       <= (~pause_work) & (~ibuff_last_w_offset_cen);
            pe_go                       <= (~pause_work) & (pe_go_first_chance);
        end
        WORK: begin
        end
        CLEAR_UP_IBUFF:   begin
            ibuff_w_sel_erase           <= 1'b1;
            ibuff_w_en_init             <= (~pause_work);
            ibuff_w_offset_cen_str8     <= (~pause_work);
        end
        RESET_STATUS:       begin
            ibuff_w_base_reg_rst        <= (~pause_work);
            ibuff_w_offset_rst          <= (~pause_work);
            obuff_r_base_reg_rst        <= (~pause_work);
            obuff_r_offset_rst          <= (~pause_work);
            clear_core_init             <= (~pause_work) & (core_init);
            clear_core_go               <= (~pause_work) & (~core_init) & (core_go);            
        end
    endcase
end

register #(
    .INPUT_WIDTH            (1)
) ibuff_w_en_wb_delayer (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (1'b1),
    .input_data             (ibuff_w_en_wb),
    .output_data            (ibuff_w_en_wb_d1)
);

register #(
    .INPUT_WIDTH            (1)
) ibuff_w_offset_cen_delayer (
    .clk                    (clk),
    .rst                    (rst),
    .manual_rst             (1'b0),
    .en                     (1'b1),
    .rst_value              (1'b0),
    .load_data              (1'b1),
    .input_data             (ibuff_w_offset_cen_cu),
    .output_data            (ibuff_w_offset_cen_d1)
);


endmodule
