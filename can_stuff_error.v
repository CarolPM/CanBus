module can_stuff_error (input i_Clock, input i_Data, input i_temp_stuff, output o_stuff_monitor);

reg Data;
reg temp_stuff;
reg stuff_monitor = 0;

parameter stuff_CLKS_PER_BIT = 10;

always @(posedge i_Clock)
    begin
		Data <= i_Data;
		temp_stuff <= i_temp_stuff;
	 end
	 
always @(posedge i_Clock)
    begin
		if (temp_stuff!=Data)
			stuff_monitor = 1;
		else
			stuff_monitor = 0;
			//$display("STUFFING ERROR");
			// o próprio módulo manda a msg de erro ou deixa no can_rx msm?
	 end
	 
assign o_stuff_monitor = stuff_monitor;

endmodule