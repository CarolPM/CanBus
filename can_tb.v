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
 
  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
   
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  //reg [7:0] r_Tx_Byte = 0;
  reg r_Rx_Serial = 1;
  wire [0:107] w_Rx_Byte; //start+identifier+RTR+IDE+RESERVED0+data
   
 
  // Takes in input byte and serializes it 
  task CAN_WRITE_BYTE;
	 //input		  i_start; //
	 //input [10:0] i_identifier; //
	 //input		  i_RTR; //
	 //input		  i_IDE; //
	 //input		  i_RESERVED0; //
	 //input [3:0] i_length; //
	 input [0:107] i_Data; //
	 //input [14:0] i_CRC; //
	 //input		  i_CRC_DELIM; //
	 //input		  i_ACK; //
	 //input		  i_ACK_DELIM; //
	 //input		  i_STOP; //
    integer     ii;
	 //integer		  count_stuff_0 = 0;
	 //integer		  count_stuff_1 = 0;
    begin
       
      // Send All Data
		for (ii=0; ii<108; ii=ii+1)
			begin
				r_Rx_Serial <= i_Data[ii];
				#(c_BIT_PERIOD);
			end
     end
  endtask // CAN_WRITE_BYTE
   
   
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
		CAN_WRITE_BYTE(108'b011111111111010001111000011111001001111110011111110111111111111000001111000011110000110000001111111111111111); //data frame standard
      @(posedge r_Clock);
      if (w_Rx_Byte == 108'b101111111111100000101111111101010101010101111100000001011111111111000001011111111010101010101011111000000011)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
   
endmodule