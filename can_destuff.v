module can_destuff (input	i_Clock,input i_Ds_Serial,output o_Ignora_Bit,output o_Eror_Stuffing);
	
	
	parameter CLKS_PER_BIT  			= 10;
	reg Ignora_Bit=0;
	reg Eror_Stuffing=0;
	reg Ds_Serial = 1'b0;
	integer Clock_Count = 5;
	integer cont_0 = 0;
	integer cont_1 = 0;
	//integer contr=0;
	
	always @(posedge i_Clock)
		begin
			Ds_Serial <= i_Ds_Serial;
		end

	always @(posedge i_Clock)
		begin

			if (Clock_Count < CLKS_PER_BIT-1)
                Clock_Count <= Clock_Count + 1'b1;
			else
			begin
				/*contr=contr+1;
				if(contr<100)
				begin
					$display("Valor = %d",Ds_Serial);
					$display("Valor = %d",cont_0);
					$display("Valor = %d",cont_1);
				end*/
				Clock_Count <= 0;
				if(cont_0==5||cont_1==5)
				begin
				
					if(cont_0==5&&Ds_Serial==1)
						Ignora_Bit=1;
					else if(cont_1==5&&Ds_Serial==0)
						Ignora_Bit=1;
					else
						Ignora_Bit=0;
					if(cont_0==5&&Ds_Serial==0)
						Eror_Stuffing=1;
					else if(cont_1==5&&Ds_Serial==1)
						Eror_Stuffing=1;	
					else
						Eror_Stuffing=0;	
						
					cont_0=0;
					cont_1=0;
				end
				else
				begin
					Eror_Stuffing=0;
					Ignora_Bit=0;		
					if (Ds_Serial == 0)
					begin
						cont_1 <= 0;
						cont_0 <= cont_0 + 1;
					end
					else
					begin
						cont_0 <= 0;
						cont_1 <= cont_1 + 1;
					end		
				end						
			end
		end
	
	assign o_Ignora_Bit = Ignora_Bit;
	assign o_Eror_Stuffing = Eror_Stuffing;
	
endmodule