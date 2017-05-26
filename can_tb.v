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
 /*  
  can_tx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) UART_TX_INST
    (.i_Clock(r_Clock),
     .i_Tx_DV(r_Tx_DV),
     .i_Tx_Byte(r_Tx_Byte),
     .o_Tx_Active(),
     .o_Tx_Serial(),
     .o_Tx_Done(w_Tx_Done)
     );
 */
   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
   
  // Main Testing:
  initial
    begin
      /* 
      // Tell UART to send a command (exercise Tx)
      @(posedge r_Clock);
      @(posedge r_Clock);
      r_Tx_DV <= 1'b1;
      r_Tx_Byte <= 8'hAB;
      @(posedge r_Clock);
      r_Tx_DV <= 1'b0;
      @(posedge w_Tx_Done);
      */ 
      // Send a command to the CAN (exercise Rx)
      @(posedge r_Clock);
      //CAN_WRITE_BYTE(11'b00000010100, 4'b0001, 64'h1, 15'b0100001100000001);
		//data frame standard = start(1bit)+identifier(11bits)+RTR(1bit)+IDE(1bit)+r0(1bit)+length(4bits)+data(64bits)+CRC(15bits)+CRCDelimiter(1bit)+ACK(1bit)+ACKDelimiter(1bit)+(1bit)stop(1bit)
		CAN_WRITE_BYTE(108'b000000010100000000110101010101010101010101010101010101010101010101010101010101010100100001100000001011111111); //data frame standard
      @(posedge r_Clock);
             
      // Check that the correct command was received
      if (w_Rx_Byte == 108'b000000010100000000110101010101010101010101010101010101010101010101010101010101010100100001100000001011111111)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
   
endmodule