module can_form_error (input Clock_TB, input Bit_Entrada, input [0:5] Estado, output [0:3] Form_monitor);

reg check = 0;
reg [0:3] Form_monitor_Temp = 0;
parameter form_CLKS_PER_BIT = 10; //Setado pelo modulo superior


	 
always @(posedge Clock_TB)
	begin
		if (Estado == 0) 															// No ID_A	reseto as flags do form error		
		begin
			Form_monitor_Temp <= 0;									
			check<=0;
		end
				
	   //-------------------------------------------------------
		if (Estado == 10) 														// ACK Delimiter
		begin
			if(Bit_Entrada == 1'b0)												// Se o ack delimiter for 0, temos um erro de formacao
				Form_monitor_Temp[2] <= 1;
			else
				Form_monitor_Temp[2] <= 0;

		end
		//-------------------------------------------------------
		else if(Estado ==9) 														// CRC Delimiter
		begin
			if(Bit_Entrada == 1'b0)												// Se o CRC delimiter for 0, temos um erro de formacao
				Form_monitor_Temp[1] <= 1;
			else
				Form_monitor_Temp[1] <= 0;
		end	
		//-------------------------------------------------------
		else if(Estado ==20)														//End Of frame
		begin
			if(Bit_Entrada == 1'b0)												// Se algum dos bits do end of frame for 0,, temos um erro de formacao
				Form_monitor_Temp[3] <= 1;
			else
			begin
				if(Form_monitor_Temp[3]==0)									//Se um dos bits ja estiver errado, já é o suficiente
					Form_monitor_Temp[3] <= 0;
			end
		end	
		//-------------------------------------------------------
		else if(Estado ==2)														//SRR , Doubt_Bits
		begin
			
			if(check==0)															//Doubt Bits tem 2 bits, mas, so 1 me importa, o primeiro (SRR)
			begin
				if(Bit_Entrada == 1'b0)
					Form_monitor_Temp[0] <= 1;
				else
				begin
					if(Form_monitor_Temp[0]==0)
						Form_monitor_Temp[0] <= 0;
				end
			end
			check<=1;
		end	
end

assign Form_monitor = Form_monitor_Temp;

endmodule