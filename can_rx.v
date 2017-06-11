`include "can_form_error.v"
`include "can_crc_checker.v"

module can_rx
(  input i_Clock,
	input i_Sample,
   input i_Rx_Serial,
	input i_Erro_Flag,
	input i_Ignora_bit
);
   
  //Estados
  parameter [0:5] Identificador_A 		               = 0;
  parameter [0:5] Identificador_B      		         = 1;
  parameter [0:5] Doubt_Bits		                     = 2;
  parameter [0:5] Reserved_Bits_Extendido             = 3;
  parameter [0:5] Reserved_Bit_Normal                 = 4;
  parameter [0:5] RTR_Extendido                       = 5;
  parameter [0:5] Length_Data_Field                   = 6;
  parameter [0:5] Data_Frame                          = 7;
  parameter [0:5] CRC_Frame                           = 8;
  parameter [0:5] CRC_Delimiter                       = 9;
  parameter [0:5] ACK_Delimiter                       = 10;
  parameter [0:5] ACK_Frame                           = 11;
  parameter [0:5] Stuffing_Check                      = 12;
  parameter [0:5] ConClusao                           = 13;  
  parameter [0:5] Passive_Error                       = 14;
  parameter [0:5] Active_Error 								= 15;
  parameter [0:5] Error_Frame							      = 16;
  parameter [0:5] Overload_Frame 							= 17;
  parameter [0:5] Waiting 									   = 18;
  parameter [0:5] Reseta_Variaveis						   = 19;
  parameter [0:5] End_Of_Frame                        = 20;
  parameter [0:5] Ocioso        		                  = 21;
  //Variaveis temporarias para guardar Estados
  reg [0:5]    Redirecionando       = Identificador_A;
  reg [0:5]    Estado               = Stuffing_Check;
  //Marcadores para detectar erros
  reg [0:4] CRC_Delimiter_ERROR			         = 0;
  reg [0:4] ACK_Delimiter_ERROR			         = 0;
  reg [0:4] CRC_Comp_ERROR                      = 0; //Incerto
  reg [0:4] Data_Length_ERROR                   = 0; //Dentro Do rx
  reg [0:4] SRR_ERROR                           = 0;
  reg [0:4] Reserved_R0_Warning	               = 0;
  reg [0:4] Reserved_R1_Warning	               = 0;
  reg [0:4] Reserved_Bit_Normal_Warning		   = 0; 
  reg [0:4] EOF_ERROR						         = 0;
  //Variavel setada pelo gerador //Essa variavel esta setada pelo tb.v 
  parameter CLKS_PER_BIT = 10; 
  //Variaveis 
  reg [0:31] Length_count              = 0;
  reg [0:31] Bit_Index                 = 1;
  reg [0:31] New_Jump                  = 0;
  reg [0:31] Count_clock               = 0;
  reg [0:31] Count_Interframe          = 0;
  reg [0:31] Count_Overload            = 0;
  reg [0:31] Count_ActiveError         = 0;
  reg [0:31] Count_PassiveError        = 0;
  //Sequencia de bits (Frame)
  reg [0:107]   Vector_Frame        = 0;
  // Outros
  reg [0:3]     Length_Data         = 0;  
  reg           Stuffing_ON         = 1;
  reg           RTR_BIT             = 1;
  reg           Data_Bit            = 1;
  reg           Sample_Point        = 0;
  reg           Ini                 = 0;
  //Fios
  
  wire [0:3] form_monitor;
  wire CRC_monitor;
  reg     [0:107]      ccc            = 0;
  
  	can_form_error #(.form_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_FORM_ERROR_INST
  (.i_Clock(i_Clock),
   .i_frame_field(Estado),
   .i_Data(Data_Bit),
   .o_form_monitor(form_monitor)
   );

	can_crc_checker #(.crc_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_CRC_CHECKER_INST
	(.i_clock(i_Clock),
	 .i_frame_field(Estado),
	 .i_Data(Data_Bit),
	 .o_CRC_monitor(CRC_monitor)
	 );


  always @(posedge i_Sample)
    begin
		Sample_Point=1;
      Data_Bit  <= i_Rx_Serial;
    end

  always @(posedge i_Clock)
    begin
	  case (Estado)
		//-------------------------------------------------------------------------
		Reseta_Variaveis:
		begin
			CRC_Delimiter_ERROR			         <= 0;
			ACK_Delimiter_ERROR			         <= 0;
			CRC_Comp_ERROR                      <= 0;
			Data_Length_ERROR                   <= 0;
			SRR_ERROR                           <= 0;
			Reserved_R0_Warning	               <= 0;
			Reserved_R1_Warning	               <= 0;
			Reserved_Bit_Normal_Warning		   <= 0; 
			EOF_ERROR						         <= 0;
			Redirecionando                      <= Identificador_A;
			Count_PassiveError                  <= 0;
			Count_ActiveError                   <= 0;
			Bit_Index                           <= 1;
			New_Jump                            <= 0;
			Count_Interframe                    <= 0;
			Count_Overload                      <= 0;
			Length_count                        <= 0;
			Stuffing_ON                         <= 1;
			Vector_Frame[0]                     <= 0; 
			Estado <= Stuffing_Check;
		end
	   //-------------------------------------------------------------------------
		Stuffing_Check:
		begin 				
			 if(Sample_Point==1&&Ini==1)
			 begin

			   Sample_Point <=0;
				Count_clock <=0;
				if(Stuffing_ON==1)
				begin
					if(i_Erro_Flag==1)
						Estado<=Error_Frame;	
					else if(i_Ignora_bit==1)
						Estado<=Stuffing_Check;
					else
						Estado <= Redirecionando;
				end
				else
					Estado <= Redirecionando;
			 end
			 else if(Sample_Point==1&&Ini==0&&Data_Bit==0)
			 begin
				Sample_Point <=0;
				Ini<=1;
				Vector_Frame[0] <= 0; 
				//$strobe("Start = %d",Data_Bit);
			 end
		 end
		//-------------------------------------------------------------------------
		Identificador_A:
		begin
			//$display("ID_A = %d",Data_Bit);
			Count_clock <= Count_clock+1;  
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1;	 
         if (Bit_Index < 11)
				Redirecionando   <= Identificador_A;
			else
            Redirecionando   <= Doubt_Bits;
			Estado <= Stuffing_Check;
		end 
		//-------------------------------------------------------------------------
		Doubt_Bits:
		begin
			//$display("DOUB = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < 13)
				Redirecionando   <= Doubt_Bits;
			else
         begin  

				if(Data_Bit== 0)
				begin
					SRR_ERROR=0;
					Redirecionando   <=  Reserved_Bit_Normal;
				end
				else
					Redirecionando   <=  Identificador_B;
			end    
			Estado <= Stuffing_Check;
		end 
		//-------------------------------------------------------------------------
		Identificador_B:
		begin
			//$display("ID_B = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1; 
         if (Bit_Index < 31)
             Redirecionando   <= Identificador_B;
			else
            Redirecionando   <= RTR_Extendido; 
         Estado <= Stuffing_Check;   
		end   
		//-------------------------------------------------------------------------
		RTR_Extendido:
		begin
			//$display("RTR EX = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
			RTR_BIT <= Data_Bit;
			Redirecionando   <= Reserved_Bits_Extendido;
			Estado <= Stuffing_Check;
		end   
		//-------------------------------------------------------------------------
		Reserved_Bits_Extendido:
		begin
			Estado <= Stuffing_Check;
			//$strobe("Res_Exte = %d",Data_Bit);
			Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			Bit_Index <= Bit_Index + 1'b1; 
			if (Bit_Index < 34)
				Redirecionando   <= Reserved_Bits_Extendido;
			else
         begin  
				New_Jump <= 34;
				Redirecionando   <= Length_Data_Field;
         end
		end 
		//-------------------------------------------------------------------------
		Reserved_Bit_Normal:
		begin
			Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			//$display("Res_Norma = %d",Data_Bit);
			if(Data_Bit==1)  
				Reserved_Bit_Normal_Warning =1;
			Bit_Index <= Bit_Index + 1'b1; 
			Redirecionando   <= Length_Data_Field;
			Estado <= Stuffing_Check;
			New_Jump <= 14;
			RTR_BIT <= Vector_Frame[12];
		end 
		//-------------------------------------------------------------------------  
		Length_Data_Field:
		begin
			//$display("LENG = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Length_Data[Length_count] <= Data_Bit;
			Length_count=Length_count+1;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < New_Jump+4)
				Redirecionando   <= Length_Data_Field;
			else
         begin  
				//$strobe("Tamanho = %d",Length_Data);
				if(Length_Data>8)
					Length_Data<=8;
				New_Jump <= New_Jump+4;
				if(RTR_BIT==0)
					Redirecionando   <=  Data_Frame;
				else
					Redirecionando   <=  CRC_Frame;
         end  
			Estado <= Stuffing_Check;
		end 
		//-------------------------------------------------------------------------    
		Data_Frame:
		begin
			//$display("DATA = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;	
         if (Bit_Index < New_Jump+(Length_Data*8))
				Redirecionando   <= Data_Frame;
			else
         begin  
				New_Jump <= New_Jump+(Length_Data*8);
				Redirecionando   <= CRC_Frame;
         end
			Estado <= Stuffing_Check;
		end 
		//-------------------------------------------------------------------------  
		CRC_Frame:
		begin
			//$strobe("CRC_Frame = %d",Data_Bit);  
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < New_Jump+15)
				Redirecionando   <= CRC_Frame;
			else
				Redirecionando   <= CRC_Delimiter;
			Estado <= Stuffing_Check;
		end 
		//------------------------------------------------------------------------- 
		CRC_Delimiter:
		begin
		   Stuffing_ON=0;
			Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			//$strobe("CRC_Delimiter = %d",Data_Bit);
			Bit_Index <= Bit_Index + 1'b1;   	
			Redirecionando   <= ACK_Frame;
			Estado <= Stuffing_Check;
		end 
		//-------------------------------------------------------------------------
		ACK_Frame:
		begin
			//$strobe("ACK_Frame = %d",Data_Bit);
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1; 	
			Redirecionando   <= ACK_Delimiter;
			Estado <= Stuffing_Check;   
		end
		//-------------------------------------------------------------------------
		ACK_Delimiter:
		begin
			//$strobe("ACK_Delimiter = %d",Data_Bit);
			Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			Bit_Index <= Bit_Index + 1'b1;
			Redirecionando   <= End_Of_Frame;
			Estado <= Stuffing_Check;					
		 end 
		//-------------------------------------------------------------------------    
		End_Of_Frame:
		begin
			Vector_Frame[Bit_Index] <= Data_Bit;
			//$display("End = %d",Data_Bit);
			Bit_Index <= Bit_Index + 1'b1;
			if (Bit_Index < New_Jump+25)
			begin
				Redirecionando <= End_Of_Frame;
				Estado <= Stuffing_Check;
			end
			else
				Estado <= ConClusao;
			
		end
		//------------------------------------------------------------------------- 
		ConClusao:
		begin
			 // INFORMACOES BASICAS
		    if(Vector_Frame[13]==0)
			 begin
				if(Vector_Frame[12]==0)
					$write("DATA FRAME NORMAL, %d Bytes de dados, Tamanho de Frame = %d Bits;",Length_Data,Bit_Index);
			   else
					$write("REMOTE FRAME NORMAL,Tamanho de Frame = %d Bits;",Bit_Index);
			 end
			 else
			 begin
			 	if(Vector_Frame[32]==0)
					$write("DATA FRAME EXTENDED, %d Bytes de dados, Tamanho de Frame = %d Bits;",Length_Data,Bit_Index);
			   else
					$write("REMOTE FRAME EXTENDED,Tamanho de Frame = %d Bits;",Bit_Index);
			 end
			 //ERROS E WARNINGS
			 if (form_monitor[1] == 1)
				$write("//*Form Error -> CRC Delimiter*//");
			 if (form_monitor[2] == 1)
			 	$write("//*Form Error -> ACK Delimiter*//");
			 if (form_monitor[0]==1&&Vector_Frame[12]==1)
				$write("//*Form Error -> SRR Bit*//");
			 if (form_monitor[3] == 1)
				$write("//*Form Error -> End Of Frame*//");				
			 if (CRC_monitor == 1)
				$write("//*Falha na Comparacao de seguranca -> CRC*//");
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
			 //ERROS E WARNINGS
			 $display("/-->End<--//");
			 
			 
			 Estado <= Stuffing_Check;
			 Redirecionando <= Waiting;
			 Estado <= Ocioso;
		  end
		//-------------------------------------------------------------------------
		Waiting:
		begin
			Estado <= Stuffing_Check;
			Estado   <= Ocioso;
			if(Data_Bit==1)
			begin
				$strobe("Interframing = %d",Data_Bit);
				Count_Interframe<=Count_Interframe+1;
				Redirecionando <= Waiting;
			end
			else
			begin
				$strobe("Start = %d",Data_Bit);
				if(Count_Interframe<2)
					Estado<=Overload_Frame;
				else
				begin
					Estado<=Reseta_Variaveis;
					$display("INTERFRAME (%d)",Count_Interframe);
				end
					
				Count_Interframe<=0;
			end
		end
		//-------------------------------------------------------------------------	
		Overload_Frame:
		begin
			//$strobe("Overload = %d",Data_Bit);
			Estado <= Stuffing_Check;
			Redirecionando <=Overload_Frame;
			if(Data_Bit==1)
				Count_Overload<=Count_Overload+1;
			if(Count_Overload==8)
			begin
				$display("OVERLOAD FRAME");
				Redirecionando <= Waiting;
				Count_Overload=0;
			end
		end
		//-------------------------------------------------------------------------			
		Error_Frame:
		begin
			$display("ERRO = %d",Data_Bit);
			Count_ActiveError<=0;
			Count_PassiveError<=0;
			Stuffing_ON<=0;
			Estado <= Stuffing_Check;
			if(Data_Bit==0)
				Redirecionando <= Active_Error;
			else
				Redirecionando <= Passive_Error;
			
		end
		//-------------------------------------------------------------------------	
		Active_Error:
		begin
			ccc<=ccc+1;
			$display("Active Error = %d",Data_Bit);
			//$display("AKI");
			Count_clock <= Count_clock + 1;
			Estado <= Stuffing_Check;
			Redirecionando <= Active_Error;
			if(Data_Bit==1)
				Count_ActiveError<=Count_ActiveError+1;
			if(Count_ActiveError==7)
			begin
				$display("ACTIVE ERROR FRAME");
				Redirecionando <= Waiting;
			end
			
			if(ccc>30)
				begin
					
					Estado<=Ocioso;
				end
		end
		//-------------------------------------------------------------------------
		Passive_Error:
		begin
			$strobe("Passive Error = %d",Data_Bit);
			Estado <= Stuffing_Check;
			Redirecionando <= Passive_Error;
			if(Data_Bit==1)
				Count_PassiveError<=Count_PassiveError+1;
			if(Count_PassiveError==7)
			begin
				$display("PASSIVE ERROR FRAME");
				Redirecionando <= Waiting;
			end
		end
		//-------------------------------------------------------------------------  
		Ocioso:
		begin
			  Estado   <= Ocioso;
		end  
	   //-------------------------------------------------------------------------  
      endcase
    end   

  endmodule // can_rx	