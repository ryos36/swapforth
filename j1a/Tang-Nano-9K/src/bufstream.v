`default_nettype none

module bufstream #(
	parameter integer WIDTH = 32,
	parameter integer BUF_LEN = 640
) (
	input wire clk,
	input wire rst,

	input wire in_axis_tvalid,
	output wire in_axis_tready,
	input wire in_axis_tuser,
	input wire in_axis_tlast,
	input wire [WIDTH-1:0] in_axis_tdata,

	output wire full,

	output wire out_axis_tvalid,
	input wire out_axis_tready,
	output wire out_axis_tuser,
	output wire out_axis_tlast,
	output wire [WIDTH-1:0] out_axis_tdata,

    output wire [9:0] debug_count_o,
    output wire [1:0] status_o
);

reg [1:0] status = 2'b00;
assign out_axis_tvalid = status[1];

reg [WIDTH-1+2:0] line_buf0 [0:BUF_LEN-1];
reg [WIDTH-1+2:0] line_buf1 [0:BUF_LEN-1];

reg [9:0] write_count = 10'd0;
reg [9:0] read_count = 10'd0;

reg write_buf = 1'b0;
reg read_buf = 1'b0;

reg tready_r = 1'b0;

wire [WIDTH-1+2:0] output_buf_w;
assign output_buf_w = ( read_buf == 1'b0 )?line_buf0[read_count]:line_buf1[read_count];
assign {out_axis_tuser, out_axis_tlast, out_axis_tdata} = output_buf_w;
assign full = (status == 2'b11);

// for debug ----------------------------
reg [9:0] saved_write_count = 10'd0;
reg [9:0] x_count = 10'd0;
reg [9:0] tlast_n = 10'd0;
assign debug_count_o = write_count;

wire [1:0] buf_status_w;
assign buf_status_w = {write_buf, read_buf};
reg [1:0] saved_buf_status_r;
assign status_o = status;
// for debug ----------------------------

always @( posedge clk ) begin
	case (status)
	2'b00: begin
		tready_r = 1'b1;
        status <=  2'b01;

		write_buf <= 1'b0;
		read_buf <= 1'b0;
    end
	2'b01: begin
		if ( in_axis_tvalid ) begin
			if ( write_buf == 1'b0 ) begin
				line_buf0[write_count] <= { in_axis_tuser, in_axis_tlast, in_axis_tdata };
			end else begin
				line_buf1[write_count] <= { in_axis_tuser, in_axis_tlast, in_axis_tdata };
			end
			if ( in_axis_tlast ) begin
				write_buf <= ~write_buf;
				write_count <= 10'd0;
				status <= 2'b10;

			end else begin
				write_count <= write_count + 10'd1;
			end
		end
	end

	2'b10: begin
		if ( in_axis_tvalid ) begin
			if ( write_buf == 1'b0 ) begin
				line_buf0[write_count] <= { in_axis_tuser, in_axis_tlast, in_axis_tdata };
			end else begin
				line_buf1[write_count] <= { in_axis_tuser, in_axis_tlast, in_axis_tdata };
			end
			if ( in_axis_tlast ) begin
				if ( out_axis_tready ) begin
					if ( out_axis_tlast ) begin
						status <= 2'b10;
                         
						read_buf <= ~read_buf;
						read_count <= 10'd0;
					end else begin
						status <= 2'b11;

                        tready_r <= 1'b0;
						read_count <= read_count + 10'd1;
					end
				end else begin
                    status <= 2'b11;

                    tready_r = 1'b0;
                end

				write_buf <= ~write_buf;
				write_count <= 10'd0;

			end else begin
				if ( out_axis_tready ) begin
					if ( out_axis_tlast ) begin
						status <= 2'b01;

						read_buf <= ~read_buf;
						read_count <= 10'd0;
					end else begin
						read_count <= read_count + 10'd1;
					end
				end

				write_count <= write_count + 10'd1;
			end
		end else begin
			if ( out_axis_tready ) begin
				if ( out_axis_tlast ) begin
					status <= 2'b01;

					read_buf <= ~read_buf;
					read_count <= 10'd0;
				end else begin
					read_count <= read_count + 10'd1;
				end
			end
		end
	end

	2'b11: begin
		if ( out_axis_tready ) begin
			if ( out_axis_tlast ) begin
				status <= 2'b10;
                 
				read_buf <= ~read_buf;
				read_count <= 10'd0;
                tready_r <= 1'b1;


			end else begin
				read_count <= read_count + 10'd1;
			end
		end
	end

	endcase
end

assign in_axis_tready = tready_r;

endmodule
`default_nettype wire
