/****************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________
--Module Name:  spi_phy_tb.sv
--Project Name: GitHub
--Data modified: 2015-09-21 10:49:59 +0800
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
****************************************/
`timescale 1ns/1ps
module spi_phy_tb;

//--->> SYSYTEM VAR <<--------
localparam	Freq	= 100;
parameter	PHASE	= 1;	
parameter	ACTIVE	= 0;

wire		clock;
wire		rst_n;

clock_rst clk_c0(
	.clock		(clock),
	.rst		(rst_n)
);

defparam clk_c0.ACTIVE = 0;
initial begin:INITIAL_CLOCK
	clk_c0.run(10 , 1000/Freq ,0);		//	
end
//---<< SYSTEM VAR >>-----------
//--->> MODEL  <<---------------
wire		cs_n		;
wire		mosi		;
wire		miso		;
wire		sck 		;

spi_model #(
	.PHASE			(PHASE		),
	.ACTIVE			(ACTIVE		),
	.Freq			(50	)
)spi_model_inst(
	.cs_n		(cs_n	),
	.mosi		(mosi	),
	.miso		(miso	),
	.sck 		(sck 	)
);  

//---<< MODEL >>---------------- 

logic		rx_stream_sof	;	
logic[7:0]	rx_stream_data	;
logic		rx_stream_vld	;
logic		rx_stream_eof	;
logic		tx_send_flag	;
logic[23:0]	tx_send_momment ;
logic[7:0]	tx_send_data	;
logic		tx_send_valid	= 0;
logic		tx_empty		;

spi_phy #(
	.PHASE			(PHASE					),
	.ACTIVE			(ACTIVE					)
)spi_phy_inst(
	//-->> SPI INTERFACE <<---               
/*    input		*/	.sck			(sck				),						
/*    input		*/	.cs_n   		(cs_n        		),	
/*    output	*/	.miso   		(miso        		),	
/*	input		*/	.mosi			(mosi				),	
	//-->> system <<---------
/*	input		*/	.clock			(clock				),			
/*	input		*/	.rst_n			(rst_n				),	
	//-->> RX INTERFACE <<---
/*	output		*/	.rx_stream_sof	(rx_stream_sof		),			
/*	output[7:0]	*/	.rx_stream_data	(rx_stream_data		),	
/*	output		*/	.rx_stream_vld	(rx_stream_vld		),	
/*	output		*/	.rx_stream_eof	(rx_stream_eof		),	
	//-->> TX INTERFACE <<---
/*	output		*/	.tx_send_flag	(tx_send_flag		),		
/*	input [23:0]*/	.tx_send_momment(tx_send_momment	),		
/*	input [7:0]	*/	.tx_send_data	(tx_send_data		),	
/*	input		*/	.tx_send_valid	(tx_send_valid		),	
/*	output		*/	.tx_empty		(tx_empty			)
);

logic[7:0]	write_data [$] = {8'hF1,8'h01,8'h02,8'h03,8'h04,8'h01,8'h02,8'h03,8'h04};
logic[7:0]	rx_data_seq[$];

task spi_mosi_task(input logic [7:0]	D [$] = {});
fork
	spi_model_inst.write(D);
	get_rx_stream;
join
endtask: spi_mosi_task

task spi_miso_task; 
fork
	spi_model_inst.read(8);
	tx_data_task(8);
join
endtask: spi_miso_task

task tx_data_task(int cnt = 8);
	@(posedge tx_send_flag);
	tx_send_momment	= 0;
	tx_send_valid	= 0;
	tx_send_data	= 0;
	wait(tx_send_flag);
	repeat(cnt)begin
		if(!tx_send_flag)	break;
		wait(tx_empty);
		@(posedge clock);
		tx_send_valid	= 1;
		tx_send_data	+=1;
		@(posedge clock);
		tx_send_valid	= 0;
		wait(!tx_empty);
	end
endtask: tx_data_task

initial begin
	repeat(10) @(posedge clock);
	spi_mosi_task(write_data);
	spi_miso_task;
end

task get_rx_stream;
	wait(rx_stream_sof);
	rx_data_seq	= {};
	while(!rx_stream_eof && !cs_n)begin
		@(posedge clock);
		if(rx_stream_vld)
				rx_data_seq.push_back(rx_stream_data);
		else	rx_data_seq = rx_data_seq;
	end
endtask: get_rx_stream

endmodule
	


