module can_crc_checker (input i_clock, input [0:5] i_frame_field,input i_Data, output o_CRC_monitor);
                             

	
	parameter crc_CLKS_PER_BIT  			= 10;
	reg [0:31] Clock_Count              = 0;
	reg [0:31] Count                    = 14;
   reg [14:0] CRC                      = 0;     
	reg Exor                            = 0;
	reg CRC_monitor                     = 0;
	


   always @(posedge i_clock) 
	begin
			
			if(Clock_Count<crc_CLKS_PER_BIT-1)
				Clock_Count<=Clock_Count+1;
		   else
			begin
				//$write("%d ",i_frame_field);
				if(i_frame_field==19)
				begin
					CRC<=0;
					CRC_monitor<=0;
					Count<=14;
				end
				if(i_frame_field>=0&&i_frame_field<8)
				begin
					//$write("%d",i_Data);
					Exor = i_Data ^ CRC[14];
					CRC[14] = CRC[13] ^ Exor;
					CRC[13] = CRC[12];
					CRC[12] = CRC[11];
					CRC[11] = CRC[10];
					CRC[10] = CRC[9] ^ Exor;
					CRC[9] = CRC[8];
					CRC[8] = CRC[7] ^ Exor;
					CRC[7] = CRC[6] ^ Exor;
					CRC[6] = CRC[5];
					CRC[5] = CRC[4];
					CRC[4] = CRC[3] ^ Exor;
					CRC[3] = CRC[2] ^ Exor;
					CRC[2] = CRC[1];
					CRC[1] = CRC[0];
					CRC[0] = Exor;
					Clock_Count<=0;
				end
				if(i_frame_field==8)
				begin
					//$display("CRC -> %b",CRC);
					if(CRC[Count]!=i_Data)
						CRC_monitor<=1;
					Clock_Count<=0;
					Count<=Count-1;
				end				
			end
	
   end
		
	assign o_CRC_monitor = CRC_monitor;


endmodule
