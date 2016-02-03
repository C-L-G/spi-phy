/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  rx_bit1_phy.v
--Project Name: spi-phy
--Data modified: 2016-02-03 15:44:39 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module rx_bit1_phy #(
	parameter		PHASE	= 0,
	parameter		ACTIVE	= 0
)(
	//-->> SPI INTERFACE <<---
	input			sck				,
	input			cs_n            ,
	input			mosi            ,
	//--<< SPI INTERFACE >>---
	input			clock   		,
	input			rst_n           ,
	output			start           ,
	output			finish          ,
	output			rx_data         ,
	output			rx_valid
);

wire		cs_raising,cs_falling;

edge_generator #(
	.MODE	("NORMAL")   // FAST NORMAL BEST
)cs_edge_generator(
	.clk		(clock      ),
	.rst_n		(rst_n      ),
	.in			(cs_n       ),
	.raising	(cs_raising ),
	.falling	(cs_falling	)
);

reg		trigger_momment;
reg		send_momment;

wire		sck_raising,sck_falling;

edge_generator #(
	.MODE	("FAST")   // FAST NORMAL BEST
)sck_edge_generator(
	.clk		(clock      ),
	.rst_n		(rst_n      ),
	.in			(sck        ),
	.raising	(sck_raising),
	.falling	(sck_falling)
);

always@(posedge clock,negedge rst_n)begin
	if(~rst_n)begin
		trigger_momment	<= 1'b0;
		send_momment	<= 1'b0;
	end else begin
		case({ACTIVE==1,PHASE==1})
		2'b00:begin
			trigger_momment <= sck_raising;
			send_momment	<= sck_falling;
		end 
		2'b01:begin
			trigger_momment <= sck_falling;
            send_momment	<= sck_raising;
		end 
		2'b10:begin
			trigger_momment <= sck_falling;
            send_momment	<= sck_raising;
		end
		2'b11:begin
			trigger_momment <= sck_raising;
			send_momment	<= sck_falling;
		end
		default:begin
			trigger_momment	<= 1'b0;
			send_momment	<= 1'b0;
		end
		endcase
end end

//----->> DI latency control <<------
wire		mosi_lat;
cross_clk_sync #(
	.LAT	(1),
	.DSIZE	(1)
)latency_DI(
	.clk	(clock			),
	.rst_n	(rst_n          ),
	.d		(mosi           ),
	.q		(mosi_lat       )
);
//-----<< DI latency control >>------

//------>> RX STATE <<-----------
reg [3:0]			cstate,nstate;
localparam			IDLE		= 4'd0,
					RX_BEGIN    = 4'd1,
					RX_WAIT     = 4'd2,
					RX_TRI      = 4'd3,
					RX_END      = 4'd4;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	cstate	= IDLE;
	else 		cstate	= nstate;

always@(*)
	case(cstate)
	IDLE:	if(cs_falling)	nstate	= RX_BEGIN;
			else			nstate	= IDLE;
	RX_BEGIN:				nstate	= RX_WAIT;
	RX_WAIT:if(cs_raising)	nstate	= RX_END;
			else if(trigger_momment)
							nstate	= RX_TRI;
			else			nstate	= RX_WAIT;
	RX_TRI:	if(trigger_momment)
							nstate	= RX_TRI;
			else			nstate	= RX_WAIT;
	RX_END:					nstate	= IDLE;
	default:				nstate	= IDLE;
	endcase

reg			start_flag;
reg			end_flag;
reg			data_reg;
reg			data_valid;

always@(posedge clock,negedge rst_n)
	if(~rst_n)		start_flag	<= 1'b0;
	else 
		case(nstate)
		RX_BEGIN:	start_flag	<= 1'b1;
		default:	start_flag	<= 1'b0;
		endcase

always@(posedge clock,negedge rst_n)
	if(~rst_n)		end_flag	<= 1'b0;
	else 
		case(nstate)
		RX_END:		end_flag	<= 1'b1;
		default:	end_flag	<= 1'b0;
		endcase

always@(posedge clock,negedge rst_n)
	if(~rst_n)		data_reg	<= 1'b0;
	else
		case(nstate)
		RX_TRI:		data_reg	<= mosi_lat;
		default:	data_reg	<= 1'b0;
		endcase

always@(posedge clock,negedge rst_n)
	if(~rst_n)		data_valid	<= 1'b0;
	else 
		case(nstate)
		RX_TRI:		data_valid	<= 1'b1;
		default:	data_valid	<= 1'b0;
		endcase
//------<< RX STATE >>-----
assign	start	= start_flag;
assign	finish	= end_flag;
assign	rx_data	= data_reg;
assign	rx_valid= data_valid;

endmodule

