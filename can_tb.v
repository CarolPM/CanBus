`timescale 1ns/10ps
 
`include "can_rx.v"
`include "can_destuff.v"

 
module can_tb ();
 
  parameter c_CLOCK_PERIOD_NS = 100;
  parameter c_CLKS_PER_BIT    = 10;
  parameter c_BIT_PERIOD      = 1000;
  parameter s_DESTUFF  		   = 0;
  parameter s_RX		   		= 1;
  parameter Tamanho           = 172;
  
  reg r_Clock = 0;
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
				#(700);                                   //Delay maroto
				r_Rx_Serial<= i_Data[ii];
				/*if(Ignora_Bit==1)
					$display("EXISTE UM BIT IGNORADO");
				if(Eror_Stuffing==1)
					$display("EXISTE UM Erro BIT");*/
				#(300);                                  //Delay maroto
			end 
     end
  endtask // CAN_WRITE_BYTE
   

	can_destuff #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_DESTUFF_INST
	(
		.i_Clock(r_Clock),
		.i_Ds_Serial(r_Ds_Serial),
		.o_Ignora_Bit(Ignora_Bit),
		.o_Eror_Stuffing(Eror_Stuffing)
	);
	
	can_rx #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) CAN_RX_INST
	(
		.i_Clock(r_Clock),
		.i_Rx_Serial(r_Rx_Serial),
		.i_Erro_Flag(Eror_Stuffing),
		.i_Ignora_bit(Ignora_Bit)
    );

   
  always
    #(c_CLOCK_PERIOD_NS/2) r_Clock <= !r_Clock;
 
 
   
  // Main Testing:
  initial
    begin
      // Send a command to the CAN (exercise Rx)
      @(posedge r_Clock);
			CAN_WRITE_BYTE(172'b0010101010100101010101010101010101100100101010101010100101100110101101111111111111111110010101010100101010101010101010101100100101010101010100101100110100001111111111100000); //data frame standard
    end
endmodule