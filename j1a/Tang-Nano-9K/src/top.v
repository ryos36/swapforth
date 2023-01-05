`default_nettype none
module top(
    input wire clock,
    input wire sw0_i,
    input wire sw1_i,

    output wire [CS_WIDTH-1:0] O_psram_ck,
    output wire [CS_WIDTH-1:0] O_psram_ck_n,
    inout wire [CS_WIDTH-1:0] IO_psram_rwds,
    inout wire [DQ_WIDTH-1:0] IO_psram_dq,
    output wire [CS_WIDTH-1:0] O_psram_reset_n,
    output wire [CS_WIDTH-1:0] O_psram_cs_n,

    output wire tmds_clk_n,
    output wire tmds_clk_p,
    output wire [2:0] tmds_d_n,
    output wire [2:0] tmds_d_p,

    output wire uart_tx,
    input wire uart_rx,
    output wire [5:0] led_o
);
localparam DQ_WIDTH = 16;
localparam ADDR_WIDTH = 21;
localparam CS_WIDTH = 2;
localparam WIDTH = 24;

localparam integer SVO_BITS_PER_PIXEL = 24;

wire lock_w;
wire memory_clk_w;
wire clkoutd3_w;
wire clk_d_w;

wire reset;

Gowin_rPLL PLL_U0(
    .clkout(memory_clk_w), //output clkout
    .lock(lock_w), //output lock

    .clkoutd(clk_d_w), //output clkoutd
    .clkoutd3(clkoutd3_w), //output clkoutd3

    .clkin(clock) //input clkin
);

assign reset = ~sw0_i;

reg [7:0] my_data_r;
reg [5:0] led_r;

//assign led_o = ~led_r;
//assign led_o[1:0] = ~led_r[3:0];

initial begin
    led_r <= 0;
end

//----------------------------------------------------------------
wire [15:0] mem_addr_w;
wire [15:0] dout_w;
wire [15:0] io_din_w;
wire [12:0] code_addr_w;
wire [15:0] insn_w;
wire io_rd_w;
wire io_wr_w;
wire mem_wr_w;

j1 j10 (
	.clk(clk_d_w),
	.resetq(1'b1),

	.io_rd(io_rd_w),
	.io_wr(io_wr_w),

	.mem_addr(mem_addr_w),
	.mem_wr(mem_wr_w),
	.dout(dout_w),

	.io_din(io_din_w),

	.code_addr(code_addr_w),
	.insn(insn_w)
);

//----------------------------------------------------------------
wire SOUT_w;
wire SIN_w;
assign uart_tx = SOUT_w;
assign SIN_w = uart_rx;

wire I_TX_EN_w;
wire [2:0] I_WADDR_w;
wire [7:0] I_WDATA_w;

wire I_RX_EN_w;
wire [2:0] I_RADDR_w;
wire [7:0] O_RDATA_w;

UART_MASTER_Top UART_0 (
	.I_CLK(clk_d_w), //input I_CLK
	.I_RESETN(1'b1), //input I_RESETN
	
	.I_TX_EN(I_TX_EN_w), //input I_TX_EN
	.I_WADDR(I_WADDR_w), //input [2:0] I_WADDR
	.I_WDATA(I_WDATA_w), //input [7:0] I_WDATA

	.I_RX_EN(I_RX_EN_w), //input I_RX_EN
	.I_RADDR(I_RADDR_w), //input [2:0] I_RADDR
	.O_RDATA(O_RDATA_w), //output [7:0] O_RDATA

	.SIN(SIN_w), //input SIN
	//.RxRDYn(RxRDYn_o), //output RxRDYn

	.SOUT(SOUT_w), //output SOUT
	//.TxRDYn(TxRDYn_o), //output TxRDYn

	//.DDIS(DDIS_o), //output DDIS
	//.INTR(INTR_o), //output INTR

	.DCDn(1'b0), //input DCDn
	.CTSn(1'b0), //input CTSn
	.DSRn(1'b0), //input DSRn

	.RIn(1'b0) //input RIn
	//.DTRn(DTRn_o), //output DTRn
	//.RTSn(RTSn_o) //output RTSn
);

//----------------------------------------------------------------
reg io_wr_r, io_rd_r;
reg [15:0] dout_r;
reg [15:0] io_addr_r;

always @(posedge clk_d_w) begin
    {io_rd_r, io_wr_r, dout_r} <= {io_rd_w, io_wr_w, dout_w};
    if (io_rd_w | io_wr_w) begin
        io_addr_r <= mem_addr_w;
    end
end

//----------------------------------------------------------------
// UART

wire tx_busy_w;
wire tx_req_w;
wire [7:0] tx_data_w;

assign tx_data_w = dout_r;
assign tx_req_w = io_wr_r & io_addr_r[12];

wire rx_valid_w;
wire rx_req_w;
wire [7:0] rx_data_w;

assign rx_req_w = io_rd_r & io_addr_r[12];

wrapper wrapper_u0
(
	.clk(clk_d_w),
	.rst(reset),

	.i_tx_en(I_TX_EN_w),
	.waddr(I_WADDR_w),
	.wdata(I_WDATA_w),

    .tx_req(tx_req_w),
    .tx_data(tx_data_w),
    .tx_busy(tx_busy_w),

	.i_rx_en(I_RX_EN_w),
	.raddr(I_RADDR_w),
	.rdata(O_RDATA_w),

    .rx_req(rx_req_w),
    .rx_valid(rx_valid_w),
    .rx_data(rx_data_w)
);

//----------------------------------------------------------------
/*
wire chat_out_w;

Chat_chat0 chat0
  (
    .clk(clk_d_w),
    .rst(1'b0),

    .in_bit(sw1_i),
    .out_bit(chat_out_w)
  );

reg kick_tx_r;
reg kick_tx_d;
wire kick_tx_w;
assign kick_tx_w = kick_tx_d & ~kick_tx_r;
reg [23:0] counter;
reg counter_23_d;

always @(posedge clk_d_w) begin
    counter_23_d <= counter[23];
    counter <= counter + 1;

    if ( ~counter_23_d & counter[23] ) begin
        kick_tx_d <= kick_tx_r;
        kick_tx_r <= ~chat_out_w;
    end
end
*/


/*
Transmitter_tx tx_u0
(
	.clk(clk_d_w),
	.rst(reset),

    .kick_tx(kick_tx_w),

    .rx_valid(rx_valid_w),
    .rx_req(rx_req_w),
    .rx_data(rx_data_w),

    .tx_busy(tx_busy_w),
    .tx_data(tx_data_w),
    .tx_req(tx_req_w)
);
*/

//----------------------------------------------------------------

wire [7:0] uart0_data_w;
wire uart0_busy_w;
wire uart0_valid_w;

assign uart0_data_w = rx_data_w;
assign uart0_busy_w = tx_busy_w;
assign uart0_valid_w = rx_valid_w;

//----------------------------------------------------------------
// ######   IO PORTS   ######################################

/*        bit   mode    device
  0001  0     r/w     GPIO (not used)
  0002  1     r/w     GPIOI direction (not used)
  0004  2     r/w     LEDS
  0008  3     r/w     misc.out (not used)
  0010  4     r/w     HDR1 GPIO (not used)
  0020  5     r/w     HDR1 direction (not used)
  0040  6     r/w     HDR2 GPIO (not used)
  0080  7     r/w     HDR2 direction (not used)
  0800  11      w     sb_warmboot
  1000  12    r/w     UART RX, UART TX
  2000  13    r       misc.in (sw0, sw1)
*/

// 0 ... tpg
// 1 ... tcard
// 2 ... bufstream
reg [1:0] from_psram_r = 2'd2;

// for j1
localparam integer ILA_ADDR_WIDTH = 8;
wire [15:0] ila_mem_data_w; // read
wire [ILA_ADDR_WIDTH-1:0] ila_mem_addr_w;  // write
wire [ILA_ADDR_WIDTH-1:0] ila_wr_addr_w;   // read

reg [ILA_ADDR_WIDTH-1:0] ila_mem_addr_r;  // write
assign ila_mem_addr_w = ila_mem_addr_r;

//
reg [14:0] video_cap_hcounter_r;
reg [14:0] video_cap_vcounter_r;

reg video_capturing_r = 1'b0;
reg video_cap_req_r = 1'b0;
wire video_cap_done_w;
wire [23:0] video_cap_data_w;

wire [3:0] io_status_w;
wire io_init_calib_w;
wire rd_error_w;
wire [15:0] ps_data_w;
wire [31:0] out_frame_w;

wire [31:0] io_addr_01_w;
wire [31:0] io_addr_45_w;

assign io_din_w =
    (io_addr_r[0] ? io_addr_01_w[15:0] : 16'd0) |
    (io_addr_r[1] ? io_addr_01_w[31:16] : 16'd0) |
    (io_addr_r[2] ? {{(16-ILA_ADDR_WIDTH){1'd0}}, ila_wr_addr_w} : 16'd0) |
    (io_addr_r[3] ? ila_mem_data_w[15:0] : 16'd0) |

    (io_addr_r[4] ? io_addr_45_w[15:0] : 16'd0) |
    (io_addr_r[5] ? io_addr_45_w[31:16] : 16'd0) |
	/*
    (io_addr_r[4] ? video_cap_data_w[15:0] : 16'd0 ) |
    (io_addr_r[5] ? {video_cap_done_w, ~video_capturing_r, 6'd0, video_cap_data_w[23:16]} : 16'd0 ) |
	*/
    (io_addr_r[6] ? {14'd0, from_psram_r} : 16'd0 ) |

    (io_addr_r[7] ? ps_data_w : 16'd0) |
    (io_addr_r[8] ? ps_test_rd_data_w : 16'd0) |

    (io_addr_r[9] ? {wait_counter_w[4:0], ps_done_get_rd_w, ps_done_rd_w, ps_done_wr_w, rd_error_w,
    ps_do_wr_r, ps_do_rd_r, psraman_status_w} : 16'd0) |


    (io_addr_r[12] ? {8'd0, uart0_data_w} : 16'd0) |
    (io_addr_r[13] ? {11'd0, io_init_calib_w, rd_error_w, sw1_i, uart0_valid_w, !uart0_busy_w} : 16'd0);

//----------------------------------------------------------------

always @(posedge clk_d_w) begin
	if (io_wr_r & io_addr_r[3]) begin
        ila_mem_addr_r <= dout_r[ILA_ADDR_WIDTH-1:0];
    end
	if (io_wr_r & io_addr_r[2]) begin
		led_r <= dout_r[5:0];
	end
	/*
    if ( io_wr_r & io_addr_r[4] ) begin
		video_capturing_r <= ~dout_r[15];
        video_cap_vcounter_r <= dout_r[14:0];
    end
    if ( io_wr_r & io_addr_r[5] ) begin
        video_cap_req_r <= dout_r[15];
        video_cap_hcounter_r <= dout_r[14:0];
    end
	*/
    if ( io_wr_r & io_addr_r[4] ) begin
		fps_sw_r <= dout_r[0];
	end
    if ( io_wr_r & io_addr_r[5] ) begin
        ps_test_wr_data_r = dout_r;
    end

    if ( io_wr_r & io_addr_r[6] ) begin
        from_psram_r <= dout_r[1:0];
    end

    if ( io_wr_r & io_addr_r[9] ) begin
        ps_do_wr_r <= dout_r[8];
        ps_do_rd_r <= dout_r[9];
        ps_get_rd_r <= dout_r[10];
    end
    if ( io_wr_r & io_addr_r[7] ) begin
        ps_addr_r[15:0] <= dout_r;
    end
    if ( io_wr_r & io_addr_r[8] ) begin
        ps_addr_r[20:16] <= dout_r[4:0];
    end
end

//----------------------------------------------------------------

wire mem0_wr_w;
assign mem0_wr_w = mem_wr_w & !mem_addr_w[13];
Gowin_DPB MEM0(
	// read for INSN
	.clka(clk_d_w), //input clka
	.cea(1'd1), //input cea
	.ocea(1'd0), //input ocea
	.reseta(1'd0), //input reseta
	.wrea(1'd0), //input wrea

	.ada(code_addr_w[11:0]), //input [11:0] ada
	.douta(insn_w), //output [15:0] douta
	.dina(16'd0), //input [15:0] dina 

	// write for mem
	.clkb(clk_d_w), //input clkb
	.ceb(1'b1), //input ceb
	.oceb(1'b0), //input oceb
	.resetb(1'b0), //input resetb
	.wreb(mem0_wr_w), //input wreb

	.adb(mem_addr_w[12:1]), //input [11:0] adb
	//.doutb(), //output [15:0] doutb
	.dinb(dout_w) //input [15:0] dinb
);

//----------------------------------------------------------------
wire video_tvalid_ref_w;
wire [23:0] video_tdata_ref_w;
wire [0:0] video_tuser_ref_w;

//----------------------------------------------------------------
wire clk_pixel;
wire clk_5x_pixel;
wire clk_5x_pixel_lock_w;

assign clk_5x_pixel = memory_clk_w;
assign clk_5x_pixel_lock_w = lock_w;

Gowin_CLKDIV CLKDIV_for_640x480(
    .clkout(clk_pixel), //output clkout
    .hclkin(clk_5x_pixel), //input hclkin
    .resetn(1'b1) //input resetn
);


reg uart0_rx_valid_r;
reg [7:0] uart0_rx_data_r;

always @(posedge clk_d_w) begin
	uart0_rx_valid_r <= rx_req_w | tx_req_w;
	uart0_rx_data_r <= rx_req_w?rx_data_w:tx_data_w;
end

wire uart0_rx_valid_w;
wire [7:0] uart0_rx_data_w;
//assign uart0_rx_valid_w = rx_req_w;
//assign uart0_rx_data_w = rx_req_w?rx_data_w:tx_data_w;
assign uart0_rx_valid_w = uart0_rx_valid_r;
assign uart0_rx_data_w = uart0_rx_data_r;

wire fifo_read_en_w;
wire [7:0] fifo_read_data_w;
wire [1:0] fifo_read_num_w;

wire output_empty_w;

FIFO_HS_Top UART_FIFO0 (
    .WrClk(clk_d_w), //input WrClk
    .WrEn(uart0_rx_valid_w), //input WrEn
    .Data(uart0_rx_data_w), //input [7:0] Data

    .RdClk(clk_pixel), //input RdClk
    .RdEn(fifo_read_en_w), //input RdEn
    .Q(fifo_read_data_w), //output [7:0] Q

    .Rnum(fifo_read_num_w), //output [1:0] Rnum

    .Empty(output_empty_w), //output Empty
    .Full() //output Full
);

wire fifo_empty_w;
assign fifo_empty_w = (fifo_read_num_w == 2'b00);

reg term_in_tvalid_r;
reg [7:0] term_in_tdata_r;
reg fifo_read_en_r;

assign fifo_read_en_w = fifo_read_en_r;

assign led_o[5] = ~output_empty_w;
assign led_o[4] = ~fifo_empty_w;
assign led_o[3] = ~term_in_tvalid_r;
assign led_o[2] = ~fifo_read_en_r;
assign led_o[1:0] = ~fifo_read_num_w;

always @(posedge clk_pixel) begin
    if ( term_in_tvalid_r == 1'b0 ) begin
        if ( fifo_read_en_r == 1'b0 ) begin
            if ( ~output_empty_w ) begin
                fifo_read_en_r <= 1'b1;
            end
        end else begin
            fifo_read_en_r <= 1'b0;
            term_in_tdata_r <= fifo_read_data_w;
            term_in_tvalid_r <= 1'b1;
        end
    end else begin
        term_in_tvalid_r <= 1'b0;
    end
end

wire term_out_tready_w;
wire term_in_tvalid_w;
wire [7:0] term_in_tdata_w;

assign term_in_tvalid_w = term_in_tvalid_r & ~video_capturing_r;
assign term_in_tdata_w = term_in_tdata_r;

wire vdma_tvalid_w;
wire vdma_tready_w;
wire [23:0] vdma_tdata_w;
wire [0:0] vdma_tuser_w;

svo_hdmi_top HDMI0 (
    .clk(clk_pixel),
    .resetn(1'b1),

    .clk_pixel(clk_pixel),
    .clk_5x_pixel(clk_5x_pixel),
    .locked(clk_5x_pixel_lock_w),

	.vdma_tvalid(vdma_tvalid_w),
	.vdma_tready(vdma_tready_w),
	.vdma_tdata(vdma_tdata_w),
	.vdma_tuser(vdma_tuser_w),

    .term_in_tvalid(term_in_tvalid_w),
    .term_out_tready(term_out_tready_w),
    .term_in_tdata(term_in_tdata_w),

	.video_tvalid_ref_o(video_tvalid_ref_w),
	.video_tdata_ref_o(video_tdata_ref_w),
	.video_tuser_ref_o(video_tuser_ref_w),

    // output signals
    .tmds_clk_n(tmds_clk_n),
    .tmds_clk_p(tmds_clk_p),
    .tmds_d_n(tmds_d_n),
    .tmds_d_p(tmds_d_p)
);

//----------------------------------------------------------------
wire tcard_tvalid_w;
wire tcard_tready_w;
wire tcard_tuser_w;
wire [SVO_BITS_PER_PIXEL-1:0] tcard_tdata_w;

svo_tcard svo_tcard0 (
	.clk(clk_pixel),
	.resetn(1'b1),

	.out_axis_tvalid(tcard_tvalid_w),
	.out_axis_tready(tcard_tready_w),
	.out_axis_tdata(tcard_tdata_w),
	.out_axis_tuser(tcard_tuser_w)
);

//----------------------------------------------------------------
wire psram_clock;
wire init_calib_w;

wire [4*DQ_WIDTH-1:0] wr_data_w /* synthesis syn_keep=1 */;
wire [4*DQ_WIDTH-1:0] rd_data_w /* synthesis syn_keep=1 */;
wire cmd_w;
wire cmd_en_w;
wire [ADDR_WIDTH-1:0] addr_w;
wire [4*CS_WIDTH-1:0] data_mask_w;
wire rd_data_valid_w;

PSRAM_Memory_Interface_HS_Top PSRAM_U1 (
    .clk(clk_d_w), //input clk
    .memory_clk(clkoutd3_w), //input memory_clk

    .pll_lock(lock_w), //input pll_lock
    .rst_n(1'b1), //input rst_n

    .O_psram_ck(O_psram_ck), //output [1:0] O_psram_ck
    .O_psram_ck_n(O_psram_ck_n), //output [1:0] O_psram_ck_n
    .IO_psram_dq(IO_psram_dq), //inout [15:0] IO_psram_dq
    .IO_psram_rwds(IO_psram_rwds), //inout [1:0] IO_psram_rwds
    .O_psram_cs_n(O_psram_cs_n), //output [1:0] O_psram_cs_n
    .O_psram_reset_n(O_psram_reset_n), //output [1:0] O_psram_reset_n

    .wr_data(wr_data_w), //input [63:0] wr_data
    .rd_data(rd_data_w), //output [63:0] rd_data
    .rd_data_valid(rd_data_valid_w), //output rd_data_valid
    .addr(addr_w), //input [20:0] addr
    .cmd(cmd_w), //input cmd
    .cmd_en(cmd_en_w), //input cmd_en

    .init_calib(init_calib_w), //output init_calib
    .clk_out(psram_clock), //output clk_out
    .data_mask(data_mask_w) //input [7:0] data_mask
);

//----------------------------------------------------------------
wire vsync_w;
wire vblank_w;
wire pixclk_vsync_w;

tgen tgen0 (
	.pixclk(clk_pixel),
	.pixclk_vsync(pixclk_vsync_w),

	.clk(psram_clock),
	.vsync(vsync_w),
	.vblank(vblank_w)
);

//----------------------------------------------------------------
// for PSRAM

wire almost_full_w;
wire ese_axis_tvalid_w;
wire ese_axis_tuser_w;
wire ese_axis_tlast_w;
wire [4*DQ_WIDTH-1:0] ese_axis_tdata_w; 

reg ps_do_wr_r = 1'b0;
reg ps_do_rd_r = 1'b0;
reg ps_get_rd_r = 1'b0;

wire [4:0] psraman_status_w;
wire ps_do_wr_w;
wire ps_done_wr_w;
wire ps_do_rd_w;
wire ps_done_rd_w;
wire ps_get_rd_w;
wire ps_done_get_rd_w;
wire [15:0] ps_test_rd_data_w;
wire [5:0] wait_counter_w;

wire [20:0] ps_addr_w;
reg [20:0] ps_addr_r = 21'd0;
assign ps_addr_w = ps_addr_r;

wire [15:0] ps_test_wr_data_w;
reg [15:0] ps_test_wr_data_r;
assign ps_test_wr_data_w = ps_test_wr_data_r;

assign ps_do_wr_w = ps_do_wr_r;
assign ps_do_rd_w = ps_do_rd_r;
assign ps_get_rd_w = ps_get_rd_r;

psraman #(
    .DQ_WIDTH(DQ_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) psraman0 (
    .psram_clock(psram_clock),
    
    .init_calib_i(init_calib_w),
    .rd_data_i(rd_data_w),
    .rd_data_valid_i(rd_data_valid_w),

    .wr_data_o(wr_data_w),
    .data_mask_o(data_mask_w),

    .addr_o(addr_w),
    .cmd_o(cmd_w),
    .cmd_en_o(cmd_en_w),

    .vsync_i(1'b1),
    .almost_full_i(almost_full_w),

    .ese_axis_tvalid(ese_axis_tvalid_w),
    .ese_axis_tuser(ese_axis_tuser_w),
    .ese_axis_tlast(ese_axis_tlast_w),
    .ese_axis_tdata(ese_axis_tdata_w),

    //----------------------------------------------------------------
	.addr_i(ps_addr_w),

	.test_wr_data_i(ps_test_wr_data_w),
	.do_wr_i(ps_do_wr_w),
	.done_wr_o(ps_done_wr_w),

	.do_rd_i(ps_do_rd_w),
	.done_rd_o(ps_done_rd_w),

	.get_rd_i(ps_get_rd_w),
	.done_get_rd_o(ps_done_get_rd_w),
	.test_rd_data_o(ps_test_rd_data_w),

	.wait_counter_o(wait_counter_w),
    .status_o(psraman_status_w),
    .rd_error_o(rd_error_w)
	/*
    .debug_error_n_o()
    */
);

//----------------------------------------------------------------
// ILA kick
wire [9:0] tuser_counter_w; // for j1
wire kick_tuser_cdc_pulse_w;
wire cap_peek_error_w;
//wire tp_tuser_w = ese_axis_tuser_w;
wire tp_tuser_w = tpg_tuser;

tuser_capture tuser_capture0
(
    .tp_clk(psram_clock),
    .tp_tuser(tp_tuser_w),
    .tp_tvalid_and_tready(ese_axis_tvalid_w), // no *ese_axis_tready_w*
    .tuser_counter_o(tuser_counter_w),

    .peek_clk(clk_pixel),
    .kick_tuser_cdc_pulse(kick_tuser_cdc_pulse_w),
    .error_o(cap_peek_error_w)
);


//----------------------------------------------------------------
wire lbuf_axis_tvalid_w;
wire lbuf_axis_tready_w;
wire lbuf_axis_tuser_w;
wire lbuf_axis_tlast_w;
wire [23:0] lbuf_axis_tdata_w;

wire [10:0] rnum_w;
wire [9:0] wnum_w;
wire empty_w;
wire full_w;
wire axis_rd_en_w;
wire axis_wr_en_w;
wire almost_empty_w;

//----------------------------------------------------------------
// TEST Pattern
reg fifo_reset = 1'b0;

reg [9:0] tpg_hcount = 10'd0;
reg [9:0] tpg_vcount = 10'd0;
reg tpg_tvalid = 1'd0;
reg tpg_tlast = 1'd0;
reg tpg_tuser = 1'd0;
reg [2:0] tpg_status = 3'b000;
wire tpg_tready_w;
wire [47:0] tpg_tdata_w;
assign tpg_tdata_w = { 2'b11, tpg_vcount, 2'b11, tpg_hcount, 2'b11, tpg_vcount, 2'b11, tpg_hcount };
reg [7:0] tpg_counter = 8'h00;

always @(posedge psram_clock) begin
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
			tpg_hcount <= ~10'd0;
			tpg_vcount <= 10'd0;
		end
		tpg_counter <= tpg_counter + 1;
	end
	3'b001: begin
		tpg_counter <= tpg_counter + 1;
		if ( ~almost_full_w ) begin
			tpg_tuser <= 1'b0;
			if ( tpg_hcount == 10'd317 ) begin
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
		if ( ~almost_full_w ) begin
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
		if ( tpg_vcount == 10'd480 ) begin
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

//----------------------------------------------------------------
wire [63:0] debug_lbuf_axis_tdata_w;
reg [7:0] debug_data_r = 8'd0;
assign debug_lbuf_axis_tdata_w = {ese_axis_tdata_w[63:7], debug_data_r};
always @(posedge psram_clock) begin
    debug_data_r <= debug_data_r + 1;
end

//----------------------------------------------------------------
/*
reg [1:0] dgen_status = 2'b11;
reg dgen_tvalid = 1'b0;
reg dgen_tuser = 1'b0;
reg dgen_tlast = 1'b0;
reg [63:0] dgen_tdata = 64'd0;
reg [3:0] dgen_counter = 4'd0;

wire tp_tuser_w;
assign tp_tuser_w = dgen_tuser;

always @(posedge psram_clock) begin
    case (dgen_status)
    2'b00: begin
        dgen_tuser <= 1'b1;
        dgen_tvalid <= 1'b1;
        dgen_tlast <= 1'b0;
        dgen_counter <= 4'hE;
        dgen_tdata <= {
            32'hBABEEF, 32'h55CAFE
        };
        dgen_status = 2'b01;
    end
    2'b01: begin
        dgen_tuser <= 1'b0;
        dgen_tdata <= {
			16'b0011110000111100,
            4'b0000, dgen_counter, ~dgen_counter, dgen_counter,
			16'b0110011001100110,
            4'b0000, ~dgen_counter, dgen_counter, ~dgen_counter
        };
        if ( dgen_counter == 4'hC ) begin
            dgen_status <= 2'b10;
            dgen_tlast <= 1'b1;
        end
        dgen_counter <= dgen_counter + 4'd1;

    end
    2'b10: begin
        dgen_tvalid <= 1'b0;
        dgen_tlast <= 1'b0;
    end
	2'b11: begin
		if ( fifo_reset == 1'b1 ) begin
			fifo_reset <= 1'b0;
		end else if ( dgen_counter == 4'd0 ) begin
			fifo_reset <= 1'b1;
		end else if ( dgen_counter == 4'hF ) begin
			dgen_status <= 2'b00;	
		end
        dgen_counter <= dgen_counter + 4'd1;
	end
    endcase
end
*/

//----------------------------------------------------------------
wire debug_axis_tready_w;

axis_conv #(
    .DQ_WIDTH(DQ_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) axis_conv0 (
    .psram_clock(psram_clock),
    .rst(fifo_reset),

    .in_ese_axis_tvalid(ese_axis_tvalid_w),
    .in_ese_axis_tuser(ese_axis_tuser_w),
    .in_ese_axis_tlast(ese_axis_tlast_w),
    .in_ese_axis_tdata(ese_axis_tdata_w), 

	/*
    .in_ese_axis_tvalid(tpg_tvalid),
    .in_ese_axis_tuser(tpg_tuser),
    .in_ese_axis_tlast(tpg_tlast),
    .in_ese_axis_tdata({
		8'h00,
		tpg_tdata_w[47:24],
		8'h00,
		tpg_tdata_w[23:0]
	}), 
	*/

	/*
    .in_ese_axis_tvalid(dgen_tvalid),
    .in_ese_axis_tuser(dgen_tuser),
    .in_ese_axis_tlast(dgen_tlast),
    .in_ese_axis_tdata(dgen_tdata), 
	*/

	.almost_full_o(almost_full_w),
    .rnum_o(rnum_w),
    .wnum_o(wnum_w),
    .empty_o(empty_w),
    .almost_empty_o(almost_empty_w),
    .full_o(full_w),
    .rd_en_o(axis_rd_en_w),
    .wr_en_o(axis_wr_en_w),
    
    .pixclk(clk_pixel),

    .out_axis_tvalid(lbuf_axis_tvalid_w),
    .out_axis_tready(lbuf_axis_tready_w),
    .out_axis_tuser(lbuf_axis_tuser_w),
    .out_axis_tlast(lbuf_axis_tlast_w),
    .out_axis_tdata(lbuf_axis_tdata_w)
);

//----------------------------------------------------------------
// Debug Counter
reg [31:0] debug_tuser_count = 32'h12345678;
reg [31:0] debug_tuser_count_r = 0;
reg [1:0] debug_status = 2'b00;

always @(posedge psram_clock) begin
    case (debug_status)
	2'b00: begin
        if ( tpg_tvalid ) begin
            if ( tpg_tuser ) begin
                debug_tuser_count_r <= debug_tuser_count;
				debug_tuser_count <= 32'd0;
            end else begin
				debug_tuser_count <= debug_tuser_count + 1;
			end
        end
    end
	2'b01: begin
        if ( tpg_tvalid ) begin
            if ( tpg_tlast ) begin
                //debug_status <= 2'b00;
            end
        end
    end
    endcase
end

reg [1:0] debug_in_status = 2'b00;
reg debug_axis_tready_r = 1'b0;
reg [31:0] debug_count = 0;
reg [31:0] debug_count_r = 0;
reg [7:0] ucount = 8'd0;
assign debug_axis_tready_w = debug_axis_tready_r;

always @(posedge clk_pixel) begin
    case (debug_in_status)
    2'b00: begin
        if (lbuf_axis_tvalid_w) begin
			if (lbuf_axis_tuser_w) begin
				ucount <= ucount + 1;
				debug_count_r <= debug_count;
				debug_count <= 32'd0;
			end else begin
				debug_count <= debug_count + 32'd1;
			end
		end
    end

    endcase
end

//----------------------------------------------------------------
// pila Kicker
reg ila_capture_r = 1'b0; // reset is ToDO
reg bs_tuser_r = 1'b0;
reg [1:0] bs_tuser_counter = 2'b0;
reg [31:0] ila_capture_counter = 32'd0;

reg bs_tready_r = 1'b0;
reg bs_tlast_r = 1'b0;
reg [1:0] bs_tready_counter = 2'b0;

always @(posedge clk_pixel) begin
	if (use_tp_vga == 1'b0) begin
    //if ( kick_tuser_cdc_pulse_w ) begin
	//end

	/*
	bs_tuser_r <= bs_tuser_w;
	if ( bs_tuser_r & ~bs_tuser_w ) begin
		if ( bs_tuser_counter == 2'b01 ) begin
			ila_capture_r <= #1 1'b1;
		end
		bs_tuser_counter <= bs_tuser_counter + 1;
	end
	*/

	/*
	bs_tready_r <= bs_tready_w;
	if ( bs_tready_r & ~bs_tready_w ) begin
		if ( bs_tready_counter == 2'b01 ) begin
			ila_capture_r <= #1 1'b1;
		end
		bs_tready_counter <= bs_tready_counter + 1;
	end
	if ( ~ila_capture_r ) begin
		ila_capture_counter <= ila_capture_counter + 32'd1;
	end
	*/

	/*
		if ( ila_capture_counter == 32'd6450 ) begin
			ila_capture_r <= #1 1'b1;
		end
		ila_capture_counter <= ila_capture_counter + 32'd1;

		//ila_capture_r <= #1 1'b1;
	*/

		bs_tlast_r <= bs_tlast_w;
		if ( ~bs_tlast_r & bs_tlast_w ) begin
			ila_capture_r <= #1 1'b1;
		end
		if ( ila_capture_r == 1'b0 ) begin
			ila_capture_counter <= ila_capture_counter + 32'd1;
		end
	end
end

// -- OreOre ILA --------------------------------
reg use_tp_vga = 1'b1;
wire pila_reset_w;
wire ila_capture_w;
wire [15:0] ila_cap_data_w;

assign pila_reset_w = 1'b0; // ToDo
assign ila_capture_w = use_tp_vga?do_capture_w:ila_capture_r;

/*
assign ila_cap_data_w = {
    kick_tuser_cdc_pulse_w, empty_w, almost_empty_w, axis_wr_en_w,
	tpg_tvalid, tpg_tuser, tpg_tlast,
	wnum_w[4:0],
	tpg_tdata_w[3:0]
};
*/

assign ila_cap_data_w = use_tp_vga?capture_data_w:
	{
		4'd0,
		almost_empty_w,
		empty_w,
		bs_status_w,
		bs_tdata_w[3:0],
		bs_tready_w, bs_tvalid_w, bs_tuser_w, bs_tlast_w
	};


pila 
#(
	.ADDR_WIDTH(ILA_ADDR_WIDTH)
) pila0 (
    .cap_clk(clk_pixel),
    .rst(pila_reset_w),

	.capture_i(ila_capture_w),
	.data_i(ila_cap_data_w),

    .peek_clk(clk_d_w),
    .addr_i(ila_mem_addr_w),
    .data_o(ila_mem_data_w),

    .write_addr_o(ila_wr_addr_w)
);

//----------------------------------------------------------------
wire bs_in_axis_tvalid_w;
wire bs_in_axis_tready_w;
wire bs_in_axis_tuser_w;
wire bs_in_axis_tlast_w;
wire [WIDTH-1:0] bs_in_axis_tdata_w;

tpg #(
	.WIDTH(WIDTH)
) linebuf_2_tpg_2_bufstream (
	.axis_clk(clk_pixel),
	.rst(1'b0),

	.out_axis_tvalid(bs_in_axis_tvalid_w),
	.out_axis_tready(bs_in_axis_tready_w),
	.out_axis_tuser(bs_in_axis_tuser_w),
	.out_axis_tlast(bs_in_axis_tlast_w),
	.out_axis_tdata(bs_in_axis_tdata_w),

    .use_in_axis(from_psram_r),

	/*
	.in_axis1_tvalid(tcard_tvalid_w),
	.in_axis1_tready(tcard_tready_w),
	.in_axis1_tdata(tcard_tdata_w),
    .in_axis1_tlast(1'b0),
	.in_axis1_tuser(tcard_tuser_w),
	*/

	.in_axis2_tvalid(lbuf_axis_tvalid_w),
	.in_axis2_tready(lbuf_axis_tready_w),
	.in_axis2_tdata(lbuf_axis_tdata_w),
    .in_axis2_tlast(lbuf_axis_tlast_w),
	.in_axis2_tuser(lbuf_axis_tuser_w),

    .tp_clk(clk_pixel),
	.tp_axis_tvalid(bs_tvalid_w),
	.tp_axis_tready(bs_tready_w),
	.tp_axis_tuser(bs_tuser_w),
	.tp_axis_tlast(bs_tlast_w),
	.tp_axis_tdata(bs_tdata_w),

    .tp_tuser_count_o(tp_lbuf_tuser_count_w),
    .tp_fps_o(tp_lbuf_fps_w)
);
//----------------------------------------------------------------

wire bs_tvalid_w;
wire bs_tready_w;
wire [23:0] bs_tdata_w;
wire [0:0] bs_tuser_w;
wire bs_tlast_w;

wire [1:0] bs_status_w;
wire [9:0] bs_debug_count_w;

bufstream #(.WIDTH(24))
bufstream0
(
    .clk(clk_pixel),
    .rst(reset),

    .in_axis_tvalid(bs_in_axis_tvalid_w),
    .in_axis_tready(bs_in_axis_tready_w),
    .in_axis_tuser(bs_in_axis_tuser_w),
    .in_axis_tlast(bs_in_axis_tlast_w),
    .in_axis_tdata(bs_in_axis_tdata_w),

    .out_axis_tvalid(bs_tvalid_w),
	.out_axis_tready(bs_tready_w),
    .out_axis_tuser(bs_tuser_w),
    .out_axis_tlast(bs_tlast_w),
    .out_axis_tdata(bs_tdata_w),

    .debug_count_o(bs_debug_count_w),
	.status_o(bs_status_w)
);

//----------------------------------------------------------------
wire [23:0] bs_tuser_count_w;
wire [7:0] bs_fps_w;
wire do_capture_w;
wire [15:0] capture_data_w;

tp_vga tp_vga0
(
    .clk(clk_pixel),
    .rst(1'b0),

	.tp_axis_tvalid(bs_tvalid_w),
	.tp_axis_tready(bs_tready_w),
	.tp_axis_tuser(bs_tuser_w),
	.tp_axis_tlast(bs_tlast_w),
	.tp_axis_tdata(bs_tlast_w),

	.do_capture_o(do_capture_w),
	.capture_data_o(capture_data_w),

    .tp_tuser_count_o(bs_tuser_count_w),
    .tp_fps_o(bs_fps_w)
);
//----------------------------------------------------------------
wire not_used_w;
wire [23:0] tp_tuser_count_w;
wire [7:0] tp_fps_w;
wire [23:0] tp_lbuf_tuser_count_w;
wire [7:0] tp_lbuf_fps_w;

tpg #(
	.WIDTH(WIDTH)
) bufstream_2_tpg_2_svo_hdmi (
	.axis_clk(clk_pixel),
	.rst(1'b0),

	.out_axis_tvalid(vdma_tvalid_w),
	.out_axis_tready(vdma_tready_w),
	.out_axis_tuser(vdma_tuser_w),
	.out_axis_tlast(not_used_w),
	.out_axis_tdata(vdma_tdata_w),

    .use_in_axis(2'b10),

	.in_axis1_tvalid(tcard_tvalid_w),
	.in_axis1_tready(tcard_tready_w),
	.in_axis1_tdata(tcard_tdata_w),
    .in_axis1_tlast(1'b0),
	.in_axis1_tuser(tcard_tuser_w),

	.in_axis2_tvalid(bs_tvalid_w),
	.in_axis2_tready(bs_tready_w),
	.in_axis2_tdata(bs_tdata_w),
    .in_axis2_tlast(bs_tlast_w),
	.in_axis2_tuser(bs_tuser_w),

    .tp_clk(clk_pixel),
    .tp_axis_tvalid(vdma_tvalid_w),
    .tp_axis_tready(vdma_tready_w),
    .tp_axis_tuser(vdma_tuser_w),
    .tp_axis_tlast(1'b0),
    .tp_axis_tdata(vdma_tdata_w),

    .tp_tuser_count_o(tp_tuser_count_w),
    .tp_fps_o(tp_fps_w)
);

//----------------------------------------------------------------
reg [31:0] out_frame = 32'd0;
reg [31:0] out_frame_counter = 32'd0;

assign out_frame_w = out_frame;

reg vdma_tuser_d;
always @(posedge clk_pixel) begin
	vdma_tuser_d <= vdma_tuser_w;
	if ( vdma_tuser_d & ~vdma_tuser_w ) begin
		out_frame = out_frame_counter;
		out_frame_counter = 32'd0;
	end else begin
		out_frame_counter <= out_frame_counter + 32'd1;
	end
end

//----------------------------------------------------------------
wire [29:0] video_cap_counter_w;
assign video_cap_counter_w = { video_cap_vcounter_r, video_cap_hcounter_r };

wire video_cap_req_w;
assign video_cap_req_w = video_cap_req_r;

reg [14:0] video_ref_vcounter = 15'd0;
reg [14:0] video_ref_hcounter = 15'd0;
wire [29:0] video_ref_counter;
assign video_ref_counter = { video_ref_vcounter, video_ref_hcounter };

reg video_cap_done_r = 1'b0;
reg [23:0] video_cap_data_r;
assign video_cap_done_w = video_cap_done_r;
assign video_cap_data_w = video_cap_data_r;

always @(posedge clk_pixel) begin
    if ( video_tvalid_ref_w ) begin
        if ( video_tuser_ref_w ) begin
            video_ref_hcounter <= 15'd1;
            video_ref_vcounter <= 15'd0;
        end else begin
			if (video_ref_hcounter == 15'd639 ) begin
				video_ref_hcounter <= 15'd0;
				video_ref_vcounter <= video_ref_vcounter + 15'd1;
			end else begin
				video_ref_hcounter <= video_ref_hcounter + 15'd1;
			end
        end

        if ( video_cap_req_w ) begin
            if ((video_ref_counter == video_cap_counter_w) |
                ((video_cap_counter_w == 30'd0) & video_tuser_ref_w)) begin

                video_cap_data_r <= video_tdata_ref_w;
                video_cap_done_r <= 1'b1;
            end
        end else begin
            video_cap_done_r <= 1'b0;    
        end
    end
end

assign io_addr_01_w = {
	1'b0,
    wnum_w,
    rnum_w,

	1'b0,
	full_w,
	bs_status_w,

    almost_full_w,
	tpg_status,

	bs_in_axis_tvalid_w,
	bs_in_axis_tready_w,
	vdma_tvalid_w,
	vdma_tready_w
};

reg fps_sw_r = 1'b1;

assign io_addr_45_w = {
	fps_sw_r?bs_fps_w:tp_fps_w,
	fps_sw_r?bs_tuser_count_w:tp_tuser_count_w
};

endmodule
`default_nettype wire
