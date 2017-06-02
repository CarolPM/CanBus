//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
 
// This testbench will exercise both the UART Tx and Rx.
// It sends out byte 0xAB over the transmitter
// It then exercises the receive by receiving byte 0x3F


`timescale 1ns/10ps
`include "can_tx.v"
`include "can_rx.v"
 
module can_tb ();
 

  parameter c_CLOCK_PERIOD_NS = 100;   
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
  reg r_Clock = 0;
  reg r_Rx_Serial = 1;
  wire [0:107] w_Rx_Byte; 
   
 
  task CAN_WRITE_BYTE;
	 input [0:107] i_Data;
    integer     ii;
    begin
		for (ii=0; ii<108; ii=ii+1)
			begin
				r_Rx_Serial <= i_Data[ii];
				#(c_BIT_PERIOD);
			end
     end
  endtask
   
   
  can_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_RX_INST
    (.i_Clock(r_Clock),
     .i_Rx_Serial(r_Rx_Serial),
     .o_Rx_DV(),
     .o_Rx_Byte(w_Rx_Byte)
     );

   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
   

  initial
    begin
      @(posedge r_Clock);
		  CAN_WRITE_BYTE(108'b010101010101001000110101010101010101010101101111111111101010101010010001101010101010101010101010100000000111); //data frame standard
    end
   
endmodule