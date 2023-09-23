`timescale 1ns/1ns

module wavelet_core_testbench;

parameter INPUT_WIDTH           = 32; 
parameter IBUFF_CELL_COUNT      = 4096;
parameter OBUFF_CELL_COUNT      = 4096;
parameter MAX_FILTER_SIZE       = 32;

parameter FS_WIDTH              = $clog2(MAX_FILTER_SIZE);
parameter IBUFF_ADDR_WIDTH      = $clog2(IBUFF_CELL_COUNT);
parameter OBUFF_ADDR_WIDTH      = $clog2(OBUFF_CELL_COUNT);

parameter FILTER_SIZE           = 4;
parameter DEC_LEVEL             = 4;
parameter INPUTS_LEN            = 2'b00;

parameter NUMBER_OF_INPUTS      =
    (INPUTS_LEN == 2'b00) ? (256) :
    (INPUTS_LEN == 2'b01) ? (512) :
    (INPUTS_LEN == 2'b10) ? (1024) :
    (INPUTS_LEN == 2'b11) ? (2048) : (0);    

parameter MAX_OUTPUTS_1         = 129 + 129;
parameter MAX_OUTPUTS_2         = 129 + 66 + 66;
parameter MAX_OUTPUTS_3         = 129 + 66 + 34 + 34;
parameter MAX_OUTPUTS_4         = 129 + 66 + 34 + 18 + 18;

parameter MAX_OUTPUTS =
    (DEC_LEVEL == 1) ? (MAX_OUTPUTS_1) : 
    (DEC_LEVEL == 2) ? (MAX_OUTPUTS_2) : 
    (DEC_LEVEL == 3) ? (MAX_OUTPUTS_3) : 
    (DEC_LEVEL == 4) ? (MAX_OUTPUTS_4) : (0);

parameter OUTPUT_FILENAME       = "../a_outputs.txt";
parameter INPUTS_PATH           = "../filter_inputs.txt"; //"../test_inputs.txt"; //    
parameter COEFFS_HID_PATH       = "../filter_coeffs_HID.txt"; //"../test_inputs.txt";   
parameter COEFFS_LOD_PATH       = "../filter_coeffs_LOD.txt"; //"../test_inputs.txt";   

integer i;
integer j;
integer fd;
reg [31:0] out_data;

reg [INPUT_WIDTH-1:0]   test_input_data     [0:NUMBER_OF_INPUTS-1];
reg [INPUT_WIDTH-1:0]   test_coeff_HID_data [0:MAX_FILTER_SIZE-1];
reg [INPUT_WIDTH-1:0]   test_coeff_LOD_data [0:MAX_FILTER_SIZE-1];

initial $readmemb(INPUTS_PATH,       test_input_data);
initial $readmemb(COEFFS_HID_PATH,   test_coeff_HID_data);
initial $readmemb(COEFFS_LOD_PATH,   test_coeff_LOD_data);

reg                     clk;
reg                     rst;
reg                     core_go;
reg                     core_init;
reg [INPUT_WIDTH-1:0]   data_in_bus;
reg                     core_input_reg_en;
reg [FS_WIDTH-1:0]      core_filter_size;
reg [1:0]               core_dec_level;
reg [1:0]               core_inputs_len;
reg                     core_downsample;
reg                     core_r_addr_rst;
reg                     core_output_reg_en;

wire                    clear_core_go;
wire                    clear_core_init;
wire [INPUT_WIDTH-1:0]  data_out_bus;
wire                    core_r_data_available;

reg set_core_init;

reg core_output_reg_en_d1;
wire core_output_reg_en_pulse;
assign core_output_reg_en_pulse = (core_output_reg_en == 1'b1) & (core_output_reg_en_d1 == 1'b0); 
always@(posedge clk) begin
    core_output_reg_en_d1 <= core_output_reg_en;
end

always@(posedge clk) begin
    if(rst)                     core_init <= 1'b0;
    else if (set_core_init)     core_init <= 1'b1;
    else if (clear_core_init)   core_init <= 1'b0;
    else                        core_init <= core_init;
end

reg set_core_go;

always@(posedge clk) begin
    if(rst)                     core_go <= 1'b0;
    else if (set_core_go)       core_go <= 1'b1;
    else if (clear_core_go)     core_go <= 1'b0;
    else                        core_go <= core_go;
end


wavelet_core #(
    .INPUT_WIDTH                (INPUT_WIDTH),
    .IBUFF_CELL_COUNT           (IBUFF_CELL_COUNT),
    .OBUFF_CELL_COUNT           (OBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE            (MAX_FILTER_SIZE)
) duv (
    .clk                        (clk),
    .rst                        (rst),
    .core_data_in               (data_in_bus),
    .core_data_out              (data_out_bus),
    .core_go                    (core_go),
    .core_init                  (core_init),
    .core_filter_size           (core_filter_size),
    .core_dec_level             (core_dec_level),
    .core_inputs_len            (core_inputs_len),
    .core_downsample            (core_downsample),
    .core_input_reg_en          (core_input_reg_en),
    .clear_core_go              (clear_core_go),
    .clear_core_init            (clear_core_init),
    .core_r_addr_rst            (core_r_addr_rst),
    .core_output_reg_en_pulse   (core_output_reg_en_pulse),
    .core_r_data_available      (core_r_data_available)
);


task duv_system_reset;
    begin
        @(posedge clk) rst = 1;
        @(posedge clk) rst = 0;
    end
endtask

integer delay;

task duv_core_init;
    begin
        set_core_init = 1'b1;
        @(posedge clk);
        set_core_init = 1'b0;

        repeat(50) @(posedge clk);

        for(i=0 ; i < FILTER_SIZE ; i=i+1) begin
            core_input_reg_en = 1;
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
            core_input_reg_en = 0;
            data_in_bus = test_coeff_HID_data[i];
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
        end

        for(i=FILTER_SIZE ; i < 2*FILTER_SIZE ; i=i+1) begin
            core_input_reg_en = 1;
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
            core_input_reg_en = 0;
            data_in_bus = test_coeff_LOD_data[i-FILTER_SIZE];
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
        end
    end
endtask

task duv_core_go;
    begin
        set_core_go <= 1'b1;
        @(posedge clk) ;
        set_core_go <= 1'b0;

        repeat(50) @(posedge clk);

        for(i=0 ; i < NUMBER_OF_INPUTS ; i=i+1) begin
            core_input_reg_en = 1;
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
            core_input_reg_en = 0;
            data_in_bus = test_input_data[i];
            for(delay=0;delay<4;delay=delay+1) begin
                @(posedge clk);
            end
        end
    end
endtask

task duv_reset_r_addr;
    begin
        @(posedge clk) core_r_addr_rst = 1;
        @(posedge clk) core_r_addr_rst = 0;
    end
endtask

always #20 clk = ~clk;

integer k = 0;


initial begin

    repeat(5000) @(posedge clk);
    fd = $fopen(OUTPUT_FILENAME, "w");
    #100
    
    duv_reset_r_addr();
    
    @(posedge clk); 
    while(1) begin
        while(core_r_data_available) begin 
            core_output_reg_en = 1;
            k = k + 1;
            @(posedge clk) ;
            @(posedge clk) out_data = data_out_bus;
            
            $fdisplayb(fd, out_data);
            $display("[%d] %d", k, out_data);
            
            for(j = 0; j < 3; j = j + 1) begin
                @(posedge clk) ;
            end
            core_output_reg_en = 0;

            for(j = 0; j < 4; j = j + 1) begin
                @(posedge clk) ;
            end
        end

        @(posedge clk);
        if(k == MAX_OUTPUTS)
            break;
    end

    $fclose(fd);
    $stop();
end

initial begin
    clk                 <= 0;
    rst                 <= 0;
    data_in_bus         <= 0;
    core_input_reg_en   <= 0;
    set_core_init       <= 0;
    set_core_go         <= 0;
    core_filter_size    <= FILTER_SIZE - 1;
    core_dec_level      <= DEC_LEVEL - 1;
    core_inputs_len     <= INPUTS_LEN;
    core_downsample     <= 1'b1;
    core_r_addr_rst     <= 0;
    core_output_reg_en  <= 0;

    duv_system_reset();
    duv_core_init();

    repeat(500) @(posedge clk);

    duv_core_go();

    // repeat(5000) @(posedge clk);
    // $stop();    
end

endmodule