`timescale 1ns/1ns

module fir_filter_testbench;

parameter INPUT_WIDTH                       = 32;
parameter OUTPUT_WIDTH                      = 32;
parameter MAX_FILTER_SIZE                   = 16;
parameter FILTER_SIZE                       = 4;
parameter DOWNSAMPLE                        = 0;
parameter DEC_LEVEL                         = 2'b00;
parameter INPUT_SERIES_LENGTH               = 256;
parameter IBUFF_CELL_COUNT                  = 4096;
parameter INPUTS_PATH                       = "../filter_inputs.txt";
parameter COEFFS_HID_PATH                   = "../filter_coeffs_HID.txt";
parameter A_OUT_DET1_PATH                   = "../filter_outputs.txt";

localparam FS_WIDTH                         = $clog2(MAX_FILTER_SIZE);
localparam IBUFF_ADDR_WIDTH                 = $clog2(IBUFF_CELL_COUNT),

localparam [FS_WIDTH-1:0] FILTER_SIZE_      = FILTER_SIZE - 1;

integer i;
integer fd;  

reg [INPUT_WIDTH-1:0]   test_input_data     [0:INPUT_SERIES_LENGTH-1];
reg [INPUT_WIDTH-1:0]   test_coeff_data     [0:MAX_FILTER_SIZE-1];

reg                       clk;
reg                       rst;
reg                       flush_pipeline;
reg                       input_valid;
reg                       init_filter;
reg                       disable_freezing;
reg [INPUT_WIDTH-1:0]     fir_input;
reg [FS_WIDTH-1:0]        filter_size;
reg [1:0]                 cur_dec_level;
reg                       downsample;

wire                      output_valid;
wire [OUTPUT_WIDTH-1:0]   fir_output;
wire                      error_flag;

// ibuff wires
reg [IBUFF_ADDR_WIDTH-1:0]  ibuff_w_addr;
reg [INPUT_WIDTH-1:0]       ibuff_w_data;
reg                         ibuff_w_en;
reg [IBUFF_ADDR_WIDTH-1:0]  ibuff_r_addr;
reg                         ibuff_r_en;
wire [INPUT_WIDTH-1:0]      ibuff_r_data;


always #20 duv_clk = ~duv_clk;

initial $readmemb(INPUTS_PATH,       test_input_data);
initial $readmemb(COEFFS_HID_PATH,   test_coeff_data);

fir_filter #(
    .MAX_FILTER_SIZE            (MAX_FILTER_SIZE),
    .INPUT_WIDTH                (INPUT_WIDTH),
    .OUTPUT_WIDTH               (OUTPUT_WIDTH)
) duv (
    .clk                        (clk),
    .rst                        (rst),
    .flush_pipeline             (flush_pipeline),
    .input_valid                (input_valid),
    .init_filter                (init_filter),
    .disable_freezing           (disable_freezing),
    .fir_input                  (fir_input),
    .filter_size                (filter_size),
    .cur_dec_level              (cur_dec_level),
    .downsample                 (downsample),
    .output_valid               (output_valid),
    .fir_output                 (fir_output),
    .error_flag                 (error_flag),
);

register_file #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .CELL_COUNT                     (IBUFF_CELL_COUNT)
) ibuff (
    .clk                            (clk),
    .rst                            (rst),
    .w_en_in                        (ibuff_w_en),
    .w_addr_in                      (ibuff_w_addr),
    .w_data_in                      (ibuff_w_data),
    .r_en_in                        (ibuff_r_en),
    .r_addr_in                      (ibuff_r_addr),
    .r_data_out                     (ibuff_r_data)
);

task duv_system_reset;
    begin
        @(posedge clk) rst = 1;
        @(posedge clk) rst = 0;
    end
endtask

task duv_filter_init;
    begin
        @(posedge clk) init_filter = 1'b1;
        @(posedge clk) {init_filter, input_valid} = 2'b01;
        for(i=0;i<FILTER_SIZE;i=i+1) begin
            fir_input = test_coeff_HID_data[i];
            @(posedge clk) ;
        end
        input_valid = 0;
    end
endtask

integer base = 0;

task duv_filter_verify;
    begin
        fd = $fopen(A_OUT_DET1_PATH, "w");
        @(posedge duv_clk) duv_input_valid = 1;

        for(base = 0; base < INPUT_SERIES_LENGTH + FILTER_SIZE - 1; base = base + 1) begin
            if(duv_downsample) base = base + 1;

            for(i = 0; i < FILTER_SIZE; i = i + 1) begin
                if((base-i < 0) | (base-i >= INPUT_SERIES_LENGTH)) begin
                    duv_fir_input = 0;    
                end
                else begin
                    duv_fir_input = test_input_data[base-i];
                end
                @(posedge duv_clk) ;
            end
        end
        duv_input_valid = 0; 

        $display("[%t] error count = %d\n", $time, error_count);
        $fclose(fd);
    end
endtask

task duv_ibuff_put_coeffs;
    begin
        for(i = 0; i < FILTER_SIZE; i = i + 1) begin
            ibuff_w_en = 1'b1;
            ibuff_w_addr = ibuff_w_addr + 1;
            ibuff_w_data = test_coeff_data[i];
            @(posedge clk);
        end
        ibuff_w_en = 0;
        ibuff_w_addr = {(IBUFF_ADDR_WIDTH){1'bz}};
        ibuff_w_data = {(INPUT_WIDTH){1'bz}};
        @(posedge clk);
    end
endtask


task duv_filter_read_coeffs;
    begin
        for(i = 0; i < FILTER_SIZE; i = i + 1) begin
            ibuff_r_en = 1'b1;
            ibuff_r_addr = ibuff_r_addr + 1;
            @(posedge clk);
            input_valid = 1'b1;
            filter_inputs = ibuff_r_data;
            
            ibuff_r_en = 0;
            ibuff_r_addr = {(IBUFF_ADDR_WIDTH){1'bz}};
            @(posedge clk);
            input_valid = 1'b0;
        end
        ibuff_r_en = 0;
        ibuff_r_addr = {(IBUFF_ADDR_WIDTH){1'bz}};
        @(posedge clk);
    end
endtask


task duv_put_init_signal;
    begin
        @(posedge clk);
        init_filter = 1'b1;
    end
endtask

initial begin
    ibuff_w_en = 0;
    ibuff_w_addr = {(IBUFF_ADDR_WIDTH){1'bz}};
    ibuff_w_data = {(INPUT_WIDTH){1'bz}};

    ibuff_r_addr = = {(IBUFF_ADDR_WIDTH){1'bz}};
    ibuff_r_en = 0;

    clk                     = 0;
    rst                     = 0;
    flush_pipeline          = 0;
    input_valid             = 0;
    init_filter             = 0;
    disable_freezing        = 0;
    fir_input               = 0;
    filter_size             = FILTER_SIZE_;
    cur_dec_level           = DEC_LEVEL;
    downsample              = DOWNSAMPLE;

    duv_system_reset();

    duv_put_init_signal();
    duv_ibuff_put_coeffs();

    duv_filter_read_coeffs();

    duv_filter_write_data();

    repeat(10) @(posedge duv_clk);
    $stop(); // all is done.
end

initial begin
    #100000 $stop();
end

endmodule

