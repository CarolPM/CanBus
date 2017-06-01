`timescale 1ns/10ps
 
`include "can_tx.v"
`include "can_rx.v"
`include "can_destuff.v"
 
module can_tb ();
 
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
  parameter s_DESTUFF  		   = 0;
  parameter s_RX		   		= 1;
  
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  reg r_Rx_Serial = 1;
  reg r_Ds_Serial = 1;
  wire [0:107] w_Rx_Byte; //start+identifier+RTR+IDE+RESERVED0+data
  wire [0:2] w_cont_0;
  wire [0:2] w_cont_1;
  wire [0:1] w_flag_destuff;
  reg [0:1] flag_destuff = 2'b0;
  reg [0:2] cont_0 = 3'b0;
  reg [0:2] cont_1 = 3'b0;

  reg [0:31] Clock_Count = 0;
  reg [0:31] loop = 0;
 
  // Takes in input byte and serializes it 
  task CAN_WRITE_BYTE;
	 input [0:107] i_Data; //
    reg [0:7]     ii;

    begin
       
      // Send All Data
		for (ii=0; ii<108; ii=ii+1)
			begin
				cont_0 = w_cont_0;
				cont_1 = w_cont_1;
				r_Ds_Serial <= i_Data[ii];
				//#(c_BIT_PERIOD-1);
				
				if (w_flag_destuff == 2'b1)
					ii = ii + 1;
				r_Rx_Serial <= i_Data[ii];

				#(c_BIT_PERIOD-100);

			end
     end
  endtask // CAN_WRITE_BYTE
   

	can_destuff #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_DESTUFF_INST
	(
		.i_Clock(r_Clock),
		.i_Ds_Serial(r_Ds_Serial),
		.i_cont_0(cont_0),
		.i_cont_1(cont_1),
		.o_flag_destuff(w_flag_destuff),
		.o_cont_0(w_cont_0),
		.o_cont_1(w_cont_1)
	);
	
	can_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_RX_INST
	(
		.i_Clock(r_Clock),
		.i_Rx_Serial(r_Rx_Serial),
		.o_Rx_DV(),
		.o_Rx_Byte(w_Rx_Byte)
    );

   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
   
  // Main Testing:
  initial
    begin

      // Send a command to the CAN (exercise Rx)
      @(posedge r_Clock);

		//data frame normal
		CAN_WRITE_BYTE(108'b011111011111010000010100000100010101010101010011111111110000111110110000010100000100010101010101010011000001); //data frame standard
      @(posedge r_Clock);
      
		$display("Frame: %b", w_Rx_Byte);
       
    end
   
endmodule