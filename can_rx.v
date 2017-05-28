//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter Clocks_Bit as follows:
// Clocks_Bit = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module can_rx(input i_Clock,input i_Rx_Serial,output o_Rx_DV,output [0:108] o_Rx_Byte);
   
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
  
  parameter CLKS_PER_BIT = 10; //Essa variavel esta setada pelo tb.v 
  
  reg [0:4]    Redirecionando       = 3;
  reg [0:4]    Estado               = 0;
  
  integer Bit_Stuffing              = 1;
  integer Bit_Index                 = 0;
  integer New_Jump                  = 0;
  integer Length_Data               = 0;
  
  reg           Stuffing_ON         = 1;
  reg           RTR_BIT             = 1;
  reg           Data_Bit_Duplicated = 1;
  reg           Data_Bit            = 1;
  reg           TempStuffing        = 0;
  reg           r_Rx_DV             = 0;
  reg [0:63]    Clock_Count         = 0;
  reg [0:110]   Vector_Frame        = 0;
  

  
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
			   Stuffing_ON    <= 1;
			   Redirecionando <= 3;
			   Bit_Stuffing   <= 1;
            r_Rx_DV        <= 1'b0;
            Clock_Count    <= 0;
            Bit_Index      <= 0;
            if (Data_Bit == 1'b0)          // Start bit detected
				begin
              Estado  <= Start_Frame;
				  TempStuffing=Data_Bit;
				end
            else
              Estado  <= Inicio;
          end
		//-------------------------------------------------------------------------
		Start_Frame:
          begin
            if (Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (Data_Bit == 1'b0)
                  begin
                    Clock_Count <= 0;  // reset counter, found the middle
					     Vector_Frame[Bit_Index] <= Data_Bit; //
						  //$display("Start -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index+1,Vector_Frame[Bit_Index] ,Vector_Frame);
					     Bit_Index <= Bit_Index + 1;
						  $display("Startt -> Vetor = %b",Vector_Frame);
                    Estado     <= Stuffing_Check;//mudado
                  end
                else
                  Estado <= Inicio;
              end
            else
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Start_Frame;
              end
          end 
	    //-------------------------------------------------------------------------
		 Stuffing_Check:
		    begin 
			  if(Stuffing_ON==1)
			   begin
				
				
		        if(Bit_Stuffing==0)
			     begin
			       Estado     <= Redirecionando;
			 	    Bit_Stuffing=1;
			     end
			     else
				  begin
				    if(TempStuffing!=Data_Bit)
				      Bit_Stuffing=1;
				    else
				      Bit_Stuffing=Bit_Stuffing+1;
				    if(Bit_Stuffing==5)
				      Estado     <= Stuffing_Bit;
				    else
					   Estado     <= Redirecionando;
				    TempStuffing=Data_Bit;
				  end
			   end
			   else
			   begin
				  Estado <= Redirecionando;
			   end
		    end
		 //-------------------------------------------------------------------------
		 Stuffing_Bit:
		 begin
			if (Clock_Count < CLKS_PER_BIT-1)
            begin
              Clock_Count <= Clock_Count + 1'b1;
              Estado     <= Identificador_A;
            end
	    	else
			begin
			  if(TempStuffing==Data_Bit)
			    Estado     <= Stuffing_Error;
			  else
			  begin
			     Clock_Count <=0;
				  Estado     <= Redirecionando;
			  end
			end
		 end
		 //-------------------------------------------------------------------------
		 Stuffing_Error:
		 begin
			$display("STUFFING ERROR");
		 end
		 //-------------------------------------------------------------------------
		 Identificador_A:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Identificador_A;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("ID_A -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < 12)
                  begin 
                    Redirecionando   <= Identificador_A;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
						  $display("ID_A Vetor = %b",Vector_Frame);
                    Redirecionando   <= DoubtBits;
						  Estado = Stuffing_Check;
                  end
              end
		  end // case: s_RX_IDENTIFIER_BITS
		//-------------------------------------------------------------------------
		DoubtBits:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= DoubtBits;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("Doubt -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < 14)
                  begin
                    Redirecionando   <= DoubtBits;
						  Estado = Stuffing_Check;
                  end
				else
              begin  
				  
					if(Vector_Frame[13]== 0)
					  begin
					    $display("Reserved Normal -> Vetor = %b",Vector_Frame);
					    Redirecionando   <=  Reserved_Bit_Normal;
						 Estado = Stuffing_Check;
					  end  
					else
					  begin
						 $display("ID_ B -> Vetor = %b",Vector_Frame);
					    Redirecionando   <=  Identificador_B;
						 Estado = Stuffing_Check;
					  end  
				  end
            end
		  end 
		//------------------------------------------------------------------------- 
		Identificador_B:
		  begin
			if (Clock_Count <CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Identificador_B;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("ID_B -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < 32)
                  begin
                    Redirecionando   <= Identificador_B;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
						  $display("Vetor = %b",Vector_Frame);
                    Redirecionando   <= Reserved_Bits_Extandard;
						  Estado = Stuffing_Check;
                  end
              end
		  end   
		//-------------------------------------------------------------------------
		Reserved_Bits_Extandard:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Reserved_Bits_Extandard;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("Reserved_ex -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < 35)
                  begin
                    Redirecionando   <= Reserved_Bits_Extandard;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
				    New_Jump = 35;
				    RTR_BIT <= Vector_Frame[32];
					 $display("Vetor = %b",Vector_Frame);
					 Redirecionando   <= Length_Data_Field;
					 Estado = Stuffing_Check;
                  end
              end
		  end 
		//-------------------------------------------------------------------------
		Reserved_Bit_Normal:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Reserved_Bit_Normal;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;  // Precisa Ser Recessivo
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("Reserved_Norm -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < 15)
                  begin
                    Redirecionando   <= Reserved_Bit_Normal;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
				    New_Jump = 15;
				    RTR_BIT <= Vector_Frame[12];
					 $display("Reserved Bits -> Vetor = %b",Vector_Frame);
					 Redirecionando   <= Length_Data_Field;
					 Estado = Stuffing_Check;
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		Length_Data_Field:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Length_Data_Field;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("Legth_Data -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < New_Jump+4)
                  begin
                    Redirecionando   <= Length_Data_Field;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
					if(RTR_BIT==0)
					  begin
						New_Jump <= New_Jump+4;
						$display("Length -> Vetor = %b",Vector_Frame);
					   Redirecionando   <=  Data_Frame;
						Estado = Stuffing_Check;
					  end  
					else
					  begin
					    New_Jump <= New_Jump+ 4;
						 $display("Length -> Vetor = %b",Vector_Frame);
					    Redirecionando   <=  CRC_Frame;
						 Estado = Stuffing_Check;
					  end  
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		Data_Frame:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= Data_Frame;
              end
	    	else
              begin
                Clock_Count          <= 1'b0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
					 //strobe("Data -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
					 Length_Data[0] = Vector_Frame[New_Jump-4]; 
					 Length_Data[1] = Vector_Frame[New_Jump-3]; 
					 Length_Data[2] = Vector_Frame[New_Jump-2]; 
					 Length_Data[3] = Vector_Frame[New_Jump-1]; 
					 
                if (Bit_Index < New_Jump+(Length_Data*8))
                  begin
                    Redirecionando   <= Data_Frame;
						  Estado = Stuffing_Check;
                  end
				  else
                  begin  
				      New_Jump <= New_Jump+(Length_Data*8);
						$display("Vetor = %b",Vector_Frame);
					   Redirecionando   <= CRC_Frame;
						Estado = Stuffing_Check;
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		CRC_Frame:
		  begin
		   Stuffing_ON=0;
			if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= CRC_Frame;
              end
	    	else
              begin
                Clock_Count          <= 1'b0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("CRC -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < New_Jump+16)
                  begin
                    Redirecionando   <= CRC_Frame;
						  Estado = Stuffing_Check;
                  end
				    else
                  begin  
						$display("Vetor = %b",Vector_Frame);
					Redirecionando   <= ACK_Frame;
					Estado = Stuffing_Check;
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		ACK_Frame:
		  begin
			if (Clock_Count < CLKS_PER_BIT-0)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= ACK_Frame;
              end
	    	else
              begin
                Clock_Count          <= 0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("ACK -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < New_Jump+18)
                  begin
                    Redirecionando   <= ACK_Frame;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
						$display("Vetor = %b",Vector_Frame);
					Redirecionando   <= End_Of_Frame;
					Estado = Stuffing_Check;
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		End_Of_Frame:
		  begin
			if (Clock_Count < CLKS_PER_BIT-1'b1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
                Estado     <= End_Of_Frame;
              end
	    	else
              begin
                Clock_Count          <= 1'b0;
                Vector_Frame[Bit_Index] <= Data_Bit;
				    Bit_Index <= Bit_Index + 1'b1;
				    //$strobe("END -> %d bits lidos, BIT = %b, Frame = %b", Bit_Index,Vector_Frame[Bit_Index-1] ,Vector_Frame);
                if (Bit_Index < New_Jump+25)
                  begin
                    Redirecionando   <= End_Of_Frame;
						  Estado = Stuffing_Check;
                  end
				else
                  begin  
						$display("Vetor END = %b",Vector_Frame);
					Redirecionando   <= ConClusao;
					Estado = Stuffing_Check;
                  end
              end
		  end 
	    //-------------------------------------------------------------------------  
		 ConClusao:
		  begin
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
			 Estado   <= Ocioso;
		  end
	    //------------------------------------------------------------------------- 
		 Ocioso:
		  begin
			  Estado   <= Ocioso;
		  end 
		  
	    //-------------------------------------------------------------------------  
      endcase
    end   
	assign o_Rx_DV   = r_Rx_DV;
	assign o_Rx_Byte = Vector_Frame;
  endmodule // can_rx	
	