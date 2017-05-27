//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
 
// This testbench will exercise both the UART Tx and Rx.
// It sends out byte 0xAB over the transmitter
// It then exercises the receive by receiving byte 0x3F
`timescale 1ns/10ps
 
`include "can_tx.v"
`include "can_rx.v"
`include "can_destuff.v"
 
module can_tb ();
 
  // Testbench uses a 10 MHz clock
  // Want to interface to 115200 baud UART
  // 10000000 / 115200 = 87 Clocks Per Bit.
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
  parameter s_DESTUFF  		   = 0;
  parameter s_RX		   		= 1;
  
  reg r_Clock = 0;
  reg r_Tx_DV = 0;
  wire w_Tx_Done;
  //reg [7:0] r_Tx_Byte = 0;
  reg r_Rx_Serial = 1;
  reg r_Ds_Serial = 1;
  wire [0:107] w_Rx_Byte; //start+identifier+RTR+IDE+RESERVED0+data
  wire cont_0 = 0;
  wire cont_1 = 0;
  wire flag_destuff = 0;
  reg [0:31] Clock_Count = 0;
  reg [0:31] loop = 0;
 
  // Takes in input byte and serializes it 
  task CAN_WRITE_BYTE;
	 //input		  i_start; //
	 //input [10:0] i_identifier; //
	 //input		  i_RTR; //
	 //input		  i_IDE; //
	 //input		  i_RESERVED0; //
	 //input [3:0] i_length; //
	 input [0:110] i_Data; //
	 //input [14:0] i_CRC; //
	 //input		  i_CRC_DELIM; //
	 //input		  i_ACK; //
	 //input		  i_ACK_DELIM; //
	 //input		  i_STOP; //
    reg [0:7]     ii;
	 //integer		  count_stuff_0 = 0;
	 //integer		  count_stuff_1 = 0;
    begin
       
      // Send All Data
		for (ii=0; ii<111; ii=ii+1)
			begin
				r_Ds_Serial <= i_Data[ii];
				#(c_BIT_PERIOD);
				if (flag_destuff == 1)
					ii = ii + 1;
					//r_Rx_Serial <= i_Data[ii];
				r_Rx_Serial <= i_Data[ii];
				//else
					//r_Rx_Serial <= i_Data[ii+1];
				#(c_BIT_PERIOD);
				/*
				$display("Indice antes(%d)	Bit: %b", ii, i_Data[ii]);
				case (loop)
					s_DESTUFF :
						begin
							//$display("Clock_count=%b	c_CLKS_PER_BIT=%b", Clock_Count, c_CLKS_PER_BIT);
							if (Clock_Count == (c_CLKS_PER_BIT-1))
								begin
									//$display("Entrei loop");
									Clock_Count = 0;
									//if (flag_destuff == 0)
										//r_Rx_Serial <= i_Data[ii];
									//else
									if(flag_destuff == 1)
										begin
											$display("Flaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaag=1");
											ii = ii + 1;
											//r_Rx_Serial <= i_Data[ii];
										end
									$display("Indice durante(%d)	Bit: %b", ii, i_Data[ii]);
									//#((c_BIT_PERIOD-1)/2);
									$display("s_RX = %b", s_RX);
									$display("loop = %b", loop);
									loop = s_RX;
								end
							else
								begin
									$display("Clock_count=%b	c_CLKS_PER_BIT=%b", Clock_Count, c_CLKS_PER_BIT);
									Clock_Count = Clock_Count + 1;
									loop = s_DESTUFF;
								end
						end
						
					s_RX :
						begin
							$display("Entrei RX");
							if (Clock_Count < c_CLKS_PER_BIT-1)
								begin
									Clock_Count = Clock_Count + 1;
									loop = s_RX;
								end
							else
								begin
									Clock_Count = 0;
									r_Rx_Serial = i_Data[ii];
									$display("Indice depois(%d)	Bit: %b", ii, i_Data[ii]);
									//#(c_BIT_PERIOD);
									loop = s_DESTUFF;
								end
						end
						
				   //default :
						//loop = s_DESTUFF;
				endcase*/
			end
     end
  endtask // CAN_WRITE_BYTE
   

	can_destuff #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_DESTUFF_INST
	(
		.i_Clock(r_Clock),
		.i_Ds_Serial(r_Ds_Serial),
		.i_cont_0(cont_0),
		.i_cont_1(cont_1),
		//.i_bit_index(ii),
		//.o_bit_index(ii),
		.o_flag_destuff(flag_destuff),
		.o_cont_0(cont_0),
		.o_cont_1(cont_1)
	);
	
	can_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_RX_INST
	(
		.i_Clock(r_Clock),
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
		CAN_WRITE_BYTE(111'b000001001010000010001101010101010101010101010101010101010101010101010101010101010101001000011000001001011111111); //data frame standard
      @(posedge r_Clock);
      
		$display("Frame: %b", w_Rx_Byte);
      // Check that the correct command was received
      if (w_Rx_Byte == 108'b000000010100000000110101010101010101010101010101010101010101010101010101010101010100100001100000001011111111)
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
   
endmodule