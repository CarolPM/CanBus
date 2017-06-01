module can_destuff 
	(
		input	i_Clock,
		input i_Ds_Serial,
		input [0:2] i_cont_0,
		input [0:2] i_cont_1,
		output [0:2] o_cont_0,
		output [0:2] o_cont_1,
		output [0:1] o_flag_destuff
	);
	
	parameter CLKS_PER_BIT  			= 10;
	
	reg [0:63]    Clock_Count         = 0;
	reg Ds_Serial = 1'b0;
	reg [0:2] cont_0 = 3'b0;
	reg [0:2] cont_1 = 3'b0;
	reg [0:1] flag_destuff = 0;
	
	always @(posedge i_Clock)
		begin
			Ds_Serial <= i_Ds_Serial;
			cont_0 <= i_cont_0;
			cont_1 <= i_cont_1;
		end

	always @(posedge i_Clock)
		begin
			// O destuff só pode considerar que ouve bits iguais sequenciais caso um dos contadores seja 0 e o outro 5.
			// Se esse cuidado não for tomado os contadores ficarão sendo somados individualmente
			// até que o primeiro chegue a 5 sem necessariamente ser sequencialmente.
			// Assim sendo o código abaixo fica fazendo um switch entre o cont_0 e o cont_1
			// onde um só será somado se o outro estiver zerado.
			// Caso não esteja zerado o código passa a somar o contador do outro bit e zera o contador anterior.
			 
			 /*if (Clock_Count < CLKS_PER_BIT-1)
              begin
                Clock_Count <= Clock_Count + 1'b1;
              end
			else
			begin*/
			//#(CLKS_PER_BIT);
				 //Clock_Count <= 0;
				if (Ds_Serial == 1'b0)
					if(cont_1 == 3'b0)
						cont_0 <= cont_0 + 3'b1;
					else
						begin
							cont_1 <= 1'b0;
							cont_0 <= cont_0 + 3'b1;
						end
				else
					if (cont_0 == 3'b0)
						cont_1 <= cont_1 + 1'b1;
					else
						begin
							cont_0 <= 1'b0;
							cont_1 <= cont_1 + 1'b1;
						end
				
				if (cont_0 == 3'b101 || cont_1 == 3'b101)
					begin
						flag_destuff <= 2'b1;	// se for o quinto bit aciona a flag pra o can_rx ignorar o proximo bit lá
														//bit_prox_index <= bit_prox_index + 1; // Se for o quinto bit o destuff pula uma posição do índice (pula o bit stuff)
					end								// O can_rx deve salvar o bit atual para só então atualizar a posição atual
														// do bit com o valor de bit_index.
				else
					flag_destuff <= 2'b0;
			//$display("cont_0: %b	cont_1: %b", cont_0, cont_1);
			//end
			//$display("flag: %b", flag_destuff);
		end
	
	assign o_cont_0 = cont_0;
	assign o_cont_1 = cont_1;
	assign o_flag_destuff = flag_destuff;
	
endmodule