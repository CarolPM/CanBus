module can_form_error (input i_Clock, input i_Data, input [0:5] i_frame_field, output [0:3] o_form_monitor);


reg [0:3] form_monitor = 0;


parameter form_CLKS_PER_BIT = 10;


	 
always @(posedge i_Clock)
	begin
		if (i_frame_field == 0) // ID_A
				form_monitor <= 0;
	   //-------------------------------------------------------
		if (i_frame_field == 10) // ACK Delimiter
		begin
			

			if(i_Data == 1'b0)
				form_monitor[2] <= 1;
			else
				form_monitor[2] <= 0;

		end
		//-------------------------------------------------------
		else if(i_frame_field ==9) // CRC Delimiter
		begin

			if(i_Data == 1'b0)
				form_monitor[1] <= 1;
			else
				form_monitor[1] <= 0;

		end	
		//-------------------------------------------------------
		else if(i_frame_field ==20)//End Of frame
		begin

			if(i_Data == 1'b0)
				form_monitor[3] <= 1;
			else
			begin
				if(form_monitor[3]==0)
					form_monitor[3] <= 0;
			end
		end	
		//-------------------------------------------------------
		else if(i_frame_field ==2)//SRR , Doubt_Bits
		begin

			if(i_Data == 1'b0)
				form_monitor[0] <= 1;
			else
			begin
				if(form_monitor[0]==0)
					form_monitor[0] <= 0;
			end
			
		end	
		//-------------------------------------------------------
		//if(form_monitor!=0)
		//$display("%b",form_monitor);
end

assign o_form_monitor = form_monitor;

endmodule