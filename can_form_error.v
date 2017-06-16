module can_form_error (input Clock_TB, input Bit_Entrada, input [0:5] Estado, output Form_monitor);


reg Form_monitor_Temp = 0;
parameter form_CLKS_PER_BIT = 10; //Setado pelo modulo superior


always @(posedge Clock_TB)
	begin
							

	   //-------------------------------------------------------
		if (Estado == 10) 														// ACK Delimiter
		begin
			if(Bit_Entrada == 1'b0)												// Se o ack delimiter for 0, temos um erro de formacao
				Form_monitor_Temp <= 1;
			else
				Form_monitor_Temp <= 0;

		end
		//-------------------------------------------------------
		else if(Estado ==9) 														// CRC Delimiter
		begin
			if(Bit_Entrada == 1'b0)												// Se o CRC delimiter for 0, temos um erro de formacao
				Form_monitor_Temp <= 1;
			else
				Form_monitor_Temp <= 0;
		end	
		//-------------------------------------------------------
		else if(Estado ==18)														//End Of frame
		begin
			if(Bit_Entrada == 1'b0)												// Se algum dos bits do end of frame for 0,, temos um erro de formacao
				Form_monitor_Temp <= 1;
			else
				Form_monitor_Temp <= 0;
		end	
		//-------------------------------------------------------
		else
			Form_monitor_Temp <= 0;

end

//$display("ENTROU");

assign Form_monitor = Form_monitor_Temp;

endmodule