/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  tx_8bit_fifo_phy.v
--Project Name: spi-phy
--Data modified: 2016-02-03 15:44:39 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module tx_8bit_fifo_phy #(
	parameter	PHASE	= 0,
	parameter	ACTIVE	= 0
)(
	//-->> SPI INTERFACE <<---
	input			sck						,
	input			cs_n        			,
	output			miso        			,
	//--<< SPI INTERFACE >>---
	input			clock     				,
	input			rst_n                   ,  
	output			send_flag				,
	input [23:0]	send_momment			,
	input [7:0]		send_data				,
	input			send_valid				,
	output			empty			
);

reg		trigger_clock;
reg		trigger_rst_n;
always@(*)
	case({ACTIVE==1,PHASE==1})
	2'b00:	trigger_clock	= !cs_n && !sck;
	2'b01:	trigger_clock	= !cs_n && sck;
	2'b10:	trigger_clock	=  sck;
	2'b11:	trigger_clock	= !sck;
	default:;
	endcase

always@(cs_n)
	trigger_rst_n	= ~cs_n;

//------>> FIFO <<-------------------
wire	rd_en	;
wire	wr_almost_full	;
wire	wr_full			;
assign	empty	= !wr_full;

fifo_nto1 #(
	.DSIZE		(1		),
	.NSIZE		(8		),
	.DEPTH		(8     ),
	.ALMOST		(2      ),
	.DEF_VALUE	(1      )
)fifo_nto1_inst(
	//--->> WRITE PORT <<-----
/*	input				*/	.wr_clk			(clock				),	 			
/*	input				*/	.wr_rst_n       (rst_n				), 
/*	input				*/	.wr_en          (send_valid 		),
/*	input [DSIZE-1:0]	*/	.wr_data        (send_data  		),
/*	output[4:0]			*/	.wr_count       (           		),
/*	output				*/	.wr_full        (wr_full           	),
/*	output				*/	.wr_almost_full (wr_almost_full     ),
	//--->> READ PORT <<------                          
/*	input				*/	.rd_clk			(trigger_clock		),		
/*	input				*/	.rd_rst_n       (trigger_rst_n      ),
/*	input				*/	.rd_en          (rd_en				),
/*	output[DSIZE-1:0]	*/	.rd_data        (miso           	),
/*	output[4:0]			*/	.rd_count       (           		),
/*	output				*/	.rd_empty       (           		),
/*	output				*/	.rd_almost_empty(           		),
/*	output				*/	.rd_vld			(					)
);


//---->> YIELD BLOCK <<-----------
reg	[23:0]	counter;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	counter	<= 24'd0;
	else begin
		if(counter < send_momment)
				counter	<= counter + 1'b1;
		else	counter	<= counter;
	end

reg						tx_yield;

always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	tx_yield	<= 1'b0;
	else				tx_yield	<= counter >= (send_momment-1'b1);

assign	rd_en	= tx_yield;

//----<< YIELD BLOCK >>-----------  
cross_clk_sync #(
	.LAT			(2		),
	.DSIZE			(1      )
)latency_inst(
	.clk			(clock					),
	.rst_n          (rst_n                  ),
	.d              (!cs_n        			),
	.q              (send_flag				)
);


endmodule
