`default_nettype none
module tp_vga #(
    parameter integer WIDTH = 24
) (
    input wire clk,
    input wire rst,

	input wire tp_axis_tvalid,
	input wire tp_axis_tready,
	input wire tp_axis_tuser,
	input wire tp_axis_tlast,
	input wire [WIDTH-1:0] tp_axis_tdata,

	output wire do_capture_o,
	output wire [15:0] capture_data_o,

    output wire [23:0] tp_tuser_count_o,
    output wire [7:0] tp_fps_o
);

// FPS
reg [31:0] sec_counter = 32'd25_175_000;
reg [7:0] fps_r = 8'd0;
reg [7:0] fps_counter = 8'd0;
assign tp_fps_o = fps_r;

reg tp_axis_tuser_d;

always @(posedge clk) begin
	tp_axis_tuser_d <= tp_axis_tuser;
    if ( sec_counter == 32'd0 ) begin
        sec_counter <= 32'd25_175_000;
        fps_r <= fps_counter;
        fps_counter <= 8'd0;
    end else begin
        if ( tp_axis_tuser_d & ~tp_axis_tuser ) begin
            fps_counter <= fps_counter + 1;
        end
        sec_counter <= sec_counter - 1;
    end
end

reg tp_axis_tvalid_d = 1'd0;
reg tp_axis_tready_d = 1'd0;
reg tp_axis_tuser_d = 1'd0;
reg tp_axis_tlast_d = 1'd0;

reg [31:0] stay_counter = 32'd0;
reg rec_tuser_r = 1'd0;
reg rec_tlast_r = 1'd0;
reg do_capture_r = 1'd0;
reg [15:0] capture_data = 16'd0;

always @(posedge clk) begin
	tp_axis_tready_d <= tp_axis_tready;
	tp_axis_tvalid_d <= tp_axis_tvalid;
	tp_axis_tuser_d <= tp_axis_tuser;
	tp_axis_tlast_d <= tp_axis_tlast;

	if (( tp_axis_tvalid_d ^ tp_axis_tvalid ) |
	    ( tp_axis_tready_d ^ tp_axis_tready ) | 
	    ( ~tp_axis_tuser_d & tp_axis_tuser ) | 
	    ( tp_axis_tlast_d & ~tp_axis_tlast ) |
		( stay_counter == ~12'd0 )
		) begin
		rec_tuser_r <= tp_axis_tuser;
		rec_tlast_r <= tp_axis_tlast;
		stay_counter <= 32'd1;

		do_capture_r <= 1'd1;
		capture_data <= {
			tp_axis_tready_d,
			tp_axis_tvalid_d,
			rec_tuser_r,
			rec_tlast_r,

			stay_counter[11:0]
		};

	end else begin	
		do_capture_r <= 1'd0;

		rec_tuser_r <= rec_tuser_r | tp_axis_tuser;
		rec_tlast_r <= rec_tlast_r | tp_axis_tlast;
		stay_counter <= stay_counter + 32'd1;
	end
end

assign do_capture_o = do_capture_r;
assign capture_data_o = capture_data;

endmodule
`default_nettype wire
