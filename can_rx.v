`include "can_form_error.v"

module can_rx(input i_Clock,input i_Rx_Serial,input i_Erro_Flag,input i_Ignora_bit,output o_Rx_DV,output [0:499] o_Rx_Byte);
   
  parameter Inicio        		                  = 5'b00000;  
  parameter Reserved_Bits_Extandard             = 5'b00001;
  parameter Reserved_Bit_Normal                 = 5'b00010;
  parameter Identificador_A 		               = 5'b00011;
  parameter Identificador_B      		         = 5'b00100;
  parameter End_Of_Frame                        = 5'b00101;
  parameter Start_Frame 		                  = 5'b00110;
  parameter Length_Data_Field                   = 5'b00111;
  parameter DoubtBits		                     = 5'b01000;
  parameter Data_Frame                          = 5'b01001;
  parameter CRC_Frame                           = 5'b01010;
  parameter ACK_Frame                           = 5'b01011;
  parameter ConClusao                           = 5'b01100;  
  parameter Ocioso        		                  = 5'b01101;
  parameter Stuffing_Check                      = 5'b01110;
  parameter Stuffing_Bit                        = 5'b01111;
  parameter Stuffing_Error                      = 5'b10000;
  parameter CRC_Delimiter                       = 5'b10001;
  parameter ACK_Delimiter                       = 5'b10010;
  parameter Form_Error                          = 5'b10011;
  parameter RTR_Extandard                       = 5'b10100;

  parameter Passive_Error                       = 5'b10101;
  parameter Active_Error 								= 5'b10110;
  parameter Error_Frame							      = 5'b10111;
  parameter Overload_Frame 							= 5'b11000;
  parameter Waiting 									   = 5'b11001;
  
  parameter SOF_ERROR						= 3'b000;
  parameter CRC_Delimiter_ERROR			= 3'b001;
  parameter ACK_Delimiter_ERROR			= 3'b010;
  parameter EOF_ERROR						= 3'b011;
  
  parameter CLKS_PER_BIT = 10; //Essa variavel esta setada pelo tb.v 
  
  //reg	[0:2]		ERROR						= 3'b111;
  //reg	[0:4]		FLAG_Frame_Final		= 5'b0;
  reg [0:4]    Redirecionando       = 3;
  reg [0:4]    Estado               = 0;
  

  integer Bit_Index                 = 0;
  integer New_Jump                  = 0;
  integer Clock_Count               = 0;
  integer Count_Interframe          = 0;
  integer Count_Overload            = 0;
  integer Count_ActiveError         = 0;
  integer Count_PassiveError        = 0;
  
  
  reg [0:3]     Length_Data         = 0;  //Precisa ser Vetor
  reg           Stuffing_ON         = 1;
  reg           RTR_BIT             = 1;
  reg           Data_Bit_Duplicated = 1;
  reg           Data_Bit            = 1;
  reg           r_Rx_DV             = 0;
  reg [0:107]   Vector_Frame        = 0;
  
  wire form_monitor=0;
  
  	can_form_error #(.form_CLKS_PER_BIT(CLKS_PER_BIT)) CAN_FORM_ERROR_INST
  (.i_Clock(i_Clock),
   .i_frame_field(Estado),
   .i_Data(Data_Bit),
   .o_form_monitor(form_monitor)
   );


  always @(posedge i_Clock)
    begin
      Data_Bit_Duplicated <= i_Rx_Serial;
      Data_Bit   <= Data_Bit_Duplicated;
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
						Estado  <= Start_Frame;
					end
				end
            else
              Estado  <= Inicio;
          end
		//-------------------------------------------------------------------------
		Start_Frame:
      begin
			Clock_Count <= Clock_Count +1; 
			Redirecionando            = 3;
			Count_PassiveError        = 0;
			Count_ActiveError         = 0;
			Bit_Index                 = 0;
			New_Jump                  = 0;
			Clock_Count               = 0;
			Count_Interframe          = 0;
			Count_Overload            = 0;
			Stuffing_ON               = 1;
			Vector_Frame[Bit_Index] <= Data_Bit; 
			Bit_Index <= Bit_Index + 1;
			//$display("Vector Processed: Start ");
         Estado <= Stuffing_Check;
		end
	   //-------------------------------------------------------------------------
		 Stuffing_Check:
		   begin 
			
			 if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Stuffing_Check;
              end
			 else
			 begin
				//$display("V = %d",Data_Bit);
				Clock_Count <=0;
				if(Stuffing_ON==1)
				begin
					if(i_Erro_Flag==1)
						Estado=Error_Frame;	
					else if(i_Ignora_bit==1)
						Estado=Stuffing_Check;
					else
						Estado <= Redirecionando;
				end
				else
					Estado <= Redirecionando;
			 end
		  end

		//-------------------------------------------------------------------------//(OK)
		Identificador_A:
		begin
			Clock_Count <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1;	 
			
         if (Bit_Index < 12)
         begin 
				Redirecionando   <= Identificador_A;
				Estado <= Stuffing_Check;
         end
			else
         begin  
						
				//$display("Vector Processed: Identifcador A ");
            Redirecionando   <= DoubtBits;
				Estado <= Stuffing_Check;
         end  
		end 
		//-------------------------------------------------------------------------//(OK)
		DoubtBits:
		begin
			Clock_Count <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < 14)
         begin
				Redirecionando   <= DoubtBits;
				Estado <= Stuffing_Check;
         end
			else
         begin  
				//$display("Vector Processed: DoubtBits Vector");
				if(Vector_Frame[13]== 0)
				begin
					Redirecionando   <=  Reserved_Bit_Normal;
					Estado <= Stuffing_Check;
				end  
				else
				begin
					Redirecionando   <=  Identificador_B;
					Estado <= Stuffing_Check;
				end  
			end    
		end 
		//-------------------------------------------------------------------------//(OK)
		Identificador_B:
		begin
			Clock_Count <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1; 
         if (Bit_Index < 32)
         begin
             Redirecionando   <= Identificador_B;
				 Estado = Stuffing_Check;
         end
			else
         begin  
				//$display("Vector Processed: Identifcador B ");
            Redirecionando   <= RTR_Extandard; //Reserved_Bits_Extandard;
				Estado <= Stuffing_Check;
         end
              
		end   
		//-------------------------------------------------------------------------//(OK)
		RTR_Extandard:
		begin
			Clock_Count <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
			New_Jump <= 35;
			RTR_BIT <= Vector_Frame[32];
			//$display("Vector Processed: RTR_Extandard");
			Redirecionando   <= Reserved_Bits_Extandard;
			Estado <= Stuffing_Check;
		end   
		//-------------------------------------------------------------------------//(OK)
		Reserved_Bits_Extandard:
		begin
			if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1;  
			else
			begin
				 Clock_Count         <= Clock_Count+1;  // SERA ?
				 Bit_Index <= Bit_Index + 1'b1; 
				 if(form_monitor==1)
					$display("Warning");
				 if (Bit_Index < 35)
             begin
					Redirecionando   <= Reserved_Bits_Extandard;
					Estado <= Stuffing_Check;
             end
				 else
             begin  
				    New_Jump <= 35;
				    RTR_BIT <= Vector_Frame[32];
					 //$display("Vector Processed: Reserved_Bits_Extandard");
					 Redirecionando   <= Length_Data_Field;
					 Estado <= Stuffing_Check;
             end
         end 
		end 
		//-------------------------------------------------------------------------//(OK)
		Reserved_Bit_Normal:
		begin
			if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1;  
				
			else
			begin
			   Clock_Count         <= Clock_Count+1;
				Bit_Index <= Bit_Index + 1'b1; 
				if(form_monitor==1)
					$display("Warning");
				Redirecionando   <= Length_Data_Field;
				Estado <= Stuffing_Check;
				New_Jump <= 15;
				RTR_BIT <= Vector_Frame[12];
				//$display("Vector Processed: Reserved_Bit_Normal");
			end  
		end 
		//-------------------------------------------------------------------------//(OK)  
		Length_Data_Field:
		begin
			Clock_Count         <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < New_Jump+4)
         begin
				Redirecionando   <= Length_Data_Field;
				Estado <= Stuffing_Check;
         end
			else
         begin  
				New_Jump <= New_Jump+4;
				Estado <= Stuffing_Check;
				//$display("Vector Processed: Length_Data_Field");
				if(RTR_BIT==0)
					Redirecionando   <=  Data_Frame;
				else
					Redirecionando   <=  CRC_Frame;
         end   
		end 
		//-------------------------------------------------------------------------//(OK)    
		Data_Frame:
		begin
			Clock_Count         <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;	
			Length_Data[0] = Vector_Frame[New_Jump-4]; 
			Length_Data[1] = Vector_Frame[New_Jump-3]; 
			Length_Data[2] = Vector_Frame[New_Jump-2]; 
			Length_Data[3] = Vector_Frame[New_Jump-1]; 
			//$display("Tamanho: %d",Length_Data);
         if (Bit_Index < New_Jump+(Length_Data*8))
			begin
				Redirecionando   <= Data_Frame;
				Estado <= Stuffing_Check;
         end
			else
         begin  
			   //$display("Tamanho: %d",Length_Data);
				New_Jump <= New_Jump+(Length_Data*8);
				//$display("Vector Processed: Data_Frame");
				Redirecionando   <= CRC_Frame;
				Estado <= Stuffing_Check;
         end
		end 
		//-------------------------------------------------------------------------//(OK)    
		CRC_Frame:
		begin
			Clock_Count         <= Clock_Count+1;  // SERA ?
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1;
         if (Bit_Index < New_Jump+14)
         begin
				Redirecionando   <= CRC_Frame;
				Estado <= Stuffing_Check;
         end
			else
         begin  
				//$display("Vector Processed: CRC_Frame");
				Redirecionando   <= CRC_Delimiter;
				Estado <= Stuffing_Check;
         end  
		end 
		//-------------------------------------------------------------------------//(OK)  
		CRC_Delimiter:
		begin
		   Stuffing_ON=0;
			if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
			if(Clock_Count<3)                         //delay 3 clocks
            Clock_Count         <= Clock_Count+1; 		
			else
			begin
				Clock_Count         <= Clock_Count+1; 
				Bit_Index <= Bit_Index + 1'b1;   	
			   if(form_monitor==0)
				begin
					//$display("Vector Processed: CRC_Delimiter");
					Redirecionando   <= ACK_Frame;
					Estado <= Stuffing_Check;
				end
				else
				begin
					$display("CRC Delimiter Error");
					//ERROR <= CRC_Delimiter_ERROR;
					Estado <= Form_Error;
				end
			end
		end 
		//-------------------------------------------------------------------------//(OK)
		ACK_Frame:
		begin
			Clock_Count         <= Clock_Count+1; 
         Vector_Frame[Bit_Index] <= Data_Bit;
			Bit_Index <= Bit_Index + 1'b1; 
			//$display("Vector Processed: ACK_Frame");	
			Redirecionando   <= ACK_Delimiter;
			Estado <= Stuffing_Check;   

		end
		//-------------------------------------------------------------------------//(OK)
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
				if(form_monitor == 0)
				begin									
					//$display("Vector Processed: ACK_Delimiter");
					Redirecionando   <= End_Of_Frame;
					Estado <= Stuffing_Check;					
				end
				else
				begin
					$display("ACK Delimiter Error");
					//ERROR <= ACK_Delimiter_ERROR;
					Estado <= Form_Error;
				end
         end    
		 end 
		//-------------------------------------------------------------------------//(OK)    
		End_Of_Frame:
		begin
		   if(Clock_Count==0)
				Vector_Frame[Bit_Index] <= Data_Bit;
			if(Clock_Count<3)
				Clock_Count <= Clock_Count + 1;
			else
			begin
				Clock_Count <= Clock_Count + 1;
				Bit_Index <= Bit_Index + 1'b1;
				if(form_monitor == 0)
				begin
					if (Bit_Index < New_Jump+24)
					begin
						Redirecionando <= End_Of_Frame;
						Estado <= Stuffing_Check;
					end
					else
					begin  
						//$display("Vector Processed: End_Of_Frame");
						Estado <= ConClusao;
						//Stuffing_ON==1;
					end
				
				end
				else
				begin
					$display("EOF Error");
					Estado <= Form_Error;
				end
				
			end 
		end
		//------------------------------------------------------------------------- 
		ConClusao:
		begin
			 Clock_Count <= Clock_Count + 1;
		    if(Vector_Frame[13]==0)
			 begin
				if(Vector_Frame[12]==0)
				begin
					$display("DATA FRAME NORMAL, %d Bytes de dados, Tamanho de Frame = %d Bits",Length_Data,Bit_Index-1);
				end
			   else
				begin
					$display("REMOTE FRAME NORMAL,Tamanho de Frame = %d Bits",Bit_Index-1);
				end
			 end
			 else
			 begin
			 	if(Vector_Frame[32]==0)
				begin
					$display("DATA FRAME EXTENDED, %d Bytes de dados, Tamanho de Frame = %d Bits",Length_Data,Bit_Index-1);
				end
			   else
				begin
					$display("REMOTE FRAME EXTENDED,Tamanho de Frame = %d Bits",Bit_Index-1);
				end
			 end
			 //$display("Vector: %b",Vector_Frame);
			 Estado <= Stuffing_Check;
			 Redirecionando = Waiting;
		  end
		//-------------------------------------------------------------------------
		Waiting:
		begin
			//$display("%d",Data_Bit);
			Clock_Count <= Clock_Count + 1;
			Estado = Stuffing_Check;
			if(Data_Bit==1)
			begin
				Count_Interframe=Count_Interframe+1;
				Estado = Stuffing_Check;
				Redirecionando = Waiting;
			end
			else
			begin
				if(Count_Interframe!=0)
				begin
					$display("INTERFRAME (%d)",Count_Interframe);
					Estado=Start_Frame;
				end
				else
				begin
					Estado=Overload_Frame;
				end
				Count_Interframe=0;
			end
		end
		//-------------------------------------------------------------------------	
		Overload_Frame:
		begin
			Estado = Stuffing_Check;
			Redirecionando =Overload_Frame;
			Clock_Count <= Clock_Count + 1;
			if(Data_Bit==1)
				Count_Overload=Count_Overload+1;
			if(Count_Overload==8)
			begin
				$display("OVERLOAD FRAME");
				Estado = Stuffing_Check;
				Redirecionando = Waiting;
				Count_Overload=0;
				Count_Interframe=0;
			end
		end
		//-------------------------------------------------------------------------			
		Error_Frame:
		begin
			Count_ActiveError=0;
			Count_PassiveError=0;
			Stuffing_ON=0;
			Estado = Stuffing_Check;
			if(Data_Bit==0)
				Redirecionando = Active_Error;
			else
				Redirecionando = Passive_Error;
		end
		//-------------------------------------------------------------------------	
		Active_Error:
		begin
			Estado = Stuffing_Check;
			Redirecionando = Active_Error;
			if(Data_Bit==1)
				Count_ActiveError=Count_ActiveError+1;
			if(Count_ActiveError==8)
			begin
				$display("ACTIVE ERROR FRAME");
				Redirecionando = Waiting;
			end
		end
		//-------------------------------------------------------------------------
		Passive_Error:
		begin
			Estado = Stuffing_Check;
			Redirecionando = Passive_Error;
			if(Data_Bit==1)
				Count_PassiveError=Count_PassiveError+1;
			if(Count_PassiveError==8)
			begin
				$display("PASSIVE ERROR FRAME");
				Redirecionando = Waiting;
			end
		end
		
		
		
		/*Form_Error:
		begin
			$display("ERRO");
			if (ERROR == SOF_ERROR)
				$display("Form Error in Start of Frame! Bit_Index = %d", Bit_Index);
			else if (ERROR == CRC_Delimiter_ERROR)
				$display("Form Error in CRC Delimiter! Bit_Index = %d", Bit_Index);
			else if (ERROR == ACK_Delimiter_ERROR)
				$display("Form Error in ACK Delimiter! Bit_Index = %d", Bit_Index);
			else if (ERROR == EOF_ERROR)
				$display("Form Error in End of Frame! Bit_Index = %d", Bit_Index);
		   //$display("ERROR,Bit_index = %d",Bit_Index);
			$display("VECTOR = %b",Vector_Frame);
			Estado <= Ocioso;
		end*/
		//-------------------------------------------------------------------------
		 /*Interframe:
		 begin
			 if(Clock_Count==0)
				begin
					//$stop;
					Vector_Frame[Bit_Index] <= Data_Bit;   //pega a informação imediatamente
				end
				if(Clock_Count<3)                         //delay 3 clocks
					Clock_Count         <= Clock_Count+1;  
				else
				begin
					Clock_Count         <= Clock_Count+1;
					Bit_Index <= Bit_Index + 1'b1;
					if (Bit_Index < New_Jump+27)
						Redirecionando <= Interframe;
					else
					begin  
						$display("Vector Processed: Interframe.");
						$display("Vector: %b",Vector_Frame);
						Redirecionando <= Ocioso; //Na vdd seria para o case 'Inicio'
						//$stop;
					end
					Estado <= Stuffing_Check;				
				end
		 end*/
	    //------------------------------------------------------------------------- 
		 Ocioso:
		  begin
		     //$display("FORM %d",form_monitor);
			  Estado   <= Ocioso;
		  end 
		  
	    //-------------------------------------------------------------------------  
      endcase
    end   
	assign o_Rx_DV   = r_Rx_DV;
	assign o_Rx_Byte = Vector_Frame;
  endmodule // can_rx	