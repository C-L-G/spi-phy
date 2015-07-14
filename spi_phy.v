/*******************************************************
______________                ______________
______________ \  /\  /|\  /| ______________
______________  \/  \/ | \/ | ______________

--Module Name:
--Project Name:
--Chinese Description:
	
--English Description:
	
--Version:VERA.1.0.0
--Data modified:2015/7/14 17:53:05
--author:Young-ÎâÃ÷
--E-mail: wmy367@Gmail.com
--Data created:
________________________________________________________
********************************************************/
`timescale 1ns/1ps
module spi_phy #(
	parameter	PHASE	= 0,
	parameter	ACTIVE	= 0
)(
	//-->> SPI INTERFACE <<---               
    input			sck						,
    input			cs_n        			,
    output			miso        			,
	input			mosi					,
	//-->> system <<---------
	input			clock					,
	input			rst_n					,
	//-->> RX INTERFACE <<---
	output			rx_stream_sof			,
	output[7:0]		rx_stream_data			,
	output			rx_stream_vld			,
	output			rx_stream_eof			,
	//-->> TX INTERFACE <<---
	output			tx_send_flag			,
	input [23:0]	tx_send_momment			,
	input [7:0]		tx_send_data			,
	input			tx_send_valid			,
	output			tx_empty			
);


wire		sck_sync;
wire		cs_n_sync;
wire		mosi_sync;

cross_clk_sync #(
	.LAT			(2		),
	.DSIZE			(3      )
)latency_inst(
	.clk			(clock					),
	.rst_n          (rst_n                  ),
	.d              ({sck,cs_n,mosi}        ),
	.q              ({sck_sync,cs_n_sync,mosi_sync})
);

    
wire	start    	;   
wire	finish      ;
wire	rx_data     ;
wire	rx_valid    ;
	
rx_bit1_phy #(
	.PHASE			(PHASE		),	
	.ACTIVE			(ACTIVE	    )
)rx_bit1_phy_inst(
	//-->> SPI INTERFACE <<---
/*	input		*/	.sck			(sck_sync		),		
/*	input		*/	.cs_n           (cs_n_sync      ),
/*	input		*/	.mosi           (mosi_sync      ),
	//--<< SPI INTERFACE >>---
/*	input		*/	.clock			(clock			),	   		
/*	input		*/	.rst_n          (rst_n          ),
/*	output		*/	.start          (start          ),
/*	output		*/	.finish         (finish         ),
/*	output		*/	.rx_data        (rx_data        ),
/*	output		*/	.rx_valid       (rx_valid	    )
);


rx_8bit_from_phy rx_8bit_from_phy_inst(
/*	input		*/	.clock			(clock			),		   		
/*	input		*/	.rst_n          (rst_n          ),
/*	input		*/	.start          (start          ),
/*	input		*/	.finish         (finish         ),
/*	input		*/	.rx_data        (rx_data        ),
/*	input		*/	.rx_valid		(rx_valid	    ),
/*              */
/*	output		*/	.stream_sof		(rx_stream_sof	),	
/*	output[7:0]	*/	.stream_data	(rx_stream_data ),	
/*	output		*/	.stream_vld		(rx_stream_vld	),
/*	output		*/	.stream_eof     (rx_stream_eof  )
);
   			           	
//wire		tx_data  			;       	
//wire		tx_valid        	;
//wire		can_ref_new_data	;
//wire[23:0]	trigger_cnt		    ;
//wire		idle            	;

//tx_bit1_phy #(
//	.PHASE			(PHASE			),	 
//	.ACTIVE			(ACTIVE	        )
//)tx_bit1_phy_inst(
//	//-->> SPI INTERFACE <<---
///*	input		*/	.sck				(sck				),						
///*	input		*/	.cs_n        		(cs_n		        ),
///*	output		*///	.miso        		(miso		        ),
//	//--<< SPI INTERFACE >>---
///*	input		*/	.clock     			(clock   			),  						
///*	input		*/	.rst_n           	(rst_n           	),        
///*	input		*/	.tx_data         	(tx_data         	),        
///*	input		*/	.tx_valid        	(tx_valid        	),        
///*	output		*/	.can_ref_new_data	(can_ref_new_data	),		
///*	output[23:0]*/	.trigger_cnt		(trigger_cnt		),		
///*	output		*/	.idle            	(idle            	)
//);
//
//tx_8bit_to_phy tx_8bit_to_phy_inst(
///*	input		*/	.clock     			(clock 				),    					
///*	input		*/	.rst_n              (rst_n              ),
///*	output		*/	.tx_data            (tx_data            ),
///*	output		*/	.tx_valid           (tx_valid           ),
///*	input		*/	.can_ref_new_data	(can_ref_new_data	),
///*	input [23:0]*/	.trigger_cnt		(trigger_cnt		),
///*	input		*/	.idle				(idle				),
//	//---->>  <<-----
///*	output		*/	//.send_flag			(tx_send_flag		),		
///*	input [23:0]*/	.send_momment		(tx_send_momment	),
///*	input [7:0]	*/	.send_data			(tx_send_data		),
///*	input		*/	.send_valid			(tx_send_valid		)	
///*	output		*/	//.empty			    (tx_empty			)
//);

tx_8bit_phy #(
	.PHASE			(PHASE			),	
	.ACTIVE			(ACTIVE	        )   
)tx_8bit_phy(
	//-->> SPI INTERFACE <<---
/*	input		*/	.sck				(sck				),		
/*	input		*/	.cs_n        		(cs_n		        ),      
/*	output		*/	.miso        		(miso		        ),      
	//--<< SPI INTERFACE >>---
/*	input		*/	.clock     			(clock   			), 
/*	input		*/	.rst_n           	(rst_n           	), 
/*	output		*/	.send_flag			(tx_send_flag		),
/*	input [23:0]*/	.send_momment		(tx_send_momment	),
/*	input [7:0]	*/	.send_data			(tx_send_data		),
/*	input		*/	.send_valid			(tx_send_valid		),
/*	output		*/	.empty			    (tx_empty			) 
);


endmodule



