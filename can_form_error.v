module can_form_error (input i_Clock, input i_Data,integer i_Index, input [0:4] i_frame_field, output o_form_monitor);

reg Data_d;
reg Data;
reg [0:4] frame_field;
reg [0:4] frame_field_d;

reg form_monitor = 0;
integer count_Clock = 0;

parameter form_CLKS_PER_BIT = 10;

always @(posedge i_Clock)
	begin
		Data_d <= i_Data;
		Data <= Data_d;
		frame_field_d <= i_frame_field;
		frame_field <= frame_field_d;
	end
	 
always @(posedge i_Clock)
	begin
	   
		if(form_monitor==1&&count_Clock<10)
			 count_Clock<=count_Clock+1;
		else
		  begin
			count_Clock<=0;
		   if (frame_field == 5'b10010) // ACK Delimiter
		   begin
				if(Data == 1'b0)
					form_monitor <= 1;
				else
					form_monitor <= 0;
		   end
			if(frame_field ==5'b10001) // CRC Delimiter
		   begin
				if(Data == 1'b0)
				begin
					form_monitor <= 1;
					end
				else
					form_monitor <= 0;
		   end	

			if(frame_field ==5'b00101)//End Of frame
			begin
				if(Data == 1'b0)
					form_monitor <= 1;
				else
					form_monitor <= 0;
		   end	
			if(frame_field !=5'b10010&&frame_field !=5'b10001&&frame_field !=5'b00101)
					form_monitor <= 0;

		end
end
assign o_form_monitor = form_monitor;

endmodule