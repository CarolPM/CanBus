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
   
  parameter Reserved_Bits_Extandard             = 4'b0001;
  parameter Reserved_Bit_Normal                 = 4'b0010;
  parameter Identificador_A 		               = 4'b0011;
  parameter Identificador_B      		         = 4'b0100;
  parameter End_Of_Frame                        = 4'b0101;
  parameter Start_Frame 		                  = 4'b0111;
  parameter Length_Data_Field                   = 4'b1000;
  parameter DoubtBits		                     = 4'b1001;
  parameter Data_Frame                          = 4'b1010;
  parameter CRC_Frame                           = 4'b1011;
  parameter ACK_Frame                           = 4'b1100;
  parameter Inicio        		                  = 4'b0000;  
  parameter ConClusao                           = 4'b1110;  
  parameter Ocioso        		                  = 4'b1111;  
  
  parameter CLKS_PER_BIT = 10; //Essa variavel esta setada pelo tb.v 
  
  reg           RTR_BIT             = 1'b1;
  reg           Data_Bit_Duplicated = 1'b1;
  reg           Data_Bit            = 1'b1;
  reg           r_Rx_DV             = 0;
  reg [0:3]     Estado              = 0;
  reg [0:3]     Length_Data         = 0; 
  reg [0:10]    Bit_Index           = 0; 
  reg [0:10]    New_Jump            = 0;  
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
            r_Rx_DV       <= 1'b0;
            Clock_Count <= 0;
            Bit_Index   <= 0;
            if (Data_Bit == 1'b0)          // Start bit detected
              Estado  <= Start_Frame;
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
                    Estado     <= Identificador_A;
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
                    Estado   <= Identificador_A;
                  end
				else
                  begin  
						  $display("ID_A Vetor = %b",Vector_Frame);
                    Estado   <= DoubtBits;
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
                    Estado   <= DoubtBits;
                  end
				else
              begin  
				  
					if(Vector_Frame[13]== 0)
					  begin
					    $display("Reserved Normal -> Vetor = %b",Vector_Frame);
					    Estado   <=  Reserved_Bit_Normal;
					  end  
					else
					  begin
						 $display("ID_ B -> Vetor = %b",Vector_Frame);
					    Estado   <=  Identificador_B;
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
                    Estado   <= Identificador_B;
                  end
				else
                  begin  
						  $display("Vetor = %b",Vector_Frame);
                    Estado   <= Reserved_Bits_Extandard;
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
                    Estado   <= Reserved_Bits_Extandard;
                  end
				else
                  begin  
				    New_Jump = 35;
				    RTR_BIT <= Vector_Frame[32];
					 $display("Vetor = %b",Vector_Frame);
					 Estado   <= Length_Data_Field;
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
                    Estado   <= Reserved_Bit_Normal;
                  end
				else
                  begin  
				    New_Jump = 15;
				    RTR_BIT <= Vector_Frame[12];
					 $display("Reserved Bits -> Vetor = %b",Vector_Frame);
					 Estado   <= Length_Data_Field;
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
                    Estado   <= Length_Data_Field;
                  end
				else
                  begin  
					if(RTR_BIT==0)
					  begin
						New_Jump <= New_Jump+4;
						$display("Length -> Vetor = %b",Vector_Frame);
					   Estado   <=  Data_Frame;
					  end  
					else
					  begin
					    New_Jump <= New_Jump+ 4;
						 $display("Length -> Vetor = %b",Vector_Frame);
					    Estado   <=  CRC_Frame;
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
                    Estado   <= Data_Frame;
                  end
				  else
                  begin  
				      New_Jump <= New_Jump+(Length_Data*8);
						$display("Vetor = %b",Vector_Frame);
					   Estado   <= CRC_Frame;
                  end
              end
		  end 
		//-------------------------------------------------------------------------  
		CRC_Frame:
		  begin
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
                    Estado   <= CRC_Frame;
                  end
				    else
                  begin  
						$display("Vetor = %b",Vector_Frame);
					Estado   <= ACK_Frame;
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
                    Estado   <= ACK_Frame;
                  end
				else
                  begin  
						$display("Vetor = %b",Vector_Frame);
					Estado   <= End_Of_Frame;
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
                    Estado   <= End_Of_Frame;
                  end
				else
                  begin  
						$display("Vetor END = %b",Vector_Frame);
					Estado   <= ConClusao;
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
	