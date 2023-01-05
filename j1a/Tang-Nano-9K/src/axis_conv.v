`default_nettype none
module axis_conv #(
    parameter integer DQ_WIDTH = 16,
    parameter integer ADDR_WIDTH = 21
) (
    input wire psram_clock,
    input wire rst,

    input wire in_ese_axis_tvalid,
    input wire in_ese_axis_tuser,
    input wire in_ese_axis_tlast,
    input wire [4*DQ_WIDTH-1:0] in_ese_axis_tdata, 

    output wire almost_full_o,
    output wire almost_empty_o,
    output wire [10:0] rnum_o,
    output wire [9:0] wnum_o,
    output wire empty_o,
    output wire full_o,
    output wire rd_en_o,
    output wire wr_en_o,
    
    input wire pixclk,
    output wire out_axis_tvalid,
    input wire out_axis_tready,
    output wire out_axis_tuser,
    output wire out_axis_tlast,
    output wire [23:0] out_axis_tdata
);
	wire almost_full_w;
	wire almost_empty_w;
	wire empty_w;
	wire full_w;
	wire [10:0] rnum_w;
	wire [9:0] wnum_w;

	//----------------------------------------------------------------	
	// write 
    wire wr_en_w;
    wire [51:0] wr_data_w;
    assign wr_en_w = in_ese_axis_tvalid;
    assign wr_data_w = 
        {1'b0, in_ese_axis_tlast, in_ese_axis_tdata[55:32],
         in_ese_axis_tuser, 1'b0, in_ese_axis_tdata[23:0] };

    assign wr_en_o = wr_en_w;

	//----------------------------------------------------------------
	// read
    wire rd_en_w;

	reg rd_req_r = 1'b0;
	reg tvalid_r = 1'b0;
	reg overflow_r = 1'b0;

	wire req;
	assign req = ~empty_w & (( ~rd_req_r & ~tvalid_r) | out_axis_tready );

	wire stay_tvalid_w;
	assign stay_tvalid_w = (tvalid_r & ~out_axis_tready);
    wire [25:0] rd_data_w;
	reg [25:0] saved_tdata_r;

	always @(posedge pixclk) begin
        if ( overflow_r ) begin
            overflow_r <= ~( tvalid_r & out_axis_tready );
            rd_req_r <= 1'b0;
        end else begin
            if (rd_req_r & stay_tvalid_w) begin
                overflow_r <= 1'b1;
                saved_tdata_r <= rd_data_w;
            end
            rd_req_r <= req;
            tvalid_r <= rd_req_r | stay_tvalid_w;
		end
	end

	wire [25:0] out_tdata_w;
	assign out_tdata_w = overflow_r?saved_tdata_r:rd_data_w;

    assign {out_axis_tuser, out_axis_tlast, out_axis_tdata } = out_tdata_w;
	assign out_axis_tvalid = tvalid_r;

    assign rd_en_w = rd_req_r;
	assign rd_en_o = rd_req_r;

	//----------------------------------------------------------------
    FIFO_HS_PSRAM_TO_SVO svo_fifo0 (
		.Reset(rst),

		.WrClk(psram_clock), //input WrClk
		.WrEn(wr_en_w), //input WrEn
		.Data(wr_data_w), //input [51:0] Data
		.Wnum(wnum_w), //output [9:0] Rnum

		.RdClk(pixclk), //input RdClk
		.RdEn(rd_en_w), //input RdEn
		.Q(rd_data_w), //output [25:0] Q

		.Rnum(rnum_w), //output [10:0] Rnum
		.Almost_Empty(almost_empty_w),
		.Almost_Full(almost_full_w),
		.Empty(empty_w), //output Empty
		.Full(full_w) //output Full
	);

    assign almost_full_o = almost_full_w;
    assign almost_empty_o = almost_empty_w;
	assign rnum_o = rnum_w;
	assign wnum_o = wnum_w;
	assign empty_o = empty_w;
	assign full_o = full_w;

endmodule
