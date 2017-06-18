`include "can_decoder.v"
`include "can_destuffing.v"

// Para testar uma sequencia, mude o parametro "tamanho" para o tamanho da sequencia e a proprioa sequencia na funcao "Can_Write"
////////////////////////////////////////
// Modulo Gerador -> Simula o Barramento
////////////////////////////////////////
module can_testbench ();
 
  //Clock Teste Banch (10 Mb)
  parameter Periodo_Clock_TB    = 100;
  parameter Periodo_Bit_TB      = 1000;
  
  //Clock Sample Point (1 Mb)
  parameter Periodo_Clock_SP    = 1000;
  parameter Periodo_Bit_SP      = 10000;
  
  //Clocks Por Bit
  parameter Clocks_Por_Bit      = 10;
  
  
  //Tamanho da sequencia de entrada
  parameter Tamanho           = 130;
  
  reg Clock_TB = 0;     // Clock do Teste Banch
  reg Clock_SP = 0;     // Clock do Sample Point

  reg r_Rx_Serial = 1;  // Entrada Do Modulo Principal
  reg r_Ds_Serial = 1;	// Entrada Do Bit Destuffing
  
  wire Ignora_Bit;		// flag para avisar o modulo principal do Destuffing  (000001)
  wire Error_Stuffing;  // flag para avisar o modulo principal do Error Frame (000000)

  task CAN_WRITE_BYTE;          // CAN_WRITE_BYTE
  input [0:Tamanho-1] i_Data;
  integer Count;
  begin
	for (Count=0; Count<Tamanho; Count=Count+1)
		begin                       
			r_Ds_Serial <= i_Data[Count];				// Seta entrada para o Destuffing
			r_Rx_Serial <= i_Data[Count];           // Seta entrada para o Modulo Principal
			#(1000);                               // Delay para simular o Clock     
		end 
   end
  endtask                       // CAN_WRITE_BYTE
   

	can_destuffing #(.CLKS_PER_BIT(Clocks_Por_Bit)) CAN_DESTUFFING_INST		//Instancia Do Modulo Destuff
	(
		.Clock_SP(Clock_SP),															//Formato Entrada(Saida)
		.Bit_Input(r_Ds_Serial),													//Formato Entrada(Saida)
		.Ignora_Bit(Ignora_Bit),													//Formato Entrada(Saida)
		.Error_Stuffing(Error_Stuffing)											//Formato Entrada(Saida)
	);
	
	can_decoder #(.CLKS_PER_BIT(Clocks_Por_Bit)) CAN_DECODER_INST              //Instancia Do Modulo Principal
	(
		.Clock_TB(Clock_TB),													     //Formato Entrada(Saida)
		.Clock_SP(Clock_SP),													     //Formato Entrada(Saida)
		.Bit_Input(r_Rx_Serial),												  //Formato Entrada(Saida)
		.Erro_Flag(Error_Stuffing),											  //Formato Entrada(Saida)
		.Ignora_bit(Ignora_Bit),												     //Formato Entrada(Saida)
		.o_Output_On(),
		.o_Data_Flag(),
		.o_Estendido_Flag(),
		.o_Data_Lenth(),
		.o_ID_Field(),
		.o_Data_Field()
    );

   
  always																// Clock Teste Banch (10 MB)
    #(Periodo_Clock_TB/2) Clock_TB <= !Clock_TB;
	 
  always																// Clock Sample Point (1 MB)
    #(Periodo_Clock_SP/2) Clock_SP <= !Clock_SP;
 

  initial					// Coloque a sequencia de entrada aqui
    begin
      @(posedge Clock_TB);		
			CAN_WRITE_BYTE(130'b0101010101011111111100000011111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111); //data frame standard
    end
	 
endmodule