module can_destuff 
	(
		input	i_Clock,
		input i_Ds_Serial,
		input i_cont_0,
		input i_cont_1,
		//input i_bit_index,
		//output o_bit_index,
		output o_cont_0,
		output o_cont_1,
		output o_flag_destuff
	);
	
	parameter CLKS_PER_BIT  = 10;
	
	reg Ds_Serial = 1'b0;
	integer cont_0 = 0;
	integer cont_1 = 0;
	//reg bit_prox_index = 1'b0;
	reg flag_destuff = 1'b0;
	
	always @(posedge i_Clock)
		begin
			Ds_Serial <= i_Ds_Serial;
			cont_0 <= i_cont_0;
			cont_1 <= i_cont_1;
			//bit_prox_index <= i_bit_index;
			flag_destuff <= o_flag_destuff;
		end

	always @(posedge i_Clock)
		begin
			// O destuff só pode considerar que ouve bits iguais sequenciais caso um dos contadores seja 0 e o outro 5.
			// Se esse cuidado não for tomado os contadores ficarão sendo somados individualmente
			// até que o primeiro chegue a 5 sem necessariamente ser sequencialmente.
			// Assim sendo o código abaixo fica fazendo um switch entre o cont_0 e o cont_1
			// onde um só será somado se o outro estiver zerado.
			// Caso não esteja zerado o código passa a somar o contador do outro bit e zera o contador anterior.
			$display("Destuffing");
			if (Ds_Serial == 0)
				begin
					if(cont_1 == 0)
						cont_0 = cont_0 + 1;
					else
						begin
							cont_1 = 0;
							cont_0 = cont_0 + 1;
						end
				end
			else
				begin
					if (cont_0 == 0)
						cont_1 = cont_1 + 1;
					else
						begin
							cont_0 = 0;
							cont_1 = cont_1 + 1;
						end
				end
				
			if (cont_0 == 5 || cont_1 == 5)
				begin
					flag_destuff <= 1; // se for o quinto bit aciona a flag pra o can_rx ignorar o proximo bit lá
					//bit_prox_index <= bit_prox_index + 1; // Se for o quinto bit o destuff pula uma posição do índice (pula o bit stuff)
				end									 // O can_rx deve salvar o bit atual para só então atualizar a posição atual
														 // do bit com o valor de bit_index.
		end
	
	assign o_flag_destuff = flag_destuff;
	//assign o_bit_index = bit_prox_index;
	assign o_cont_0 = cont_0;
	assign o_cont_1 = cont_1;
	
endmodule