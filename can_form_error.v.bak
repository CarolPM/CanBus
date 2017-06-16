module can_form_error (input i_Clock, input i_Data, input [0:5] i_frame_field, output o_form_monitor);



reg [0:4] frame_field;
reg Data;
reg form_monitor = 0;


parameter form_CLKS_PER_BIT = 10;

always @(posedge i_Clock)
	begin
		Data <= i_Data;
		frame_field <= i_frame_field;
	end
	 
always @(posedge i_Clock)
	begin
	   //-------------------------------------------------------
		if (frame_field == 18) // ACK Delimiter
		begin
			if(Data == 1'b0)
				form_monitor <= 1;
			else
				form_monitor <= 0;
		end
		//-------------------------------------------------------
		else if(frame_field ==17) // CRC Delimiter
		begin
			if(Data == 1'b0)
			begin
				//$display("EXISTE UM BIT IGNORADO");
				form_monitor <= 1;
			end
			else
				form_monitor <= 0;
		end	
		//-------------------------------------------------------
		else if(frame_field ==5)//End Of frame
		begin
			if(Data == 1'b0)
				form_monitor <= 1;
			else
				form_monitor <= 0;
		end	
		//-------------------------------------------------------
		else if(frame_field ==8)//SRR
		begin
			if(Data == 1'b0)
				form_monitor <= 1;
			else
				form_monitor <= 0;
		end	
		//-------------------------------------------------------
		else
			form_monitor <= 0;
end

assign o_form_monitor = form_monitor;

endmodule