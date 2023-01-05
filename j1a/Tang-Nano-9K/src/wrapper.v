`default_nettype none

module wrapper ( 
    input wire clk,
	input wire rst,

    input wire tx_req,
    input wire [7:0] tx_data,
    output wire tx_busy,

    output reg i_tx_en,
    output reg [2:0] waddr,
    output reg [7:0] wdata,

    output reg i_rx_en,
    output reg [2:0] raddr,
    input wire [7:0] rdata,

    input wire rx_req,
    output reg rx_valid,
    output reg [7:0] rx_data
);

reg [4:0] status = 5'd0;
reg [7:0] rdata_r = 8'd0;

reg [7:0] tx_data_r;

reg [4:0] next_status = 5'd0;

reg tx_req_r;
reg tx_busy_r;
assign tx_busy = tx_busy_r | tx_req_r;

always @(posedge clk) begin
    case (status)
	5'd0: begin
		if (tx_req_r == 1'b1) begin
			tx_busy_r <= 1'b1;
			next_status <= 5'd7;
			status <= 5'd1;
		end else begin
			next_status <= 5'd0;
			if ((rdata_r[0] == 1'b1) & (rx_valid == 1'b0)) begin
				status <= 5'd10;
			end else begin
				status <= 5'd1;
			end
		end
	end

	5'd1: begin
		i_rx_en <= 1'b1;
		raddr <= 3'h05; // LSR
		status <= 5'd2;
	end

	5'd2: begin
		i_rx_en <= 1'b0;
		status <= 5'd3;
	end

	5'd3: begin
		status <= 5'd4;
	end

	5'd4: begin
		status <= 5'd5;
	end

	5'd5: begin
		status <= 5'd6;
	end

	5'd6: begin
		rdata_r <= rdata;
		if ( rdata[6] == 1'b0 ) begin
			status <= 5'd1;
		end else begin
			status <= next_status;
		end
	end

	5'd7: begin
		i_tx_en <= 1'b1;
		waddr <= 3'h00;
		wdata <= tx_data_r;

		status <= 5'd8;
	end

	5'd8: begin
		i_tx_en <= 1'b0;
		status <= 5'd1;
		next_status <= 5'd9;
	end

	5'd9: begin
		tx_busy_r <= 1'b0;
		if ( tx_req_r == 1'b0 ) begin
			status <= 5'd0;
		end
	end

	// RECEIVE

	5'd10: begin
		i_rx_en <= 1'b1;
		raddr <= 3'h00; // DATA
		status <= 5'd11;
	end

	5'd11: begin
		i_rx_en <= 1'b0;
		status <= 5'd12;
	end

	5'd12: begin
		status <= 5'd13;
	end

	5'd13: begin
		status <= 5'd14;
	end

	5'd14: begin
		status <= 5'd15;
	end

	5'd15: begin
		rx_data <= rdata;
		status <= 5'd0;
	end

	endcase
end

always @(posedge clk) begin
	if ( tx_req_r == 1'b0 ) begin
		if ( tx_req == 1'b1 ) begin
			tx_req_r = 1'b1;
			tx_data_r <= tx_data;
		end
	end else begin
		if ( status == 5'd9 ) begin
			tx_req_r = 1'b0;
		end
	end
end

always @(posedge clk) begin
	if ( rx_valid == 1'b0 ) begin
		if (status == 5'd15) begin
			rx_valid <= 1'b1;
		end
	end else begin
		if (rx_req == 1'b1) begin
			rx_valid <= 1'b0;
		end
	end
end


endmodule

`default_nettype wire
