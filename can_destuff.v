module can_destuff (input	Clock_SP,input Bit_Input,output Ignora_Bit,output Error_Stuffing);
	
	
	parameter CLKS_PER_BIT  			= 10;   // Setada pelo gerador
	
	reg Ignora_Bit_Temp              = 0;    // Marca sexto bit diferente
	reg Error_Stuffing_Temp           = 0;    // Marca sexto bit igual
	
	integer cont_0                   = 0;    // Conta o numero de bits dominantes
	integer cont_1                   = 0;    // Conta o numero de bits recessivos
	
	


	always @(posedge Clock_SP)							     // Funciona com Sample Point								
		begin
				if(cont_0==5||cont_1==5)					  // Se ja houve 5 bits repetidos checamos o sexto
				begin
					if(cont_0==5&&Bit_Input==1)			  // Se houve 5 bits dominantes e o sexto é recessivo 
						Ignora_Bit_Temp=1;					  // Bit deve ser ignorado
					else if(cont_1==5&&Bit_Input==0)		  // Se houve 5 bits recessivos e o sexto é dominante 
						Ignora_Bit_Temp=1;                 // Bit deve ser ignorado
					else											  // Se não, deixo a variavel zerada por precaução
						Ignora_Bit_Temp=0;
						
					if(cont_0==5&&Bit_Input==0)			  // Se houve 5 bits dominantes e o sexto é dominante
						Error_Stuffing_Temp=1;             // Error Frame
					else if(cont_1==5&Bit_Input==1)       // Se houve 5 bits recessivos e o sexto é recessivos
						Error_Stuffing_Temp=1;	           // Error Frame
					else  										  // Se não, deixo a variavel zerada por precaução
						Error_Stuffing_Temp=0;	
						
					cont_0=0;									  // Zero os contadores
					cont_1=0;	                          // Zero os contadores
				end
				else
				begin
					Error_Stuffing_Temp=0;					  // Bit deve ser ignorado
					Ignora_Bit_Temp=0;		              // Bit deve ser ignorado
					if (Bit_Input == 0)
					begin
						cont_1 <= 0;                       // Contador "1" zerado
						cont_0 <= cont_0 + 1;              // Contador "0" incrementado
					end 
					else
					begin
						cont_0 <= 0;                       // Contador "0" zerado
						cont_1 <= cont_1 + 1;              // Contador "1" incrementado
					end		
				end						
		end
	
	assign Ignora_Bit = Ignora_Bit_Temp;				  // Atualizo saida
	assign Error_Stuffing = Error_Stuffing_Temp;      // Atualizo saida
	 
endmodule