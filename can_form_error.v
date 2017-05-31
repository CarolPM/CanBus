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
	   
		if(form_monitor==1&&count_Clock<20)
			 count_Clock<=count_Clock+1;
		else
		  begin
			
			count_Clock<=0;
		   if (frame_field == 5'b10010) //CRC Delimiter ou ACK Delimiter
		   begin
			
			if(Data == 1'b1)
				form_monitor <= 1;
			else
				form_monitor <= 0;
		   end
		   else
			form_monitor <= 0;

		  end

end
	 

assign o_form_monitor = form_monitor;

endmodule