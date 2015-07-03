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
module rx_8bit_from_phy (
	input			clock   		,
	input			rst_n           ,
	input			start           ,
	input			finish          ,
	input			rx_data         ,
	input			rx_valid		,

	output			stream_sof		,
	output[7:0]		stream_data		,
	output			stream_vld		,
	output			stream_eof
);


reg	[7:0]			data_shift;
always@(posedge clock,negedge rst_n)
	if(~rst_n)		data_shift	<= 8'd0;
	else 			data_shift	<= rx_valid? {data_shift[6:0],rx_data} : data_shift;

reg [3:0]			shift_cnt;
always@(posedge clock,negedge rst_n)begin
	if(~rst_n)		shift_cnt	<= 4'd0;
	else if(start)	shift_cnt	<= 4'd0;
	else begin
		if(shift_cnt == 4'd7)begin
			if(rx_valid)	shift_cnt	<= 4'd0;
			else			shift_cnt	<= shift_cnt;
		end else begin
			if(rx_valid)	shift_cnt	<= shift_cnt + 1'b1;
			else			shift_cnt	<= shift_cnt;		
end end end

reg				one_byte_fsh;
always@(posedge clock,negedge rst_n)
	if(~rst_n)	one_byte_fsh	<= 1'b0;
	else		one_byte_fsh	<= (shift_cnt == 4'd7) && rx_valid;

reg [7:0]		data_reg;
always@(posedge clock,negedge rst_n)
	if(~rst_n)	data_reg	<= 8'd0;
	else if(one_byte_fsh)
				data_reg	<= data_shift;
	else		data_reg	<= data_reg;

reg				valid_reg;
always@(posedge clock,negedge rst_n)
	if(~rst_n)	valid_reg	<= 1'b0;
	else		valid_reg	<= one_byte_fsh;		

cross_clk_sync #(
	.LAT			(2		),
	.DSIZE			(2      )
)latency_inst(
	.clk			(clock					),
	.rst_n          (rst_n                  ),
	.d              ({start,finish}         ),
	.q              ({stream_sof,stream_eof})
);


assign	stream_data	= data_reg;
assign	stream_vld	= valid_reg;


endmodule


