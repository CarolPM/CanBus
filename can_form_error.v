module can_form_error (input i_Clock, input i_Data,integer i_Index, input [0:4] i_frame_field, output o_form_monitor);

reg Data;
reg [0:4] frame_field;
reg form_monitor = 0;
reg count_Clock = 0;

parameter form_CLKS_PER_BIT = 10;

/*always @(posedge i_Clock)
	begin
		Data <= i_Data;
		frame_field <= i_frame_field;
	end*/
	 
always @(posedge i_Clock)
	begin
	
		if(form_monitor==1&&count_Clock<2)
			 count_Clock<=count_Clock+1;
		else
		begin
			count_Clock<=0;
		if (i_frame_field == 5'b10001 || i_frame_field == 5'b10010) //CRC Delimiter ou ACK Delimiter
		begin
			
			if(i_Data == 1'b1)
			begin
				form_monitor <= 1;
			end
			
			else
				form_monitor <= 0;
			//$display("FORM ERROR");
		end
		else
			form_monitor <= 0;
		end

end
	 

assign o_form_monitor = form_monitor;

endmodule