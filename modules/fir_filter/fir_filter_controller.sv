module fir_filter_controller(
    input               clk,
    input               rst,
    input               input_valid,
    input               input_valid_d1,
    input               init_filter,
    input               last_coeff,
    input               batch_first_data, //addr == 0

    output reg          overwrite,
    output reg          incr_addr,
    output reg          output_valid,
    output reg          coeff_r_en,
    output reg          coeff_w_en,
    output reg          init_in_progress
);

    localparam GET_DATA     = 1'b0;
    localparam INIT_FILTER  = 1'b1; 

    reg present_state;
    reg next_state;

    // wire input_valid_cu;

    // assign input_valid_cu = (init_in_progress) ? (input_valid) : (input_valid_d1);

    always @(posedge clk) begin
        if(rst)     present_state <= GET_DATA;
        else        present_state <= next_state;
    end

    always @(present_state, init_filter, input_valid, last_coeff) begin
        next_state <= (GET_DATA);
        case (present_state)
            GET_DATA:       next_state <= (init_filter) ? (INIT_FILTER) : (GET_DATA); 
            INIT_FILTER:    next_state <= (last_coeff & input_valid) ? (GET_DATA) : (INIT_FILTER);         
        endcase
    end

    always @(present_state, input_valid, input_valid, batch_first_data, last_coeff) begin

        {coeff_r_en,
        incr_addr,
        overwrite,
        output_valid,            
        coeff_w_en,  
        init_in_progress} <= 0;  

        case (present_state)
            GET_DATA: begin
                {coeff_r_en, incr_addr}             <= {input_valid, input_valid};
                {overwrite}                         <= batch_first_data;
                {output_valid}                      <= last_coeff;
                {init_in_progress}                  <= init_filter;
            end
            INIT_FILTER: begin
                {incr_addr, coeff_w_en}             <= {(2){input_valid}};
                {init_in_progress}                  <= 1'b1;
            end            
        endcase
    end

endmodule
