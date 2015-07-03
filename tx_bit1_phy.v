/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module tx_bit1_phy #(
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
	input			tx_data                 ,
	input			tx_valid                ,
	output			can_ref_new_data		,
	output [23:0]	trigger_cnt				,
	output			idle
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

reg 	trigger_flag	= 1'b0;
reg		write_flag;

reg		wr_data;
reg		tri_data;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	wr_data	<= 1'b0;
	else		wr_data	<= tx_valid? tx_data : wr_data;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	write_flag	<= 1'b0;
	else if(!cs_n)
				write_flag	<= tx_valid? ~write_flag : write_flag;
	else		write_flag	<= ~trigger_flag;

always@(posedge trigger_clock)
	tri_data	<= wr_data;

always@(posedge trigger_clock)
	trigger_flag<= ~trigger_flag;

reg	[23:0]	counter;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	counter	<= 24'd0;
	else				counter	<= counter + 1'b1;

assign	can_ref_new_data	= trigger_flag != write_flag;
//assign	miso				= (PHASE	== 0)? tx_data : tri_data;
assign	trigger_cnt			= counter;
assign	idle				= cs_n;

reg		miso_reg;
always@(*)
	case({ACTIVE==1,PHASE==1})
	2'b00:	miso_reg	= tx_data;
	2'b10:	miso_reg	= wr_data;
	2'b01:	miso_reg	= tri_data;
	2'b11:	miso_reg	= tri_data;
	default:;
	endcase

assign	miso			= miso_reg;

endmodule