`default_nettype none
module pila #(
    parameter integer WIDTH = 16,
    parameter integer ADDR_WIDTH = 8
) (
    input wire cap_clk,
	input wire rst,

	input wire capture_i,
	input wire [WIDTH-1:0] data_i,

    input wire peek_clk, // but not used
	input wire [ADDR_WIDTH-1:0] addr_i,	
	output wire [WIDTH-1:0] data_o,

	output wire [ADDR_WIDTH-1:0] write_addr_o
);

reg [WIDTH-1:0] data_buf[0:2**ADDR_WIDTH-1];
reg [ADDR_WIDTH-1:0] write_addr_r = {ADDR_WIDTH{1'b0}};

assign write_addr_o = write_addr_r;
assign data_o = data_buf[addr_i];

always @(posedge cap_clk) begin
	if (rst) begin
		write_addr_r <= #1 0;
	end else if ( capture_i ) begin
		if (~(write_addr_r == {ADDR_WIDTH{1'b1}})) begin
			data_buf[write_addr_r] <= #1 data_i;
			write_addr_r <= #1 write_addr_r + 1;
		end
	end
end

endmodule
`default_nettype wire
