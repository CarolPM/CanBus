module can_destuff 
	(
		input	i_Clock,
		input i_Ds_Serial,
		input i_cont_0,
		input i_cont_1,
		output o_Ds_Serial
	);
	
	//caso seja o quinto bit repetido chama o proprio metodo atual em rx se nao salva o valor normalmente em rx
	/*
	if (i_Ds_Serial == 0)
			i_cont_0 = i_cont_0 + 1;
		else
			i_cont_1 = i_cont_1 + 1;
		if (i_cont_0 < 6 && i_cont_1 < 6)
			begin
				o_Ds_Serial <= i_Ds_Serial;
				#(c_BIT_PERIOD);
			end
		else
			if (i_cont_0 == 6)
				begin
					i_cont_0 <= 1; //contador zera dps soma 1 do novo bit
					r_Rx_Serial <= 1; //bit stuffing
					r_Rx_Serial <= i_start; //sexto bit 0
					#(c_BIT_PERIOD);
				end
			else
				begin
					i_cont_1 <= 1; //contador zera dps soma 1 do novo bit
					r_Rx_Serial <= 0; //bit stuffing
					r_Rx_Serial <= i_start; //sexto bit 1
					#(c_BIT_PERIOD);
				end
	*/			

endmodule