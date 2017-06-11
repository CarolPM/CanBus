`timescale 1ns/10ps
 
`include "can_rx.v"
`include "can_destuff.v"

 
module can_tb ();
 
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
  
  parameter c_CLOCK_PERIOD_NS2 = 1000;
  parameter c_CLKS_PER_BIT2   = 10;
  parameter c_BIT_PERIOD2      = 10000;
  
  
  
  parameter s_DESTUFF  		   = 0;
  parameter s_RX		   		= 1;
  parameter Tamanho           = 87;
  
  reg r_Clock = 0;
  reg Sample_Point = 0;
  reg r_Clock2 = 0;
  reg r_Rx_Serial = 1;
  reg r_Ds_Serial = 1;
  wire Ignora_Bit;
  wire Eror_Stuffing;

  task CAN_WRITE_BYTE;
	 input [0:Tamanho-1] i_Data;
    integer     ii;
    begin
		for (ii=0; ii<Tamanho; ii=ii+1)
			begin                       
					r_Ds_Serial <= i_Data[ii];
					r_Rx_Serial<= i_Data[ii];
					#(1000);                                  //Delay maroto
			end 
     end
  endtask // CAN_WRITE_BYTE
   

	can_destuff #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_DESTUFF_INST
	(
		.i_Sample(r_Clock2),
		.i_Ds_Serial(r_Ds_Serial),
		.o_Ignora_Bit(Ignora_Bit),
		.o_Eror_Stuffing(Eror_Stuffing)
	);
	
	can_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_RX_INST
	(
		.i_Clock(r_Clock),
		.i_Sample(r_Clock2),
		.i_Rx_Serial(r_Rx_Serial),
		.i_Erro_Flag(Eror_Stuffing),
		.i_Ignora_bit(Ignora_Bit)
    );

   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
	 
  always
    #(c_CLOCK_PERIOD_NS2/2) r_Clock2 <= !r_Clock2;
 

 
   
  // Main Testing:
  initial
    begin
      // Send a command to the CAN (exercise Rx)
      @(posedge r_Clock);
			CAN_WRITE_BYTE(87'b001010101010010101010101010101010110010010101010101010010110011011110100010111111111111); //data frame standard
    end
endmodule