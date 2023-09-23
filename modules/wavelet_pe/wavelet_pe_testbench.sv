`timescale 1ns/1ns

module wavelet_pe_testbench;

parameter INPUT_WIDTH       = 32;
parameter IBUFF_CELL_COUNT  = 2048;
parameter OBUFF_CELL_COUNT  = 4096;
parameter MAX_FILTER_SIZE   = 32;
parameter FILTER_SIZE       = 4;
parameter NUMBER_OF_INPUTS  = 256;
parameter FS_WIDTH          = $clog2(MAX_FILTER_SIZE);
parameter IBUFF_ADDR_WIDTH  = $clog2(IBUFF_CELL_COUNT);
parameter OBUFF_ADDR_WIDTH  = $clog2(OBUFF_CELL_COUNT);



parameter INPUTS_PATH                       = "../test_inputs.txt";
parameter COEFFS_HID_PATH                   = "../filter_coeffs_HID.txt";
parameter COEFFS_LOD_PATH                   = "../filter_coeffs_LOD.txt";
parameter OUTPUTS_HID                       = "../filter_outputs_HID.txt";
parameter OUTPUTS_LOD                       = "../filter_outputs_LOD.txt";


reg [INPUT_WIDTH-1:0]   test_input_data     [0:NUMBER_OF_INPUTS-1];
reg [INPUT_WIDTH-1:0]   test_coeff_HID_data [0:MAX_FILTER_SIZE-1];
reg [INPUT_WIDTH-1:0]   test_coeff_LOD_data [0:MAX_FILTER_SIZE-1];

initial $readmemb(INPUTS_PATH,       test_input_data);
initial $readmemb(COEFFS_HID_PATH,   test_coeff_HID_data);
initial $readmemb(COEFFS_LOD_PATH,   test_coeff_LOD_data);


reg                             clk;
reg                             rst;

// core signals
reg                             pe_init;
reg                             pe_go;

// general configuration signals
reg                             core_downsample;
reg [1:0]                       cur_dec_level;
reg [1:0]                       core_dec_level;
reg [FS_WIDTH-1:0]              core_filter_size;
reg [1:0]                       core_inputs_len;
reg                             ibuff_w_en;
reg [IBUFF_ADDR_WIDTH-1:0]      ibuff_w_addr;
reg [INPUT_WIDTH-1:0]           ibuff_w_data;

reg [OBUFF_ADDR_WIDTH-1:0]      cur_outputs_len;
reg [IBUFF_ADDR_WIDTH-1:0]      cur_inputs_len;
reg [OBUFF_ADDR_WIDTH-1:0]      obuff_w_approx_addr;

wire                            job_done;
wire                            fir_hp_output_valid;
wire                            fir_lp_output_valid;
wire [INPUT_WIDTH-1:0]          fir_hp_output;
wire [INPUT_WIDTH-1:0]          fir_lp_output;
wire [INPUT_WIDTH-1:0]          ibuff_r_data;
wire [IBUFF_ADDR_WIDTH-1:0]     ibuff_r_addr;
wire                            ibuff_r_en;

// obuff write port
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_addr;
wire [OBUFF_ADDR_WIDTH-1:0]     obuff_w_lp_abs_address;

wire [INPUT_WIDTH-1:0]          obuff_w_data;
wire                            obuff_w_en;

wire                            ibuff_r_data_available;
wire                            waiting_on_pe;

assign ibuff_r_data_available = (ibuff_r_addr < ibuff_w_addr);  
assign waiting_on_pe = (ibuff_w_addr == (NUMBER_OF_INPUTS + 2*FILTER_SIZE - 2));

integer fd_hp_file;
integer fd_lp_file;

wavelet_pe #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .IBUFF_CELL_COUNT               (IBUFF_CELL_COUNT),
    .MAX_FILTER_SIZE                (MAX_FILTER_SIZE)   
) duv (
    .clk                            (clk),
    .rst                            (rst),
    .pe_init                        (pe_init),
    .pe_go                          (pe_go),
    
    .ibuff_r_data_available         (ibuff_r_data_available),
    .waiting_on_pe                  (waiting_on_pe),

    .core_downsample                (core_downsample),
    .core_dec_level                 (core_dec_level),
    .cur_dec_level                  (cur_dec_level),
    .core_filter_size               (core_filter_size),
    .core_inputs_len                (core_inputs_len),
    .cur_outputs_len                (cur_outputs_len),
    .cur_inputs_len                 (cur_inputs_len),

    // obuff write port
    .obuff_w_approx_addr            (obuff_w_approx_addr),
    .obuff_w_addr                   (obuff_w_addr),
    .obuff_w_data                   (obuff_w_data),
    .obuff_w_en                     (obuff_w_en),
    .obuff_w_lp_abs_address         (obuff_w_lp_abs_address),

    .ibuff_r_data                   (ibuff_r_data),
    .ibuff_r_addr                   (ibuff_r_addr),
    .ibuff_r_en                     (ibuff_r_en),
    .fir_hp_output_valid            (fir_hp_output_valid),
    .fir_lp_output_valid            (fir_lp_output_valid),
    .fir_hp_output                  (fir_hp_output),
    .fir_lp_output                  (fir_lp_output),
    .job_done                       (job_done)
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

register_file #(
    .INPUT_WIDTH                    (INPUT_WIDTH),
    .CELL_COUNT                     (OBUFF_CELL_COUNT)
) obuff (
    .clk                            (clk),
    .rst                            (rst),
    .w_en_in                        (obuff_w_en),
    .w_addr_in                      (obuff_w_addr),
    .w_data_in                      (obuff_w_data),
    .r_en_in                        (),
    .r_addr_in                      (),
    .r_data_out                     ()
);

task duv_system_reset;
    begin
        @(posedge clk) rst = 1;
        @(posedge clk) rst = 0;
    end
endtask

integer i;

task duv_ibuff_coeff_init;
    begin
        @(posedge clk) ;
        for(ibuff_w_addr = 0; ibuff_w_addr < FILTER_SIZE; ibuff_w_addr=ibuff_w_addr+1) begin
            ibuff_w_en      <= 1'b1;
            ibuff_w_data    <= test_coeff_HID_data[ibuff_w_addr];
            @(posedge clk) ;
        end

        for(ibuff_w_addr = FILTER_SIZE; ibuff_w_addr<(2*FILTER_SIZE); ibuff_w_addr=ibuff_w_addr+1) begin
            ibuff_w_en      <= 1'b1;
            ibuff_w_data    <= test_coeff_LOD_data[ibuff_w_addr-FILTER_SIZE];
            @(posedge clk) ;
        end 
        ibuff_w_en <= 0;
    end
endtask

task duv_pe_init;
    begin
        @(posedge clk) pe_init <= 1'b1;
        @(posedge clk) pe_init <= 1'b0;
    end
endtask

task duv_pe_go;
    begin
        @(posedge clk) pe_go <= 1'b1;
        @(posedge clk) pe_go <= 1'b0;
    end
endtask

task duv_ibuff_data_init;
    begin
        @(posedge clk) ;
        for(ibuff_w_addr = 0;
            ibuff_w_addr < NUMBER_OF_INPUTS + 2*FILTER_SIZE - 2;
            ibuff_w_addr = ibuff_w_addr + 1)
        begin
            ibuff_w_en      <= 1'b1;
            ibuff_w_data    <= (
                (ibuff_w_addr > (core_filter_size-1)) &
                (ibuff_w_addr < (core_filter_size+NUMBER_OF_INPUTS))
            ) ? ((test_input_data[ibuff_w_addr-core_filter_size])) : (0);
            @(posedge clk) ;
        end
        ibuff_w_en <= 0;
    end
endtask

always #20 clk = ~clk;



always@(posedge clk) begin
    if(fir_hp_output_valid) begin
        $fdisplayb(fd_hp_file, fir_hp_output);
    end
    if(fir_lp_output_valid) begin
        $fdisplayb(fd_lp_file, fir_lp_output);
    end
end

initial begin
    #100000 $stop();
end

initial begin
    fd_hp_file = $fopen(OUTPUTS_HID, "w");
    fd_lp_file = $fopen(OUTPUTS_LOD, "w");

    clk                 <= 0;
    rst                 <= 0;
    pe_init             <= 0;
    pe_go               <= 0;
    core_downsample     <= 1;
    core_dec_level      <= 0;
    cur_dec_level       <= 0;
    cur_outputs_len     <= 129;
    cur_inputs_len      <= 256;
    core_filter_size    <= FILTER_SIZE - 1;
    core_inputs_len     <= 2'b00;
    ibuff_w_en          <= 0;
    ibuff_w_addr        <= 0;
    ibuff_w_data        <= 0;
    obuff_w_approx_addr <= 129;

    duv_system_reset();

    duv_pe_init();
    duv_ibuff_coeff_init();

    @(posedge clk) ibuff_w_addr = 0;
    repeat(20) @(posedge clk);

    duv_pe_go();
    duv_ibuff_data_init();

    while(~job_done) @(posedge clk); 

    repeat(20) @(posedge clk);

    $fclose(fd_hp_file);
    $fclose(fd_lp_file);


    $stop();

end

endmodule