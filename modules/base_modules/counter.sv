module counter #(
    parameter COUNTER_WIDTH = 6
) (
    input                           clk,
    input                           rst,
    input                           manual_rst,
    input                           count_up,
    input                           enable_counter,
    input      [COUNTER_WIDTH-1:0]  max_count,

    output reg [COUNTER_WIDTH-1:0]  count_value,
    output                          co
);
    
    wire                            sync_rst_signal;

    assign co                       = (count_up) ? (count_value == max_count) : (~|count_value);
    assign sync_rst_signal          = rst | manual_rst; 

    always @(posedge clk) begin
        if(sync_rst_signal)             count_value <= (count_up) ? (0) : (max_count);
        else if(enable_counter) begin
            if(co)                      count_value <= (count_up) ? (0) : (max_count);
            else                        count_value <= (count_up) ? (count_value + 1) : (count_value - 1);
        end
        else                            count_value <= count_value; 
    end


endmodule
