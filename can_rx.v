`include "can_form_error.v"
`include "can_crc_checker.v"

module can_rx
(  input i_Clock,
   input i_Rx_Serial,
	input i_Erro_Flag,
	input i_Ignora_bit
);
   
  //Estados
  parameter [0:5] Inicio        		                  = 0;  
  parameter [0:5] Reserved_Bits_Extendido             = 1;
  parameter [0:5] Reserved_Bit_Normal                 = 2;
  parameter [0:5] Identificador_A 		               = 3;
  parameter [0:5] Identificador_B      		         = 4;
  parameter [0:5] RTR_Extendido                       = 5;
  parameter [0:5] Start_Frame 		                  = 6;
  parameter [0:5] Length_Data_Field                   = 7;
  parameter [0:5] Doubt_Bits		                     = 8;
  parameter [0:5] Data_Frame                          = 9;
  parameter [0:5] CRC_Frame                           = 10;
  parameter [0:5] ACK_Frame                           = 11;
  parameter [0:5] ConClusao                           = 12;  
  parameter [0:5] Ocioso        		                  = 13;
  parameter [0:5] Stuffing_Check                      = 14;
  parameter [0:5] Stuffing_Bit                        = 15;
  parameter [0:5] Stuffing_Error                      = 16;
  parameter [0:5] CRC_Delimiter                       = 17;
  parameter [0:5] ACK_Delimiter                       = 18;
  parameter [0:5] Form_Error                          = 19;
  parameter [0:5] Passive_Error                       = 20;
  parameter [0:5] Active_Error 								= 21;
  parameter [0:5] Error_Frame							      = 22;
  parameter [0:5] Overload_Frame 							= 23;
  parameter [0:5] Waiting 									   = 24;
  parameter [0:5] Reseta_Variaveis						   = 25;
  parameter [0:5] End_Of_Frame                        = 26;
  //Variaveis temporarias para guardar Estados
  reg [0:5]    Redirecionando       = Identificador_A;
  reg [0:5]    Estado               = Inicio;
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
  //Variavel setada pelo gerador
  parameter CLKS_PER_BIT = 10; //Essa variavel esta setada pelo tb.v 
  //Variaveis 
  reg [0:31] Length_count              = 0;
  reg [0:31] Bit_Index                 = 0;
  reg [0:31] New_Jump                  = 0;
  reg [0:31] Clock_Count               = 0;
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
  //Fios
  wire form_monitor;
  wire CRC_monitor;

  
  	can_form_error #(.form_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_FORM_ERROR_INST
  (.i_Clock(i_Clock),
   .i_frame_field(Estado),
   .i_Data(Data_Bit),
   .o_form_monitor(form_monitor)
   );

	can_crc_checker #(.crc_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_CRC_CHECKER_INST
	(.i_Clock(i_Clock),
	 .i_frame_field(Estado),
	 .i_Data(Data_Bit),
	 .o_CRC_monitor(CRC_monitor)
	 );

  always @(posedge i_Clock)
    begin
      Data_Bit  <= i_Rx_Serial;
    end



  always @(posedge i_Clock)
    begin
	  case (Estado)
	   //-------------------------------------------------------------------------
      Inicio:
      begin
			if (Data_Bit == 1'b0)        
				begin
					if((Clock_Count < (CLKS_PER_BIT/2)-1))
						Clock_Count <= Clock_Count + 1;
					else
					begin
						Clock_Count <= 0; 
						Estado  <= Reseta_Variaveis;
					end
				end
         else
				Estado  <= Inicio;
      end
		//-------------------------------------------------------------------------
		Reseta_Variaveis:
		begin
			Clock_Count <= Clock_Count +1;
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
			Bit_Index                           <= 0;
			New_Jump                            <= 0;
			Count_Interframe                    <= 0;
			Count_Overload                      <= 0;
			Length_count                        <= 0;
			Stuffing_ON                         <= 1;
			Estado <= Start_Frame;
		end
		//-------------------------------------------------------------------------
		Start_Frame:
      begin
			//$strobe("Start = %d",Data_Bit);
			Clock_Count <= Clock_Count +1;
			Vector_Frame[Bit_Index] <= Data_Bit; 
			Bit_Index <= Bit_Index + 1;
         Estado <= Stuffing_Check;
		end
	   //-------------------------------------------------------------------------
		Stuffing_Check:
		begin 
			 if (Clock_Count < CLKS_PER_BIT-1)
				Clock_Count <= Clock_Count + 1'b1;
			 else
			 begin
				Clock_Count <=0;
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
		 end
		//-------------------------------------------------------------------------
		Identificador_A:
		begin
			//$display("ID_A = %d",Data_Bit);
			//$stop;
			Clock_Count <= Clock_Count+1;  
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
			Clock_Count <= Clock_Count+1;  
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < 13)
			begin
				if(form_monitor==1)
					SRR_ERROR<=1;
				Redirecionando   <= Doubt_Bits;
			end
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
			Clock_Count <= Clock_Count+1;  
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
			Clock_Count <= Clock_Count+1;  
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
			RTR_BIT <= Data_Bit;
			Redirecionando   <= Reserved_Bits_Extendido;
			Estado <= Stuffing_Check;
		end   
		//-------------------------------------------------------------------------
		Reserved_Bits_Extendido:
		begin
			if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1;  
			else
			begin
				 Clock_Count         <= Clock_Count+1;  
				 Bit_Index <= Bit_Index + 1'b1; 
				 //Warnings
				 if(Data_Bit==1&&Bit_Index==33)
					 Reserved_R0_Warning <=1;
				 if(Data_Bit==1&&Bit_Index==34)
					 Reserved_R1_Warning <=1;
				 //Warnings
				 if (Bit_Index < 34)
					Redirecionando   <= Reserved_Bits_Extendido;
				 else
             begin  
				    New_Jump <= 34;
					 Redirecionando   <= Length_Data_Field;
             end
				 Estado <= Stuffing_Check;
         end 
		end 
		//-------------------------------------------------------------------------
		Reserved_Bit_Normal:
		begin
			
			if(Clock_Count==0)
			begin
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
				//$display("Res_Norma = %d",Data_Bit);
			end
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1;  
			else
			begin
			
				if(Data_Bit==1)  
					Reserved_Bit_Normal_Warning =1;
				
			   Clock_Count         <= Clock_Count+1;
				Bit_Index <= Bit_Index + 1'b1; 
				Redirecionando   <= Length_Data_Field;
				Estado <= Stuffing_Check;
				New_Jump <= 14;
				RTR_BIT <= Vector_Frame[12];
			end  
		end 
		//-------------------------------------------------------------------------  
		Length_Data_Field:
		begin
			//$display("LENG = %d",Data_Bit);
			Clock_Count         <= Clock_Count+1;  
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
				begin
					Data_Length_ERROR <= 1;
					Length_Data<=8;
				end
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
			Clock_Count         <= Clock_Count+1;  
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
			Clock_Count         <= Clock_Count+1;  
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < New_Jump+15)
				Redirecionando   <= CRC_Frame;
			else
			begin
				Redirecionando   <= CRC_Delimiter;
			end
			Estado <= Stuffing_Check;
		end 
		//------------------------------------------------------------------------- 
		CRC_Delimiter:
		begin
			if(CRC_monitor==1)
				CRC_Comp_ERROR=1;
		   Stuffing_ON=0;
			if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1; 		
			else
			begin
				Clock_Count         <= Clock_Count+1; 
				Bit_Index <= Bit_Index + 1'b1;   	
				if(form_monitor==1)
					CRC_Delimiter_ERROR<=1;
				Redirecionando   <= ACK_Frame;
				Estado <= Stuffing_Check;
			end
		end 
		//-------------------------------------------------------------------------
		ACK_Frame:
		begin
			Clock_Count         <= Clock_Count+1; 
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1; 	
			Redirecionando   <= ACK_Delimiter;
			Estado <= Stuffing_Check;   
		end
		//-------------------------------------------------------------------------
		ACK_Delimiter:
		begin
			if(Clock_Count==0)
			begin
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			end
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1;  
			else
			begin
				Clock_Count         <= Clock_Count+1;
				Bit_Index <= Bit_Index + 1'b1;
				if(form_monitor==1)
					ACK_Delimiter_ERROR<=1;
				Redirecionando   <= End_Of_Frame;
				Estado <= Stuffing_Check;					
         end    
		 end 
		//-------------------------------------------------------------------------    
		End_Of_Frame:
		begin
		   if(Clock_Count==0)
			begin
				Vector_Frame[Bit_Index] <= Data_Bit;
				//$display("End = %d",Data_Bit);
			end
			if(Clock_Count<3)
				Clock_Count <= Clock_Count + 1;
			else
			begin
				Clock_Count <= Clock_Count + 1;
				Bit_Index <= Bit_Index + 1'b1;
				if(form_monitor==1)
					EOF_ERROR=1;
				if (Bit_Index < New_Jump+25)
				begin
					Redirecionando <= End_Of_Frame;
					Estado <= Stuffing_Check;
				end
				else
					Estado <= ConClusao;
			end 
		end
		//------------------------------------------------------------------------- 
		ConClusao:
		begin
			 Clock_Count <= Clock_Count + 1;
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
			 //Erros E warnings
			 if (CRC_Delimiter_ERROR == 1)
				$write("//*Form Error -> CRC Delimiter*//");
			 if (ACK_Delimiter_ERROR == 1)
			 	$write("//*Form Error -> ACK Delimiter*//");
			 if (CRC_Comp_ERROR == 1)
				$write("//*Falha na Comparacao de seguranca -> CRC*//");
			 if (Data_Length_ERROR==1)
				$write("//*Tamanho Invalido (>8) -> Tamanho considerado = 8*//");
			 if (SRR_ERROR==1)
				$write("//*Form Error -> SRR Bit*//");
			 if (Reserved_R0_Warning==1)
				$write("//*Warning --> Reserved bit R0*//");
			 if (Reserved_R1_Warning==1)
				$write("//*Warning --> Reserved bit R1*//");
			 if (Reserved_Bit_Normal_Warning==1)
				$write("//*Warning --> Reserved bit R0*//");
			 if (EOF_ERROR==1)
				$write("//*Form Error -> End Of Frame*//");
			 $display("/-->End<--//");
			 Estado <= Stuffing_Check;
			 Redirecionando <= Waiting;
		  end
		//-------------------------------------------------------------------------
		Waiting:
		begin
			Clock_Count <= Clock_Count + 1;
			Estado <= Stuffing_Check;
			if(Data_Bit==1)
			begin
				Count_Interframe<=Count_Interframe+1;
				Redirecionando <= Waiting;
			end
			else
			begin
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
			Clock_Count <= Clock_Count + 1;
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
			Clock_Count <= Clock_Count + 1;
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
			//$display("AKI");
			Clock_Count <= Clock_Count + 1;
			Estado <= Stuffing_Check;
			Redirecionando <= Active_Error;
			if(Data_Bit==1)
				Count_ActiveError<=Count_ActiveError+1;
			if(Count_ActiveError==7)
			begin
				$display("ACTIVE ERROR FRAME");
				Redirecionando <= Waiting;
			end
		end
		//-------------------------------------------------------------------------
		Passive_Error:
		begin
			Clock_Count <= Clock_Count + 1;
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