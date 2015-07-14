/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:2015/7/14 17:54:15
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module tx_8bit_to_phy (
	input			clock     				,
	input			rst_n                   ,
	output			tx_data                 ,
	output			tx_valid                ,
	input			can_ref_new_data		,
	input [23:0]	trigger_cnt				,
	input			idle					,
	//---->>  <<-----
	output			send_flag				,
	input [23:0]	send_momment			,
	input [7:0]		send_data				,
	input			send_valid				,
	output			empty			

);

/*
    ___________________
___/                   \____  send_flag
        _________           
_______/         \__________  empty
             ____  
____________/    \_____  send_valid
             ____
____________/XXXX\_____  send data 
*/

wire					reload;
reg						tx_yield;

always@(posedge clock,negedge rst_n)
	if(~rst_n)	tx_yield	<= 1'b0;
	else if(send_momment	< 24'd8)
				tx_yield	<= 1'b1;
	else 		tx_yield	<= trigger_cnt > send_momment;


//reg [7:0]		pre_data;
//always@(posedge clock,negedge rst_n)
//	if(~rst_n)	pre_data	<= 8'd0;
//	else if(idle)
//				pre_data	<= 8'd0;
//	else 		pre_data	<= send_valid? send_data : pre_data;
//
//reg				pre_vld;
//always@(posedge clock,negedge rst_n)
//	if(~rst_n)	pre_vld		<= 1'b0;
//	else begin
//		if(send_valid)	pre_vld	<= reload;
//		else if(reload)	pre_vld	<= 1'b0;
//		else			pre_vld	<= pre_vld;
//	end  

wire[7:0]		pre_data;
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
/*	input				*/	.low_empty  	(reload         ),
/*	output				*/	.valid      	(pre_vld        ),
/*	output				*/	.curr_empty 	(pre_empty      ),
/*	output				*/	.sum_empty  	(               ),
/*	output[DSIZE-1:0]	*/	.outdata    	(pre_data       ),
							.high_reload	(pre_reload		)
);

assign	empty	= pre_empty || pre_reload;

reg [7:0]		data_shift;
always@(posedge clock,negedge rst_n)begin
	if(~rst_n)	data_shift	<= 8'd0;
	else begin
		if(reload)	data_shift	<= pre_data;
		else if(tx_yield)begin
			if(can_ref_new_data)
					data_shift	<= data_shift << 1;
			else	data_shift	<= data_shift;
		end else 	data_shift	<= data_shift;
end end

reg [7:0]		shift_vld;

always@(posedge clock,negedge rst_n)
	if(~rst_n)		shift_vld	<= 8'b0000_0000;
	else begin
		if(idle)	shift_vld	<= 8'b0000_0000;
		else begin
			if(reload)	shift_vld	<= pre_vld? 8'b1111_1111 : 8'b0000_0000;
			else if(tx_yield)begin
				if(can_ref_new_data)
						shift_vld	<= {shift_vld[6:0],1'b0};
				else	shift_vld	<= shift_vld;
			end else	shift_vld	<= shift_vld;
end end 


reg			tx_reg;
reg			tx_reg_vld;

always@(data_shift[7])
		tx_reg		= data_shift[7];

always@(can_ref_new_data,shift_vld[7])
	if(can_ref_new_data)
			tx_reg_vld	= shift_vld[7];
	else	tx_reg_vld	= 1'b0;





assign	reload	= (shift_vld == 8'b0000_0000) || (can_ref_new_data && shift_vld == 8'b1000_0000);
//assign	empty	= !pre_vld;
assign	tx_data	= tx_reg && tx_yield;
assign	tx_valid= tx_reg_vld;

cross_clk_sync #(
	.LAT			(2		),
	.DSIZE			(1      )
)latency_inst(
	.clk			(clock					),
	.rst_n          (rst_n                  ),
	.d              (!idle        			),
	.q              (send_flag				)
);

endmodule


		
		
				





	