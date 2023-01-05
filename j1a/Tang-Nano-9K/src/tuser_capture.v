`default_nettype none
module tuser_capture 
#(
    parameter integer CWIDTH = 10
)
(
    input wire tp_clk,
	input wire tp_tuser,
	input wire tp_tvalid_and_tready,
    output wire [CWIDTH-1:0] tuser_counter_o,

    input wire peek_clk,
    output wire kick_tuser_cdc_pulse,
    output wire error_o
);

reg [CWIDTH-1:0] counter = 0;
reg [CWIDTH-1:0] counter_result = 0;

assign tuser_counter_o = counter_result;

always @(posedge tp_clk) begin
    if ( tp_tuser & tp_tvalid_and_tready ) begin
        counter_result <= #1 counter;
        counter <= #1 0;
    end else begin
        counter <= #1 counter + 1;
    end
end

reg tuser_detect = 1'b0;
reg consume_error = 1'b0;

assign error_o = consume_error;

reg tuser_detect_is_consumed = 1'b0;

always @(posedge tp_clk) begin
    if ( tuser_detect ) begin
        if (tuser_detect_is_consumed) begin
            tuser_detect <= #1 1'b0;
        end
    end else if ( tp_tuser & tp_tvalid_and_tready ) begin
        if ( tuser_detect_is_consumed ) begin
            consume_error <= #1 1'b1; // timing error!!
        end
        tuser_detect <= #1 1'b1;
    end
end

reg peek_tuser_r = 1'b0;

always @(posedge peek_clk) begin
    if ( peek_tuser_r ) begin
        peek_tuser_r <= #1 1'b0;
    end else if ( tuser_detect ) begin
        peek_tuser_r <= #1 1'b1;
    end
end

always @(posedge peek_clk) begin
    if ( tuser_detect_is_consumed ) begin
        if ( ~tuser_detect ) begin
            tuser_detect_is_consumed <= #1 1'b0;
        end
    end else if ( tuser_detect ) begin
        tuser_detect_is_consumed <= #1 1'b1;
    end
end

assign kick_tuser_cdc_pulse = peek_tuser_r;

endmodule
`default_nettype wire
