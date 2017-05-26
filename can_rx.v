//////////////////////////////////////////////////////////////////////
// File Downloaded from http://www.nandland.com
//////////////////////////////////////////////////////////////////////
// This file contains the UART Receiver.  This receiver is able to
// receive 8 bits of serial data, one start bit, one stop bit,
// and no parity bit.  When receive is complete o_rx_dv will be
// driven high for one clock cycle.
// 
// Set Parameter CLKS_PER_BIT as follows:
// CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART)
// Example: 10 MHz Clock, 115200 baud UART
// (10000000)/(115200) = 87
  
module can_rx 
  //#(parameter CLKS_PER_BIT)
  (
   input        i_Clock,
   input        i_Rx_Serial,
   output       o_Rx_DV,
   output [0:107] o_Rx_Byte
   );
    
  parameter s_IDLE        		   = 4'b0000;
  parameter s_RX_START_BIT 		= 4'b0001;
  parameter s_RX_DATA_BITS 		= 4'b0010;
  parameter s_RX_STOP_BITS		   = 4'b0011;
  parameter s_CLEANUP      		= 4'b0100;
  parameter s_RX_IDENTIFIER_BITS = 4'b0101;
  parameter s_RX_RTR_BIT = 4'b0110;
  parameter s_RX_IDE_BIT = 4'b0111;
  parameter s_RX_RESERVED0_BIT = 4'b1000;
  parameter s_RX_LENGTH_BITS = 4'b1001;
  parameter s_RX_CRC_BITS = 4'b1010;
  parameter s_RX_CRC_DELIM_BIT = 4'b1011;
  parameter s_RX_ACK_BIT = 4'b1100;
  parameter s_RX_ACK_DELIM_BIT = 4'b1101;
  parameter CLKS_PER_BIT  			= 10;
   
  reg           r_Rx_Data_R = 1'b1;
  reg           r_Rx_Data   = 1'b1;
   
  reg [0:63]    r_Clock_Count = 0;
  reg [0:7]     r_Bit_Index   = 0; //256 bits total
  reg [0:107]   r_Rx_Byte     = 0;
  reg           r_Rx_DV       = 0;
  reg [0:3]     r_SM_Main     = 0;
   
  // Purpose: Double-register the incoming data.
  // This allows it to be used in the UART RX Clock Domain.
  // (It removes problems caused by metastability)
  always @(posedge i_Clock)
    begin
      r_Rx_Data_R <= i_Rx_Serial;
      r_Rx_Data   <= r_Rx_Data_R;
    end
   
   
  // Purpose: Control RX state machine
  always @(posedge i_Clock)
    begin
       
      case (r_SM_Main)
        s_IDLE :
          begin
            r_Rx_DV       <= 1'b0;
            r_Clock_Count <= 0;
            r_Bit_Index   <= 0;
             
            if (r_Rx_Data == 1'b0)          // Start bit detected
              r_SM_Main <= s_RX_START_BIT;
            else
              r_SM_Main <= s_IDLE;
          end
         
        // Check middle of start bit to make sure it's still low
        s_RX_START_BIT :
          begin
            if (r_Clock_Count == (CLKS_PER_BIT-1)/2)
              begin
                if (r_Rx_Data == 1'b0)
                  begin
                    r_Clock_Count <= 0;  // reset counter, found the middle
						  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data; //
						  r_Bit_Index <= r_Bit_Index + 1;
						  $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
						  $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                    r_SM_Main     <= s_RX_IDENTIFIER_BITS;
                  end
                else
                  r_SM_Main <= s_IDLE;
              end
            else
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_START_BIT;
              end
          end // case: s_RX_START_BIT
        
		  s_RX_IDENTIFIER_BITS :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_IDENTIFIER_BITS;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
					 
					   // Check if we have received all bits
                  if (r_Bit_Index < 11)
                    begin
                      r_SM_Main   <= s_RX_IDENTIFIER_BITS;
                    end
				      else
                    begin
                      r_SM_Main   <= s_RX_DATA_BITS;
                    end
                end
			
			  end // case: s_RX_IDENTIFIER_BITS
         
		  s_RX_RTR_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_RTR_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_IDE_BIT;
                end
			
			  end // case: s_RX_RTR_BIT
			  
		  s_RX_IDE_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_IDE_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_RESERVED0_BIT;
                end
			
			  end // case: s_RX_IDE_BIT
			  
			s_RX_RESERVED0_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_RESERVED0_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_LENGTH_BITS;
                end
			
			  end // case: s_RX_IDE_BIT
		  
		  s_RX_LENGTH_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_LENGTH_BITS;
              end
            else
              begin
                r_Clock_Count          <= 0;
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
					 r_Bit_Index <= r_Bit_Index + 1; //observar se estoura
					 $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					 $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                 
                // Check if we have received all bits
                if (r_Bit_Index < 19)
                  begin
                    r_SM_Main   <= s_RX_LENGTH_BITS;
                  end
                else
                  begin
                    r_SM_Main   <= s_RX_DATA_BITS;
                  end
              end
          end // case: s_RX_LENGTH_BITS
		
        // Wait CLKS_PER_BIT-1 clock cycles to sample serial data
        s_RX_DATA_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_DATA_BITS;
              end
            else
              begin
                r_Clock_Count          <= 0;
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
					 r_Bit_Index <= r_Bit_Index + 1; //observar se estoura
					 $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					 $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                 
                // Check if we have received all bits
                if (r_Bit_Index < 82)
                  begin
                    r_SM_Main   <= s_RX_DATA_BITS;
                  end
                else
                  begin
                    r_SM_Main   <= s_RX_CRC_BITS;
                  end
              end
          end // case: s_RX_DATA_BITS
     
	  s_RX_CRC_BITS :
          begin
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_CRC_BITS;
              end
            else
              begin
                r_Clock_Count          <= 0;
                r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
					 r_Bit_Index <= r_Bit_Index + 1; //observar se estoura
					 $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					 $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                 
                // Check if we have received all bits
                if (r_Bit_Index < 97)
                  begin
                    r_SM_Main   <= s_RX_CRC_BITS;
                  end
                else
                  begin
                    r_SM_Main   <= s_RX_CRC_DELIM_BIT;
                  end
              end
          end // case: s_RX_DATA_BITS
     
	     s_RX_CRC_DELIM_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_CRC_DELIM_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_ACK_BIT;
                end
			
			  end // case: s_RX_CRC_DELIM_BIT
			  
        s_RX_ACK_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_ACK_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_ACK_DELIM_BIT;
                end
			
			  end // case: s_RX_ACK_BIT
			  
		  s_RX_ACK_DELIM_BIT :
			  begin
				  if (r_Clock_Count < CLKS_PER_BIT-1)
                begin
                  r_Clock_Count <= r_Clock_Count + 1;
                  r_SM_Main     <= s_RX_ACK_DELIM_BIT;
                end
			  	  else
                begin
                  r_Clock_Count          <= 0;
                  r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
						r_Bit_Index <= r_Bit_Index + 1;
					   $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					   $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
                  r_SM_Main   <= s_RX_STOP_BITS;
                end
			
			  end // case: s_RX_ACK_DELIM_BIT
	  
        // Receive Stop bit.  Stop bit = 1
        s_RX_STOP_BITS :
          begin
            // Wait CLKS_PER_BIT-1 clock cycles for Stop bit to finish
            if (r_Clock_Count < CLKS_PER_BIT-1)
              begin
                r_Clock_Count <= r_Clock_Count + 1;
                r_SM_Main     <= s_RX_STOP_BITS;
              end
            else
              begin
                r_Clock_Count <= 0;
					 r_Rx_Byte[r_Bit_Index] <= r_Rx_Data;
					 r_Bit_Index <= r_Bit_Index + 1;
					 $display("Valor Data (%d)=%b", r_Bit_Index, r_Rx_Data);
					 $display("r_Bit_Index(%d)=%b", r_Bit_Index, r_Bit_Index);
					 
					 if (r_Bit_Index < 107)
                  begin
                    r_SM_Main   <= s_RX_STOP_BITS;
                  end
                else
                  begin
						   r_Rx_DV     <= 1'b1;
							r_Clock_Count <= 0;
							r_Bit_Index	<= 0;
							r_SM_Main	<= s_CLEANUP;
                  end
              end
          end // case: s_RX_STOP_BIT
     
         
        // Stay here 1 clock
        s_CLEANUP :
          begin
            r_SM_Main <= s_IDLE;
            r_Rx_DV   <= 1'b0;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
         
      endcase
    end   
   
  assign o_Rx_DV   = r_Rx_DV;
  assign o_Rx_Byte = r_Rx_Byte;
   
endmodule // can_rx