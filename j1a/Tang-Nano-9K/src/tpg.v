
`default_nettype none

module tpg #(
	parameter integer WIDTH = 32,
	parameter integer HVALID = 640,
	parameter integer VVALID = 480
) (
	input wire axis_clk,
	input wire rst,

	input wire vsync_i,

	output wire out_axis_tvalid,
	input wire out_axis_tready,
	output wire out_axis_tuser,
	output wire out_axis_tlast,
	output wire [WIDTH-1:0] out_axis_tdata,

	input wire full_i,

    /* source */
    input wire [1:0] use_in_axis,

	input wire in_axis1_tvalid,
	output wire in_axis1_tready,
	input wire in_axis1_tuser,
	input wire in_axis1_tlast,
	input wire [WIDTH-1:0] in_axis1_tdata,

	input wire in_axis2_tvalid,
	output wire in_axis2_tready,
	input wire in_axis2_tuser,
	input wire in_axis2_tlast,
	input wire [WIDTH-1:0] in_axis2_tdata,

    input wire tp_clk,
	input wire tp_axis_tvalid,
	input wire tp_axis_tready,
	input wire tp_axis_tuser,
	input wire tp_axis_tlast,
	input wire [WIDTH-1:0] tp_axis_tdata,

    output wire [23:0] tp_tuser_count_o,
    output wire [7:0] tp_fps_o,

    output wire [1:0] status_o
);

//----------------------------------------------------------------
// TEST Pattern
/*
reg fifo_reset = 1'b0;

reg [9:0] tpg_hcount = 10'd0;
reg [9:0] tpg_vcount = 10'd0;
reg tpg_tvalid = 1'd0;
reg tpg_tlast = 1'd0;
reg tpg_tuser = 1'd0;
reg [2:0] tpg_status = 3'b000;
wire tpg_tready_w;
wire [WIDTH-1:0] tpg_tdata_w;
assign tpg_tdata_w = { 2'b00, tpg_vcount, 2'b11, tpg_hcount };

reg [7:0] tpg_counter = 8'h00;

always @(posedge axis_clk) begin
	case (tpg_status) 
	3'b000: begin
		if ( fifo_reset == 1'b1 ) begin
			fifo_reset <= 1'b0;
		end else if ( tpg_counter == 8'h00 ) begin
			fifo_reset <= 1'b1;
		end else if ( tpg_counter == 8'h0F ) begin
			tpg_status <= 3'b001;
			tpg_tvalid <= 1'b1;
			tpg_tuser <= 1'b1;
			tpg_hcount <= 10'd0;
			tpg_vcount <= 10'd0;
		end
		tpg_counter <= tpg_counter + 1;
	end
	3'b001: begin
		tpg_counter <= tpg_counter + 1;
		if ( out_axis_tready ) begin
			tpg_tuser <= 1'b0;
			if ( tpg_hcount == HVALID - 2 ) begin
				tpg_tlast <= 1'd1;
				tpg_status <= 3'b010;
			end
			tpg_hcount <= tpg_hcount + 10'd1;
			tpg_tvalid <= 1'b1;
		end else begin
			tpg_tvalid <= 1'b0;
		end
	end
	3'b010: begin
		if ( out_axis_tready ) begin
			tpg_status <= 3'b011;
			tpg_tlast <= 1'b0;
			tpg_tvalid <= 1'b0;
			tpg_vcount <= tpg_vcount + 10'd1;
			tpg_hcount <= 10'd0;
			tpg_tvalid <= 1'b1;
		end else begin
			tpg_tvalid <= 1'b0;
		end
	end
	3'b011: begin
		if ( tpg_vcount == VVALID ) begin
			tpg_status <= 3'b100;
		end else begin
			tpg_status <= 3'b001;
			tpg_tvalid <= 1'b1;
		end
	end
	3'b100: begin
		tpg_status <= 3'b001;
		tpg_tvalid <= 1'b1;
		tpg_tuser <= 1'b1;
		tpg_hcount <= 10'd0;
		tpg_vcount <= 10'd0;
	end
	endcase
end
*/

//----------------------------------------------------------------
// TEST Pattern
reg [9:0] tpg_hcount = 10'd0;
reg [9:0] tpg_vcount = 10'd0;
reg tpg_tvalid = 1'd0;
reg tpg_tlast = 1'd0;
reg tpg_tuser = 1'd0;
reg [1:0] tpg_status = 2'b00;
wire tpg_tready_w;
wire [23:0] tpg_tdata_w;
assign tpg_tdata_w = { 2'b11, tpg_vcount, 2'b11, tpg_hcount };
reg [7:0] tpg_counter;

assign tpg_tready_w = out_axis_tready;

always @(posedge axis_clk) begin
	case (tpg_status) 
	2'b00: begin
		tpg_status <= 2'b01;
		tpg_tvalid <= 1'b1;
		tpg_tuser <= 1'b1;
		tpg_hcount <= 10'd0;
		tpg_vcount <= 10'd0;
	end
	2'b01: begin
		tpg_counter <= tpg_counter + 1;
		if ( tpg_tready_w ) begin
			tpg_tuser <= 1'b0;
			if ( tpg_hcount == 10'd638 ) begin
				tpg_tlast <= 1'd1;
				tpg_status <= 2'b10;
			end
			tpg_hcount <= tpg_hcount + 10'd1;
		end
	end
	2'b10: begin
		if ( tpg_tready_w ) begin
			tpg_status <= 2'b11;
			tpg_tlast <= 1'b0;
			tpg_tvalid <= 1'b0;
			tpg_vcount <= tpg_vcount + 10'd1;
			tpg_hcount <= 10'd0;
		end
	end
	2'b11: begin
		if ( tpg_vcount == 10'd480 ) begin
			tpg_status <= 2'b00;
		end else begin
			tpg_status <= 2'b01;
			tpg_tvalid <= 1'b1;
		end
	end
	endcase
end

//----------------------------------------------------------------
/*
// for TEST PATTERN
reg [19:0] vga_count = ~20'd0;
reg out_axis_tvalid_r = 1'b1;
*/

assign out_axis_tuser = (use_in_axis == 2'd2)?in_axis2_tuser:((use_in_axis == 2'd1)?in_axis1_tuser:tpg_tuser);
assign out_axis_tvalid = (use_in_axis == 2'd2)?in_axis2_tvalid:((use_in_axis == 2'd1)?in_axis1_tvalid:tpg_tvalid);
assign out_axis_tdata = (use_in_axis == 2'd2)?in_axis2_tdata:((use_in_axis == 2'd1)?in_axis1_tdata:tpg_tdata_w);
assign out_axis_tlast = (use_in_axis == 2'd2)?in_axis2_tlast:((use_in_axis == 2'd1)?in_axis1_tlast:tpg_tlast); 

assign in_axis1_tready = (use_in_axis == 2'd1)?out_axis_tready:1'b0;
assign in_axis2_tready = (use_in_axis == 2'd2)?out_axis_tready:1'b0;


/*
always @(posedge axis_clk) begin
	if ( out_axis_tready ) begin
        tricky code!!  desgined that vga_count[19] becames tuser.
		if ( vga_count == (20'd307200 - 1) ) begin
			vga_count <= ~20'd0;
		end else begin 
			vga_count <= vga_count + 20'd1;
		end
	end
end
*/

//----------------------------------------------------------------
// from Test Point
reg [31:0] out_frame = 32'd0;
reg [31:0] out_frame_counter = 32'd0;

assign tp_tuser_count_o = out_frame;

reg tp_axis_tuser_d;
always @(posedge tp_clk) begin
	tp_axis_tuser_d <= tp_axis_tuser;
	if ( tp_axis_tuser_d & ~tp_axis_tuser ) begin
		out_frame = out_frame_counter;
		out_frame_counter = 32'd0;
	end else begin
		out_frame_counter <= out_frame_counter + 32'd1;
	end
end

reg [31:0] sec_counter = 32'd25_175_000;
reg [7:0] fps_r = 8'd0;
reg [7:0] fps_counter = 8'd0;
assign tp_fps_o = fps_r;

always @(posedge tp_clk) begin
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

endmodule
`default_nettype wire
