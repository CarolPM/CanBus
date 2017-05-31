module can_form_error (input i_Clock, input i_Data, input [0:4] i_frame_field, output o_form_monitor);

reg Data;
reg [0:4] frame_field;
reg form_monitor = 0;

parameter form_CLKS_PER_BIT = 10;

always @(posedge i_Clock)
	begin
		Data <= i_Data;
		frame_field <= i_frame_field;
	end
	 
always @(posedge i_Clock)
	begin
		if (frame_field == 5'b10001 || frame_field == 5'b10010) //CRC Delimiter ou ACK Delimiter
		begin
			if(Data == 1'b1)
				form_monitor = 1;
			else
				form_monitor = 0;
			//$display("FORM ERROR");
		end
//else //para os outros campos

end
	 
assign o_form_monitor = form_monitor;

endmodule