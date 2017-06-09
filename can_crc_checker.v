module can_crc_checker (BITVAL, BITSTRB, CLEAR, o_CRC, o_flag_CRC);
   input        BITVAL;                            // Next input bit
   input        BITSTRB;                           // Current bit valid (Clock)
   input        CLEAR;                             // Init CRC value
   output [14:0] o_CRC;                               // Current output CRC value
	output o_flag_CRC;
	
	parameter crc_CLKS_PER_BIT  			= 10;
	
	reg flag_CRC = 1'b0;
   reg    [14:0] CRC = 15'b0;                               // We need output registers
   reg bitval = 1'b0;
	reg         inv;
	//wire         inv;
   
	always @(posedge BITSTRB or negedge BITSTRB) begin
		bitval = BITVAL;
		inv = bitval ^ CRC[14];                   // XOR required?
	end

   always @(posedge BITSTRB or negedge BITSTRB or posedge CLEAR) begin
      if (CLEAR) begin
         CRC = 15'b0;                                // Init before calculation
         end
      else begin
         CRC[14] = CRC[13] ^ inv;
         CRC[13] = CRC[12];
         CRC[12] = CRC[11];
         CRC[11] = CRC[10];
         CRC[10] = CRC[9] ^ inv;
         CRC[9] = CRC[8];
         CRC[8] = CRC[7] ^ inv;
         CRC[7] = CRC[6] ^ inv;
         CRC[6] = CRC[5];
         CRC[5] = CRC[4];
         CRC[4] = CRC[3] ^ inv;
         CRC[3] = CRC[2] ^ inv;
         CRC[2] = CRC[1];
         CRC[1] = CRC[0];
         CRC[0] = inv;
         end
		if (CRC == 15'b0)
			flag_CRC <= 0;
		else
			flag_CRC <= 1;
   end
		
	assign o_CRC = CRC;
   assign o_flag_CRC = flag_CRC;

endmodule
