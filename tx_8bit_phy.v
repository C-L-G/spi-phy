/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:2015/7/14 17:54:00
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module tx_8bit_phy #(
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
reg		stay_clock;
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

always@(*)
	case({ACTIVE==1,PHASE==1})
	2'b00:	stay_clock	= sck;
	2'b01:	stay_clock	= !sck;
	2'b10:	stay_clock	= !sck;
	2'b11:	stay_clock	=  sck;
	default:;
	endcase

//---->> YIELD BLOCK <<-----------
reg	[23:0]	counter;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	counter	<= 24'd1;
	else				counter	<= counter + 1'b1;

reg						tx_yield;

always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	
				tx_yield	<= 1'b0;
	else if(send_momment	< 24'd8)
				tx_yield	<= 1'b1;
	else 		tx_yield	<= counter >= send_momment;

//----<< YIELD BLOCK >>-----------  
//---->> TX DATA PRO <<-----------
reg [2:0]	point;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	point	<= 3'd0;
	else 				point	<= point + tx_yield;

wire[7:0]	pre_data;
reg [7:0]	data_reg;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	data_reg	<= pre_data; 
	else if(!tx_yield)	data_reg	<= pre_data;
	else begin
		if(point == 3'b111)
				data_reg	<= pre_data;
		else	data_reg	<= data_reg;
	end

reg tx_reg;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	tx_reg	<= 1'b0; 
	else begin
		case(point)
		3'b000:	tx_reg	= data_reg[7];
		3'b001:	tx_reg	= data_reg[6];
		3'b010:	tx_reg	= data_reg[5];
		3'b011:	tx_reg	= data_reg[4];
		3'b100:	tx_reg	= data_reg[3];
		3'b101:	tx_reg	= data_reg[2];
		3'b110:	tx_reg	= data_reg[1];
		3'b111:	tx_reg	= data_reg[0];
		default:;
		endcase
	end

//----<< TX DATA PRO >>-----------
reg				reload;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	reload	<= 1'b0; 
	else begin
		if(point == 3'b111)
				reload	<= 1'b1;
		else	reload	<= 1'b0;
	end

reg				reloadQ;
always@(posedge trigger_clock,negedge trigger_rst_n)
	if(~trigger_rst_n)	reloadQ	<= 1'b0; 
	else 				reloadQ	<= reload;

wire			reloadQ_raising;

edge_generator #(
	.MODE		("BEST")   // FAST NORMAL BEST
)reloadQ_edge(
	.clk		(clock				),
	.rst_n      (rst_n          	),
	.in         (reloadQ        	),
	.raising    (reloadQ_raising    ),
	.falling    (               	)
);

cross_clk_sync #(
	.LAT			(2		),
	.DSIZE			(1      )
)latency_inst(
	.clk			(clock					),
	.rst_n          (rst_n                  ),
	.d              (!cs_n        			),
	.q              (send_flag				)
);

wire	cs_raising;

edge_generator #(
	.MODE		("BEST")   // FAST NORMAL BEST
)cs_edge(
	.clk		(clock				),
	.rst_n      (rst_n          	),
	.in         (!send_flag	       	),
	.raising    (cs_raising		    ),
	.falling    (               	)
);

wire		tx_yield_raising;
edge_generator #(
	.MODE		("BEST")   // FAST NORMAL BEST
)tx_yield_edge(
	.clk		(clock				),
	.rst_n      (rst_n          	),
	.in         (tx_yield	       	),
	.raising    (tx_yield_raising   ),
	.falling    (               	)
);

reg				low_empty;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	low_empty	<= 1'b1;
	else begin
		if(reloadQ_raising)
				low_empty	<= 1'b1;
		else if(cs_raising)
				low_empty	<= 1'b1;
		else if(tx_yield_raising)
				low_empty	<= 1'b1;
		else if(!tx_yield)
			if(low_empty)
					low_empty	<= !send_valid;
			else	low_empty	<= 1'b0;
		else		low_empty	<= 1'b0;
	end	

wire			pre_vld;
wire			pre_empty;
wire			pre_reload;

pipe_reg #(
	.DSIZE				(8)
)pre_data_inst(
/*	input				*/	.clock			(clock			),	
/*	input				*/	.rst_n      	(rst_n          ),
/*	input				*/	.wr_en      	(send_valid     ),
/*	input [DSIZE-1:0]	*/	.indata     	(send_data      ),
/*	input				*/	.low_empty  	(low_empty      ),
/*	output				*/	.valid      	(pre_vld        ),
/*	output				*/	.curr_empty 	(pre_empty      ),
/*	output				*/	.sum_empty  	(               ),
/*	output[DSIZE-1:0]	*/	.outdata    	(pre_data       ),
							.high_reload	(pre_reload		)
);


assign	empty	= pre_reload || pre_empty;
assign	miso	= tx_reg;

endmodule
