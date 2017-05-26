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
  wire [101:0] w_Rx_Byte; //start+identifier+RTR+IDE+RESERVED0+data
   
 
  // Takes in input byte and serializes it 
  task CAN_WRITE_BYTE;
	 input		  i_start; //
	 input [10:0] i_identifier; //
	 input		  i_RTR; //
	 input		  i_IDE; //
	 input		  i_RESERVED0; //
	 input [3:0] i_length; //
	 input [63:0] i_Data; //
	 input [14:0] i_CRC; //
	 input		  i_CRC_DELIM; //
	 input		  i_ACK; //
	 input		  i_ACK_DELIM; //
	 input		  i_STOP; //
    integer     ii;
    begin
       
      // Send Start Bit
      r_Rx_Serial <= i_start;
      #(c_BIT_PERIOD);
      //#1000;
		
		// Send Data Identifier
      for (ii=0; ii<11; ii=ii+1)
        begin
          r_Rx_Serial <= i_identifier[ii];
          #(c_BIT_PERIOD);
        end
      
		// Send RTR Bit
		r_Rx_Serial <= i_RTR;
		#(c_BIT_PERIOD);
		
		// Send IDE Bit
		r_Rx_Serial <= i_IDE;
		#(c_BIT_PERIOD);
		
		// Send Reserved0 Bit
		r_Rx_Serial <= i_RESERVED0;
		#(c_BIT_PERIOD);
		
		// Send length
      for (ii=0; ii<4; ii=ii+1)
        begin
          r_Rx_Serial <= i_length[ii];
          #(c_BIT_PERIOD);
        end
		
		// Send Data
      for (ii=0; ii<64; ii=ii+1)
        begin
          r_Rx_Serial <= i_Data[ii];
          #(c_BIT_PERIOD);
        end
		 
		// Send CRC
		for (ii=0; ii<15; ii=ii+1)
        begin
          r_Rx_Serial <= i_CRC[ii];
          #(c_BIT_PERIOD);
        end
		
		// Send CRC Delimiter
      r_Rx_Serial <= i_CRC_DELIM;
      #(c_BIT_PERIOD);
		
		// Send ACK
      r_Rx_Serial <= i_ACK;
      #(c_BIT_PERIOD);
		
		// Send ACK Delimiter
      r_Rx_Serial <= i_ACK_DELIM;
      #(c_BIT_PERIOD);
		
      // Send Stop Bit
      r_Rx_Serial <= i_STOP;
      #(c_BIT_PERIOD);
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
		CAN_WRITE_BYTE(1'b0, 11'b00000010100, 1'b0, 1'b0, 1'b0, 4'b0001, 64'b1010101010101010101010101010101010101010101010101010101010101010, 15'b010000110000000, 1'b1, 1'b0, 1'b1, 1'b1);
      @(posedge r_Clock);
             
      // Check that the correct command was received
      if (w_Rx_Byte == 102'b110101000011000000010101010101010101010101010101010101010101010101010101010101010100001000000000101000)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
   
endmodule