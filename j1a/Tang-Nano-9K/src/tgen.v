`timescale 1ns / 1ps
`default_nettype none

module tgen #(
	parameter integer HOL_TOTAL = 800,
	parameter integer HOL_VALID = 640,
	parameter integer VAR_TOTAL = 525,
	parameter integer VAR_VALID = 480
) (
	input wire pixclk,
    output wire pixclk_vsync,

	input wire clk,
	output wire vsync,
	output wire vblank
);

reg [9:0] vcounter = 10'd0;
reg [9:0] hcounter = 10'd0;
reg [3:0] status = 4'd0;
reg vsync_r = 1'b0;
reg vsync_rr;

assign pixclk_vsync = ~vsync_rr & vsync_r;
assign vblank = status[2];

always @(posedge pixclk) begin

	case (status) 
	4'b0000: begin
		vcounter <= #1 10'd0;
		hcounter <= #1 10'd0;
        status <= 4'b0001;
	end
	4'b0001: begin
        status <= 4'b0010;
    end
	4'b0010: begin
        if ( hcounter == (HOL_TOTAL - 1)) begin
            if ( vcounter == (VAR_VALID - 1) ) begin
                status <= 4'b0100;
            end

            hcounter <= #1 10'd0;
            vcounter <= #1 vcounter + 10'd1;
        end else begin
            hcounter <= #1 hcounter + 10'd1;
        end
	end
	4'b0100: begin
        if ( hcounter == (HOL_TOTAL - 1)) begin
            if ( vcounter == (VAR_TOTAL - 2) ) begin
                status <= 4'b1000;
            end

            hcounter <= #1 10'd0;
            vcounter <= #1 vcounter + 10'd1;
        end else begin
            hcounter <= #1 hcounter + 10'd1;
        end
	end
	4'b1000: begin
        if ( hcounter == (HOL_TOTAL - 1)) begin
            status <= 4'b0000;
            hcounter <= #1 10'd0;
            vcounter <= #1 vcounter + 10'd1;
        end else begin
            hcounter <= #1 hcounter + 10'd1;
        end
	end
	endcase

end

reg vsync_detect_r = 1'b0;

always @(posedge pixclk) begin
    vsync_rr <= #1 vsync_r;
    if ( vsync_r ) begin
        if ( vsync_detect_r ) begin
            vsync_r <= #1 1'b0;
        end
    end else if ( vsync_detect_r ) begin
        // nothing to do
    end else if (status[0]) begin
        vsync_r <= #1 1'b1;
    end
end

reg vsync_hold_r = 1'b0;

always @(posedge clk) begin
    if ( vsync_hold_r ) begin
        vsync_hold_r <= #1 1'b0;
    end

    if ( vsync_detect_r ) begin
        if ( ~vsync_r ) begin
            vsync_detect_r <= #1 1'b0;
        end
    end else if ( vsync_r ) begin
        vsync_detect_r <= #1 1'b1;
        vsync_hold_r <= #1 1'b1;
    end
end

assign vsync = vsync_hold_r;

endmodule
`default_nettype wire
