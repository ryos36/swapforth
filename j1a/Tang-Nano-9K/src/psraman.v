`default_nettype none
module psraman #(
    parameter integer DQ_WIDTH = 16,
    parameter integer ADDR_WIDTH = 21,
    parameter integer DATA_MASK_WIDTH = ((4 * DQ_WIDTH)/8)
) (
    input wire psram_clock,
    
    input wire init_calib_i,
    input wire [4*DQ_WIDTH-1:0] rd_data_i,
    input wire rd_data_valid_i,

    output wire [4*DQ_WIDTH-1:0] wr_data_o,
    output wire [DATA_MASK_WIDTH-1:0] data_mask_o,

    output wire [ADDR_WIDTH-1:0] addr_o,
    output wire cmd_o,
    output wire cmd_en_o,

    input wire vsync_i,
    input wire almost_full_i,

    output wire ese_axis_tvalid,
    output wire ese_axis_tuser,
    output wire ese_axis_tlast,
    output wire [4*DQ_WIDTH-1:0] ese_axis_tdata, 

	// PSRAM debug
	input wire [20:0] addr_i,

	input wire [15:0] test_wr_data_i,
	input wire do_wr_i,
	output wire done_wr_o,

	input wire do_rd_i,
	output wire done_rd_o,

	input wire get_rd_i,
	output wire done_get_rd_o,
	output wire [15:0] test_rd_data_o,

    output wire [4:0] status_o,
	output wire [5:0] wait_counter_o,
    output wire rd_error_o,
    output wire [4:0] debug_error_n_o
);

reg [4:0] status = 5'b11110;
assign status_o = status;
reg [5:0] read_hcounter = 6'd0;
reg [8:0] read_vcounter = 9'd0;
reg [5:0] wait_counter = 6'd0;

assign wait_counter_o = wait_counter;

assign addr_o = ((status >= 5'b01000) & (status < 5'b11000))? debug_addr_r:{2'd0, read_vcounter, read_hcounter[3:0], 6'b00_0000};

reg [DATA_MASK_WIDTH-1:0] data_mask_r;
reg cmd_en_r;
reg cmd_r;

assign cmd_o = cmd_r;
assign cmd_en_o = cmd_en_r;
assign data_mask_o = data_mask_r;

reg [4*DQ_WIDTH-1:0] rd_data_r;
reg [4:0] debug_error_n = 4'd0;
reg rd_error_r = 1'b0;

assign rd_error_o = rd_error_r;
assign debug_error_n_o = debug_error_n;

reg ese_axis_tvalid_r = 1'b0;
reg ese_axis_tuser_r = 1'b0;
reg ese_axis_tuser_rr;
reg ese_axis_tlast_r = 1'b0;

assign ese_axis_tvalid = ese_axis_tvalid_r;
assign ese_axis_tuser = ese_axis_tuser_rr;
assign ese_axis_tlast = ese_axis_tlast_r;
assign ese_axis_tdata = rd_data_r;

reg [20:0] debug_addr_r;
reg [15:0] test_wr_data_r;
wire [15:0] wr_data_aw[0:3];
assign wr_data_aw[0] = test_wr_data_r;
assign wr_data_aw[1] = test_wr_data_r + 1;
assign wr_data_aw[2] = test_wr_data_r + 2;
assign wr_data_aw[3] = test_wr_data_r + 3;

reg [31:0] background_color_r;

assign wr_data_o = (status < 5'b11000)?
{
	wr_data_aw[3],
	wr_data_aw[2],
	wr_data_aw[1],
	wr_data_aw[0]
}: {background_color_r, background_color_r};

reg done_wr_r = 1'b0;
assign done_wr_o = done_wr_r;
reg done_rd_r = 1'b0;
assign done_rd_o = done_rd_r;
reg done_get_rd_r = 1'b0;
assign done_get_rd_o = done_get_rd_r;

reg [4*DQ_WIDTH-1:0] test_rd_data_cache[0:31];
wire [6:0] test_rd_addr_cache_w;
assign test_rd_addr_cache_w = debug_addr_r[6:0];
wire [4*DQ_WIDTH-1:0] test_rd_data_cache_w;
assign test_rd_data_cache_w = test_rd_data_cache[test_rd_addr_cache_w[6:2]];
assign test_rd_data_o = 
	(debug_addr_r[1:0] == 2'b00)?test_rd_data_cache_w[15:0]:
	(debug_addr_r[1:0] == 2'b01)?test_rd_data_cache_w[31:16]:
	(debug_addr_r[1:0] == 2'b10)?test_rd_data_cache_w[47:32]:
	                             test_rd_data_cache_w[63:48];

always @(posedge psram_clock) begin
    ese_axis_tuser_rr <= #1 ese_axis_tuser_r;
    data_mask_r <= #1 {DATA_MASK_WIDTH{1'b0}};
	case (status) 
	5'd0: begin
		if (init_calib_i & vsync_i) begin
			status <= #1 5'd1;
		end
		read_hcounter <= #1 6'd0;
		read_vcounter <= #1 9'd0;
        ese_axis_tuser_r <= #1 1'b1;
	end

	// Start Read!
	5'd1: begin
		if ( ~almost_full_i ) begin
			status <= #1 5'd2;
			cmd_en_r <= #1 1'b1;
		end
        
        cmd_r <= #1 1'b0;
		// 16 latency
		wait_counter <= #1 6'd0;
	end
	5'd2: begin
		cmd_en_r <= #1 1'b0;

		if ( wait_counter == 6'd15 ) begin
			status <= #1 5'd3;
			wait_counter <= #1 6'd0;
			read_hcounter <= #1 read_hcounter + 6'd1;
		end else begin
			wait_counter <= #1 wait_counter + 6'd1;
		end
	end

	5'd3: begin
		rd_data_r <= #1 rd_data_i;
        ese_axis_tvalid_r <= #1 1'b1;
        ese_axis_tuser_r <= #1 1'b0;

		if (rd_data_valid_i == 1'b0) begin
			// error!!
			rd_error_r <= #1 1'b1;
			debug_error_n <= #1 debug_error_n + 5'd1;
		end

		if ( wait_counter == 6'd31 ) begin
			// 32 burst
			status <= #1 5'd4;
			wait_counter <= #1 6'd0;

            ese_axis_tlast_r <= #1 ( read_hcounter == 10 );
		end else begin
			wait_counter <= #1 wait_counter + 6'd1;
		end
	end

	5'd4: begin
        ese_axis_tvalid_r <= #1 1'b0;
		ese_axis_tlast_r <= #1 1'd0;
		if ( read_hcounter == 10 ) begin
			read_hcounter <= #1 6'd0;
			status <= #1 5'd5;
			read_vcounter <= #1 read_vcounter + 9'd1;
		end else begin
			status <= #1 5'd1;
		end
	end

	5'd5: begin
        if ( read_vcounter == 9'd480 ) begin
            read_vcounter <= #1 9'd0;
            status <= #1 5'd6;
        end else begin
            status <= #1 5'd1;
		end
	end

	5'd6: begin
		if ( do_wr_i ) begin
            status <= #1 5'b01000;
        end else begin
            ese_axis_tuser_r <= #1 1'b1;
            status <= #1 5'd1;
        end
	end

	//----------------------------------------------------------------
	// for debug
	5'b01000: begin
		debug_addr_r <= addr_i;
		if (do_wr_i) begin
			status <= 5'b01001;
		end else if ( do_rd_i ) begin
			status <= 5'b10000;
		end else if ( get_rd_i ) begin
			status <= 5'b00000;
		end
		// get_rd_i is deprecated
	end

	//----------------------------------------------------------------
	// Write 
	5'b01001: begin
		cmd_en_r <= 1'b1;
		cmd_r <= 1'b1; // write
		test_wr_data_r <= test_wr_data_i;
		wait_counter <= 6'd0;
		status <= 5'b01010;
	end

	5'b01010: begin
		cmd_en_r <= 1'b0;
		cmd_r <= 1'b0;
		test_wr_data_r <= test_wr_data_r + 16'd4;
		if ( wait_counter == 6'b01_1111 ) begin
			// 32 burst
			status <= 5'b01011;
			wait_counter <= 6'd0;
		end else begin
			wait_counter <= wait_counter + 6'd1;
		end
	end

	5'b01011: begin
		if ( wait_counter == 6'b00_1111 ) begin
			// wait 16 clock
			status <= 5'b01100;
			wait_counter <= 6'd0;
		end else begin
			wait_counter <= wait_counter + 6'd1;
		end
	end

	5'b01100: begin
		if ( do_wr_i == 1'b0 ) begin
			done_wr_r <= 1'b0;
			status <= 5'b01000;
		end else begin
			done_wr_r <= 1'b1;
		end
	end

	//----------------------------------------------------------------
	// Read 
	5'b10000: begin
		cmd_en_r <= #1 1'b1;
        cmd_r <= #1 1'b0;

		wait_counter <= 6'd0;
		// 16 latency

		status <= 5'b10001;
	end
	 
	5'b10001: begin
		cmd_en_r <= #1 1'b0;

		if (rd_data_valid_i == 1'b1) begin
			rd_error_r <= #1 1'b1;
		end
		if ( wait_counter == 6'd15 ) begin
			status <= #1 5'b10010;
			wait_counter <= #1 6'd0;
		end else begin
			wait_counter <= #1 wait_counter + 6'd1;
		end
	end

	5'b10010: begin
		test_rd_data_cache[wait_counter] <= rd_data_i;

		if ( wait_counter == 6'd31 ) begin
			status <= #1 5'b10011;
			wait_counter <= #1 6'd0;
		end

		if (rd_data_valid_i == 1'b0) begin
			rd_error_r <= #1 1'b1;
		end
        wait_counter <= #1 wait_counter + 6'd1;
    end
	5'b10011: begin
		if ( do_rd_i == 1'b0 ) begin
			done_rd_r <= 1'b0;
			status <= 5'b01000;
		end else begin
			done_rd_r <= 1'b1;
		end
	end

	//----------------------------------------------------------------
	// Write Background
	5'b11000: begin
		cmd_en_r <= 1'b1;
		cmd_r <= 1'b1; // write
		wait_counter <= 6'd0;
		status <= 5'b11001;
	end

	5'b11001: begin
		cmd_en_r <= 1'b0;
		cmd_r <= 1'b0;
		if ( wait_counter == 6'b01_1111 ) begin
			// 32 burst
			status <= 5'b11010;
			wait_counter <= 6'd0;
			read_hcounter <= read_hcounter + 6'd1;
		end else begin
			wait_counter <= wait_counter + 6'd1;
		end
	end

	5'b11010: begin
		if ( wait_counter == 6'b11_1111 ) begin
			// wait 16 clock
			status <= 5'b11011;
			wait_counter <= 6'd0;
		end else begin
			wait_counter <= wait_counter + 6'd1;
		end
	end

	5'b11011: begin
		if ( read_hcounter == 6'd10 ) begin
			read_hcounter <= 6'd0;
			read_vcounter <= read_vcounter + 9'd1;
			status <= 5'b11100;
		end else begin
			status <= 5'b11000;
		end
	end

	5'b11100: begin
		if ( read_vcounter == 9'd480 ) begin
			status <= 5'b00000;
		end else begin 
			status <= 5'b11000;
		end
	end

	5'b11110: begin
        background_color_r <= { 32'h00800000, 32'h00800000 };
		read_hcounter <= 6'd0;
		read_vcounter <= 9'd0;
		rd_error_r <= 1'b0;
		if (init_calib_i) begin
            status <= 5'b11000;
		end
	end

	endcase
end

endmodule
`default_nettype wire
