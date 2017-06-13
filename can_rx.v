`include "can_form_error.v"
`include "can_crc_checker.v"

module can_rx
(  input Clock_TB,
	input Clock_SP,
   input Bit_Input,
	input Erro_Flag,
	input Ignora_bit
);
   
  //Estados  --> Não mude
  parameter [0:5] Identificador_A 		               = 0;			// Pega os 11 Bits do indentificador A
  parameter [0:5] Identificador_B      		         = 1; 			// Pega os 18 Bits do indentificador B      
  parameter [0:5] Doubt_Bits		                     = 2;			// Pega (SRR e IDE) ou (RTR e IDE)
  parameter [0:5] Reserved_Bits_Extendido             = 3;			// Pega R0 e R1 do extendido
  parameter [0:5] Reserved_Bit_Normal                 = 4;			// Pega R0 do Normal
  parameter [0:5] RTR_Extendido                       = 5;			// Pega o RTR do extendido
  parameter [0:5] Length_Data_Field                   = 6;			// Pega a sequencia que determina o tamanho do data
  parameter [0:5] Data_Frame                          = 7;			// Pega a sequencia data
  parameter [0:5] CRC_Frame                           = 8;			// Pega a sequencia CRC
  parameter [0:5] CRC_Delimiter                       = 9;			// Pega a sequencia CRC Delimiter
  parameter [0:5] ACK_Delimiter                       = 10;			// Pega a sequencia ACK Delimiter
  parameter [0:5] ACK_Frame                           = 11;			// Pega a sequencia ACK
  parameter [0:5] Stuffing_Check                      = 12;			// Aguarda o novo bit (baseado no sample point)
  parameter [0:5] ConClusao                           = 13; 		// Imprime Informações sobre o frame
  //parameter [0:5] Passive_Error                       = 14;       // Ler os 14 bits recessivos do error passivo
  parameter [0:5] Active_Error 								= 15;			// Pega o erro ativo (12-18 bits)
  //parameter [0:5] Error_Frame							      = 16;			// Decide se o erro é Ativo ou passivo
  parameter [0:5] Overload_Frame 							= 17;			// Pega o Overload (12-18 bits)
  parameter [0:5] Waiting 									   = 18;			// Interframe
  parameter [0:5] Reseta_Variaveis						   = 19;			// Zera as variaveis para um novo frame 
  parameter [0:5] End_Of_Frame                        = 20;			// Os 7 bits finais do frame
  parameter [0:5] Ocioso        		                  = 21;			// Estado para debugger (Simula o barramento em espera)
  //Variaveis temporarias para guardar Estados
  reg [0:5]    Redirecionando       = Identificador_A;				// Fatores de implementacao
  reg [0:5]    Estado               = Stuffing_Check;             // Comeco esperando o novo Bit
  //Variavel setada pelo gerador 
  parameter CLKS_PER_BIT = 10; 
  //Variaveis 
  reg [0:31] New_Jump                  = 0;								// Guarda o pulo de index (varia para frames normais e extendidos)
  reg [0:31] Count_Length              = 0;								// Contador pata a sequencia que determina o tamanho
  reg [0:31] Count_Index               = 1;								// Contador para o indice do vetor principal							
  reg [0:31] Count_Interframe          = 0;								// Contador para o interframe
  reg [0:31] Count_Overload            = 0;								// Contador para o overload
  reg [0:31] Count_ActiveError         = 0;								// Contador para o erro ativo
  reg [0:31] Count_PassiveError        = 0;								// Contador para o erro passivo
  //Sequencia de bits (Frame)
  reg [0:200]   Vector_Frame           = 0;								// Vetor que guarda o frame
  // Outros
  reg [0:3]     Length_Data            = 0;  						   // Vetor que guarda a sequencia data (uso a propria linguagem de programacao para fazer a conversao de uma sequencia de bits para um inteiro
  reg           Stuffing_ON            = 1;							   // Bit que marca se devemos ou não considerar o Destuff
  reg           RTR_BIT                = 1;							   // Guarda o Bit RTR
  reg           Data_Bit               = 1;	                   	// Bit de entrada						
  reg           Sample_Point           = 0;								// Sample Point (clock do Bit Timing)
  reg           Ini                    = 0;								// Marca o primeiro bit a ser lido (fator de implementacao)
  //Fios
  
  wire Form_monitor;														// Fio do form error que marca os erros de formação ( um bit para cada tipo de erro)
  wire CRC_monitor;																// Fio que marca erro de CRC

  
  	can_form_error #(.form_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_FORM_ERROR_INST
  (.Clock_TB(Clock_TB),
   .Estado(Estado),
   .Bit_Entrada(Data_Bit),
   .Form_monitor(Form_monitor)
   );

	can_crc_checker #(.crc_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_CRC_CHECKER_INST
	(.Clock_TB(Clock_TB),
	 .Estado(Estado),
	 .Bit_Entrada(Data_Bit),
	 .CRC_monitor(CRC_monitor)
	 );


  always @(posedge Clock_SP)				// Liberado pelo Sample Point
    begin
		Sample_Point=1;						// Libera o always principal
      Data_Bit  <= Bit_Input;				// Ler novo bit
    end

  always @(posedge Clock_TB)				// Always principal
    begin
	  case (Estado)
		//-------------------------------------------------------------------------
		Reseta_Variaveis:
		begin																				// Reinicia variaveis
			Redirecionando                      <= Identificador_A;		// Fator de implementação
			Count_PassiveError                  <= 0;                   // Auto Explicativo							
			Count_ActiveError                   <= 0;                   // Auto Explicativo
			Count_Index                         <= 1;                   // Auto Explicativo
			Count_Interframe                    <= 0;                   // Auto Explicativo
			Count_Overload                      <= 0;                   // Auto Explicativo
			Count_Length                        <= 0;                   // Auto Explicativo
			New_Jump                            <= 0;                   // Auto Explicativo
			Stuffing_ON                         <= 1;                   // Auto Explicativo
			Vector_Frame[0]                     <= 0;                   // Auto Explicativo
			Estado                              <= Stuffing_Check;      // Auto Explicativo
		end
	   //-------------------------------------------------------------------------
		Stuffing_Check:																// Espera a liberacao para pegar novo bit
		begin 				
			 if(Sample_Point==1&&Ini==1)										   // Se o sample point for liberado e não for o primeiro bit da sequencia			
			 begin
			   Sample_Point <=0;														// Reseto Sample Point
				if(Stuffing_ON==1)													// Se o destuffing estiver sendo levado em consideracao
				begin	
					if(Erro_Flag==1)													// 6 bits repetidos ? (111111 ou 000000)
					begin
						$display("Erro BIt Stuffing");
						Estado<=Active_Error;											// Mando para estado de erro
					end
					else if(Ignora_bit==1)											// Bit Destuffing ? (111110 ou 000002)	
					begin
						$display("Bit Ignorado");
						Estado<=Stuffing_Check;										// Pulo um estado e espero o proximo bit
					end
					else
						Estado <= Redirecionando;									// Se tudo OK continuo com o fluxo normal
				end
				else
					Estado <= Redirecionando;										// Se não estou mais levando em consideracao o destuffing entao, so continuo com o fluxo normal
			 end
			 else if(Sample_Point==1&&Ini==0&&Data_Bit==0)					// Se o sample point for liberado e for o primeiro bit da sequencia igual a 0 ( pode vim varios '1' antes de comecar o frame			
			 begin
				Sample_Point <=0;														// Reseto Sample Point
				Ini<=1;																	// A a partir de agora, estamos na sequencia
				Vector_Frame[0] <= 0; 												// Start bit guardado
				//$strobe("Start = %d",Data_Bit);								// Debugger
			 end
		 end
		//-------------------------------------------------------------------------
		Identificador_A:
		begin
			//$display("ID_A = %d",Data_Bit); 								   // Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;	 									// Incremento contador
         if (Count_Index < 11)
				Redirecionando   <= Identificador_A;							// pegando 11 bits do ID_A
			else
            Redirecionando   <= Doubt_Bits;									// Acabou os 11 bits
			Estado <= Stuffing_Check;												// Mando esperar novo bit
		end 
		//-------------------------------------------------------------------------
		Doubt_Bits:
		begin
			//$display("DOUB = %d",Data_Bit); 								   // Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;							         // Incremento contador
         if (Count_Index < 13)
				Redirecionando   <= Doubt_Bits;									// pegando 2 bits apos o ID_A (IDE e (SRR ou RTR))
			else
         begin  
				if(Data_Bit== 0)														// Verifico IDE para saber se o frame é extendido ou normal
					Redirecionando   <=  Reserved_Bit_Normal;					// Frame Normal
				else
					Redirecionando   <=  Identificador_B;						// Extendido
			end    
			Estado <= Stuffing_Check;												// Mando esperar novo bit
		end 
		//-------------------------------------------------------------------------
		Identificador_B:
		begin
			//$display("ID_B = %d",Data_Bit); 								   // Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;							         // Incremento contador 
         if (Count_Index < 31)									            // pegando os 18 bits do ID_B
             Redirecionando   <= Identificador_B;							
			else
            Redirecionando   <= RTR_Extendido; 								// Acabando os 18 bits, proximo passo RTR extendido
         Estado <= Stuffing_Check;												// Mando esperar novo bit   
		end   
		//-------------------------------------------------------------------------
		RTR_Extendido:
		begin
			//$display("RTR EX = %d",Data_Bit); 								// Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;							         // Incremento contador 
			RTR_BIT <= Data_Bit;														// pegando o RTR Exetendido
			Redirecionando   <= Reserved_Bits_Extendido;						// RTR extendido, proximo passo r0 e r1 extendidos
			Estado <= Stuffing_Check;												// Mando esperar novo bit  
		end   
		//-------------------------------------------------------------------------
		Reserved_Bits_Extendido:
		begin
			//$strobe("Res_Exte = %d",Data_Bit); 								// Debugger
			Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;							         // Incremento contador  
			if (Count_Index < 34)													// pegando os 2 bits reservados
				Redirecionando   <= Reserved_Bits_Extendido;
			else
         begin  
				New_Jump <= 34;														// Pulo para marcar onde estou no vetor
				Redirecionando   <= Length_Data_Field;							// proximo passo sequencia data frame
         end
			Estado <= Stuffing_Check;												// Mando esperar novo bit  
		end 
		//-------------------------------------------------------------------------
		Reserved_Bit_Normal:
		begin
			//$display("Res_Norma = %d",Data_Bit); 							// Debugger
			Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   
			Count_Index <= Count_Index + 1;							         // Incremento contador   
			Redirecionando   <= Length_Data_Field;							   // proximo passo sequencia data frame  
			New_Jump <= 14;															// Pulo para marcar onde estou no vetor
			RTR_BIT <= Vector_Frame[12];											// RTR no caso do normal frame
			Estado <= Stuffing_Check;												// Mando esperar novo bit  
		end 
		//-------------------------------------------------------------------------  
		Length_Data_Field:
		begin
			//$display("LENG = %d",Data_Bit); 							      // Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   
			Length_Data[Count_Length] <= Data_Bit;								// Guardo proximo bit da sequencia frame 
			Count_Length=Count_Length+1;											// Incremento contador  
			Count_Index <= Count_Index +1;										// Incremento contador  
         if (Count_Index < New_Jump+4)											// Pegando os 4 bits
				Redirecionando   <= Length_Data_Field;
			else
         begin  
				//$strobe("Tamanho = %d",Length_Data);			 				// Debugger	
				if(Length_Data>8)														// Se o tamanho for > 8, considero tamanho 8 (sera?)
					Length_Data<=8;
				New_Jump <= New_Jump+4;												// Novo pulo
				if(RTR_BIT==0)
					Redirecionando   <=  Data_Frame;								// Se Data frame, vou pegar os dados
				else
					Redirecionando   <=  CRC_Frame;								// Se Remote frame, vou direto para CRC
         end  
			Estado <= Stuffing_Check;												// Mando esperar novo bit  
		end 
		//-------------------------------------------------------------------------    
		Data_Frame:
		begin
			//$display("DATA = %d",Data_Bit); 							      // Debugger
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;										// Incremento contador  	
         if (Count_Index < New_Jump+(Length_Data*8))						// Leio os bits relativos a data, tamanho em bytes vezes 8 bits
				Redirecionando   <= Data_Frame;									// Continuo pegando o data
			else
         begin  
				New_Jump <= New_Jump+(Length_Data*8);							// Novo Pulo
				Redirecionando   <= CRC_Frame;									// Proximo passo, CRC frame
         end
			Estado <= Stuffing_Check;												// Mando esperar novo bit 
		end 
		//-------------------------------------------------------------------------  
		CRC_Frame:
		begin
			//$display("CRC_Frame = %d",Data_Bit); 							// Debugger  
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit
			Count_Index <= Count_Index + 1;										// Incremento contador  
         if (Count_Index < New_Jump+15)										// Pegos os 15 bits do crc frame
				Redirecionando   <= CRC_Frame;									// Continuo pegando os bits do crc
			else
				Redirecionando   <= CRC_Delimiter;								// Proximo passo, CRC Delimiter
			Estado <= Stuffing_Check;												// Mando esperar novo bit 
		end 
		//------------------------------------------------------------------------- 
		CRC_Delimiter:
		begin
			#(100);
			//$display("CRC_Delimiter = %d",Data_Bit); 						// Debugger 
		   Stuffing_ON=0;																// O stuffing não é mais relevante
			Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   						
			Count_Index <= Count_Index + 1;   									// Incremento contador 
			Redirecionando   <= ACK_Frame;										// Proximo passo, ACK Frame 
			Estado <= Stuffing_Check;												// Mando esperar novo bit 
			if(Form_monitor==1)
			begin
				$display("CRC_Delimiter Erro"); 						
				Redirecionando   <= Active_Error;
			end
		end 
		//-------------------------------------------------------------------------
		ACK_Frame:
		begin
			//$display("ACK_Frame = %d",Data_Bit); 						   // Debugger 
         Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   
			Count_Index <= Count_Index + 1;   									// Incremento contador  	
			Redirecionando   <= ACK_Delimiter;									// Proximo passo, ACK Delimiter
			Estado <= Stuffing_Check;												// Mando esperar novo bit    
		end
		//-------------------------------------------------------------------------
		ACK_Delimiter:
		begin
			#(100);
			//$display("ACK_Delimiter = %d",Data_Bit); 						// Debugger 
			Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   
			Count_Index <= Count_Index + 1;   									// Incremento contador  	
			Redirecionando   <= End_Of_Frame;									// Proximo passo, End of frame
			Estado <= Stuffing_Check;					
			// Mando esperar novo bit
			if(Form_monitor==1)
			begin
				$display("ACK_Delimiter Erro"); 	
				Redirecionando   <= Active_Error;	
		   end		
			if(CRC_monitor==1)
			begin
				$display("Falha na Comparacao de seguranca"); 	
				Redirecionando   <= Active_Error;	
		   end
			
			
			
		 end 
		//-------------------------------------------------------------------------    
		End_Of_Frame:
		begin
			#(100);
			//$display("End = %d",Data_Bit); 					         	// Debugger 
			Vector_Frame[Count_Index] <= Data_Bit;								// Guardo proximo bit   
			Count_Index <= Count_Index + 1;   									// Incremento contador  	
			if (Count_Index < New_Jump+25)										// Pego os 7 bits
			begin
				Redirecionando <= End_Of_Frame;									// Continuo pegando os bits
				Estado <= Stuffing_Check;											// Mando esperar novo bit
			end
			else
				Estado <= ConClusao;													// Fim do frame, Finalizando...
			if(Form_monitor==1)
			begin
				$display("End Of Frame Erro");
				Estado <= Stuffing_Check;	
				Redirecionando   <= Active_Error;
			end
			
		end
		//------------------------------------------------------------------------- 
		ConClusao:
		begin
			 // INFORMACOES BASICAS
		    if(Vector_Frame[13]==0)								//Frame Normal
			 begin
				if(Vector_Frame[12]==0)
					$write("DATA FRAME NORMAL, %d Bytes de dados, Tamanho de Frame = %d Bits;",Length_Data,Count_Index);
			   else
					$write("REMOTE FRAME NORMAL,Tamanho de Frame = %d Bits;",Count_Index);
			 end
			 else
			 begin														//Frame Extendido
			 	if(Vector_Frame[32]==0)								
					$write("DATA FRAME EXTENDED, %d Bytes de dados, Tamanho de Frame = %d Bits;",Length_Data,Count_Index);
			   else
					$write("REMOTE FRAME EXTENDED,Tamanho de Frame = %d Bits;",Count_Index);
			 end
			 //ERROS E WARNINGS		
			 if (Vector_Frame[12]==0&&Vector_Frame[13]==1)
				$write("//*Warning --> Wrong SRR*//");
			 if (Vector_Frame[35:38]>8&&Vector_Frame[13]==1)
				$write("//*Tamanho Invalido (>8) -> Tamanho considerado = 8*//");
			 if (Vector_Frame[15:18]>8&&Vector_Frame[13]==0)
				$write("//*Tamanho Invalido (>8) -> Tamanho considerado = 8*//");
			 if (Vector_Frame[33]==1&&Vector_Frame[13]==1)
				$write("//*Warning --> Reserved bit R0*//");
			 if (Vector_Frame[34]==1&&Vector_Frame[13]==1)
				$write("//*Warning --> Reserved bit R1*//");
			 if (Vector_Frame[14]==1&&Vector_Frame[13]==0)
				$write("//*Warning --> Reserved bit R0*//");
			 //ERROS E WARNINGS	--> Representação feia ? pode melhorar ?
			 $display("/-->End<--//");
			 Estado <= Stuffing_Check;											// Mando esperar novo bit
			 Redirecionando <= Waiting;										// Proximo passo, interframe
			 //Estado <= Ocioso;													// Debuger, pegar apenas o primeiro frame, comentar para pegar sequencias, não comentar para um unico frame
		  end
		//-------------------------------------------------------------------------
		Waiting:																		// Interframe+intermission
		begin
			Estado <= Stuffing_Check;											// Mando esperar novo bit
			if(Data_Bit==1)														// Equanto bit igual a '1' (interframe)
			begin
				//$display("Interframing = %d",Data_Bit);					// Debuger, é bom ficar sempre comentado
				Count_Interframe<=Count_Interframe+1;						// Conto a quantidade de bits no interframe+intermission
				Redirecionando <= Waiting;										// Novo Bit
			end
			else
			begin																		// Primeiro BIt 0		
				//$display("Interframing = %d",Data_Bit);
				if(Count_Interframe<3)											// Se houve apenas 2 ou menos bits de interframe
					Estado<=Overload_Frame;										// é um overload
				else
				begin	
					Estado<=Reseta_Variaveis;									// Se mais de 2 bits de inteframe, novo frame remote ou data
					$display("INTERFRAME (%d)",Count_Interframe);		// Debuger
					//$display("Start = %d",Data_Bit);						// Debuger
				end
				Count_Interframe<=0;												// Auto explicativo
			end
																	
		end
		//-------------------------------------------------------------------------	
		Overload_Frame:
		begin
			Redirecionando<=Overload_Frame;
			//$display("Overload = %d",Data_Bit);					   	   // Debuger
			if(Data_Bit==1)
				Count_Overload<=Count_Overload+1;							// Conta quando achamos um bit recessivo
			if(Count_Overload==7)												// 8 bits recessivos marca o fim do frame
			begin
				$display("OVERLOAD FRAME");
				Redirecionando <= Waiting;
				Count_Overload<=0;
			end
			Estado <= Stuffing_Check;											// Mando esperar novo bit		
		end
		//-------------------------------------------------------------------------			
		/*Error_Frame:
		begin
			//$display("ERRO = %d",Data_Bit);					      	// Debuger
			Count_ActiveError<=0;												// Auto explicativo
			Count_PassiveError<=0;												// Auto explicativo
			Stuffing_ON<=0;														// Stuffing não é mais relevante
			Redirecionando <= Active_Error;							
			Estado <= Stuffing_Check;											// Mando esperar novo bit		
		end*/
		//-------------------------------------------------------------------------	
		Active_Error:
		begin
			//$display("Active Error = %d",Data_Bit);					   // Debuger
			Stuffing_ON=0;
			Redirecionando <= Active_Error;
			if(Data_Bit==1)														// Conto os bits recessivos
				Count_ActiveError<=Count_ActiveError+1;
			if(Count_ActiveError==7)											// 8 bits recessivos marcam o final do frame
			begin
				$display("ACTIVE ERROR FRAME");
				Redirecionando <= Waiting;
			end
			Estado <= Stuffing_Check;											// Mando esperar novo bit	
			
		end
		//-------------------------------------------------------------------------
		/*Passive_Error:
		begin
			//$display("Passive Error = %d",Data_Bit);
			Redirecionando <= Passive_Error;
			if(Data_Bit==1)														
				Count_PassiveError<=Count_PassiveError+1;					// Conto o numero de bits recessivos
			if(Count_PassiveError==7)											// 6+8 = 14 bits recessivos -> passive error 
			begin
				$display("PASSIVE ERROR FRAME");
				Redirecionando <= Waiting;
			end
			Estado <= Stuffing_Check;											// Mando esperar novo bit				
		end*/
		//-------------------------------------------------------------------------  
		Ocioso:																		//Debuger
		begin
			  Estado   <= Ocioso;
		end  
	   //-------------------------------------------------------------------------  
      endcase
    end   

  endmodule 