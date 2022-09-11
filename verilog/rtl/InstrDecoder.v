module InstrDecoder (
	IN_instr,
	IN_instrValid,
	IN_branchPred,
	IN_branchID,
	IN_pc,
	OUT_uop
);
	parameter NUM_UOPS = 2;
	input wire [(NUM_UOPS * 32) - 1:0] IN_instr;
	input wire [NUM_UOPS - 1:0] IN_instrValid;
	input wire [NUM_UOPS - 1:0] IN_branchPred;
	input wire [(NUM_UOPS * 6) - 1:0] IN_branchID;
	input wire [(NUM_UOPS * 32) - 1:0] IN_pc;
	output reg [(NUM_UOPS * 97) - 1:0] OUT_uop;
	integer i;
	reg [96:0] uop;
	reg invalidEnc;
	reg [31:0] instr;
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				instr = IN_instr[i * 32+:32];
				uop = 97'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
				invalidEnc = 1;
				uop[64-:32] = IN_pc[i * 32+:32];
				uop[0] = IN_instrValid[i];
				uop[7-:6] = IN_branchID[i * 6+:6];
				uop[1] = IN_branchPred[i];
				case (instr[6-:7])
					7'b0110111, 7'b0010111: uop[96-:32] = {instr[31:12], 12'b000000000000};
					7'b1101111: uop[96-:32] = IN_pc[i * 32+:32] + $signed({{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0});
					7'b1110011, 7'b1100111, 7'b0000011, 7'b0010011: uop[96-:32] = $signed({{20 {instr[31]}}, instr[31:20]});
					7'b1100011: uop[96-:32] = IN_pc[i * 32+:32] + $signed({{20 {instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0});
					7'b0100011: uop[96-:32] = $signed({{20 {instr[31]}}, instr[31:25], instr[11:7]});
					default: uop[96-:32] = 0;
				endcase
				case (instr[6-:7])
					7'b1110011: begin
						uop[9-:2] = 2'd0;
						uop[32-:5] = 0;
						uop[27-:5] = 0;
						uop[20-:5] = 0;
						uop[15-:6] = 6'd20;
						uop[21] = 1;
						uop[22] = 1;
						invalidEnc = 0;
					end
					7'b0110111: begin
						uop[9-:2] = 2'd0;
						uop[32-:5] = 0;
						uop[27-:5] = 0;
						uop[22] = 0;
						uop[21] = 1;
						uop[20-:5] = instr[11-:5];
						uop[15-:6] = 6'd16;
						invalidEnc = 0;
					end
					7'b0010111: begin
						uop[9-:2] = 2'd0;
						uop[32-:5] = 0;
						uop[27-:5] = 0;
						uop[22] = 1;
						uop[21] = 1;
						uop[20-:5] = instr[11-:5];
						uop[15-:6] = 6'd17;
						invalidEnc = 0;
					end
					7'b1101111: begin
						uop[9-:2] = 2'd0;
						uop[32-:5] = 0;
						uop[27-:5] = 0;
						uop[22] = 1;
						uop[21] = 1;
						uop[20-:5] = instr[11-:5];
						uop[15-:6] = 6'd18;
						invalidEnc = 0;
					end
					7'b1100111: begin
						uop[9-:2] = 2'd0;
						uop[32-:5] = 0;
						uop[27-:5] = instr[19-:5];
						uop[22] = 1;
						uop[21] = 0;
						uop[20-:5] = instr[11-:5];
						uop[15-:6] = 6'd19;
						invalidEnc = 0;
					end
					7'b0000011: begin
						uop[32-:5] = instr[19-:5];
						uop[27-:5] = 0;
						uop[22] = 0;
						uop[21] = 1;
						uop[20-:5] = instr[11-:5];
						uop[9-:2] = 2'd1;
						case (instr[14-:3])
							0: uop[15-:6] = 6'd0;
							1: uop[15-:6] = 6'd1;
							2: uop[15-:6] = 6'd2;
							4: uop[15-:6] = 6'd3;
							5: uop[15-:6] = 6'd4;
						endcase
						invalidEnc = ((((instr[14-:3] != 0) && (instr[14-:3] != 1)) && (instr[14-:3] != 2)) && (instr[14-:3] != 4)) && (instr[14-:3] != 5);
					end
					7'b0100011: begin
						uop[32-:5] = instr[19-:5];
						uop[27-:5] = instr[24-:5];
						uop[22] = 0;
						uop[21] = 0;
						uop[20-:5] = 0;
						uop[9-:2] = 2'd1;
						case (instr[14-:3])
							0: uop[15-:6] = 6'd5;
							1: uop[15-:6] = 6'd6;
							2: uop[15-:6] = 6'd7;
						endcase
						invalidEnc = ((instr[14-:3] != 0) && (instr[14-:3] != 1)) && (instr[14-:3] != 2);
					end
					7'b1100011: begin
						uop[32-:5] = instr[19-:5];
						uop[27-:5] = instr[24-:5];
						uop[22] = 0;
						uop[21] = 0;
						uop[20-:5] = 0;
						uop[9-:2] = 2'd0;
						case (instr[14-:3])
							0: uop[15-:6] = 6'd10;
							1: uop[15-:6] = 6'd11;
							4: uop[15-:6] = 6'd12;
							5: uop[15-:6] = 6'd13;
							6: uop[15-:6] = 6'd14;
							7: uop[15-:6] = 6'd15;
						endcase
						invalidEnc = (uop[15-:6] == 2) || (uop[15-:6] == 3);
					end
					7'b0010011: begin
						uop[32-:5] = instr[19-:5];
						uop[27-:5] = 0;
						uop[22] = 0;
						uop[21] = 1;
						uop[20-:5] = instr[11-:5];
						invalidEnc = ((instr[14-:3] == 1) && (instr[31-:7] != 0)) || ((instr[14-:3] == 5) && ((instr[31-:7] != 7'h20) && (instr[31-:7] != 0)));
						uop[9-:2] = 2'd0;
						case (instr[14-:3])
							0: uop[15-:6] = 6'd0;
							1: uop[15-:6] = 6'd4;
							2: uop[15-:6] = 6'd6;
							3: uop[15-:6] = 6'd7;
							4: uop[15-:6] = 6'd1;
							5: uop[15-:6] = (instr[31-:7] == 7'h20 ? 6'd9 : 6'd5);
							6: uop[15-:6] = 6'd2;
							7: uop[15-:6] = 6'd3;
						endcase
						if (instr[31-:7] == 7'b0110000) begin
							if (instr[14-:3] == 3'b001) begin
								if (instr[24-:5] == 5'b00000) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd28;
								end
								else if (instr[24-:5] == 5'b00001) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd29;
								end
								else if (instr[24-:5] == 5'b00010) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd30;
								end
								else if (instr[24-:5] == 5'b00100) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd35;
								end
								else if (instr[24-:5] == 5'b00101) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd36;
								end
								else if (instr[24-:5] == 5'b00101) begin
									invalidEnc = 0;
									uop[15-:6] = 6'd37;
								end
							end
							else if (instr[14-:3] == 3'b101) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd39;
								uop[96-:32] = {27'b000000000000000000000000000, instr[24-:5]};
							end
						end
						else if ((instr[31:20] == 12'b001010000111) && (instr[14-:3] == 3'b101))
							uop[15-:6] = 6'd40;
						else if ((instr[31:20] == 12'b011010011000) && (instr[14-:3] == 3'b101))
							uop[15-:6] = 6'd40;
						if (instr[31-:7] == 7'b0100100) begin
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd42;
								uop[96-:32] = {27'b000000000000000000000000000, instr[24-:5]};
							end
							else if (instr[14-:3] == 3'b101) begin
								uop[15-:6] = 6'd43;
								uop[96-:32] = {27'b000000000000000000000000000, instr[24-:5]};
							end
						end
						else if (instr[31-:7] == 7'b0110100) begin
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd44;
								uop[96-:32] = {27'b000000000000000000000000000, instr[24-:5]};
							end
						end
						else if (instr[31-:7] == 7'b0010100)
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd45;
								uop[96-:32] = {27'b000000000000000000000000000, instr[24-:5]};
							end
					end
					7'b0110011: begin
						uop[32-:5] = instr[19-:5];
						uop[27-:5] = instr[24-:5];
						uop[22] = 0;
						uop[21] = 0;
						uop[20-:5] = instr[11-:5];
						uop[9-:2] = 2'd0;
						if (instr[31-:7] == 0) begin
							invalidEnc = 0;
							case (instr[14-:3])
								0: uop[15-:6] = 6'd0;
								1: uop[15-:6] = 6'd4;
								2: uop[15-:6] = 6'd6;
								3: uop[15-:6] = 6'd7;
								4: uop[15-:6] = 6'd1;
								5: uop[15-:6] = 6'd5;
								6: uop[15-:6] = 6'd2;
								7: uop[15-:6] = 6'd3;
							endcase
						end
						else if (instr[31-:7] == 7'h01) begin
							invalidEnc = 0;
							if (instr[14-:3] < 4)
								uop[9-:2] = 2'd2;
							else
								uop[9-:2] = 2'd3;
							case (instr[14-:3])
								0: uop[15-:6] = 6'd0;
								1: uop[15-:6] = 6'd1;
								2: uop[15-:6] = 6'd2;
								3: uop[15-:6] = 6'd3;
								4: uop[15-:6] = 6'd0;
								5: uop[15-:6] = 6'd1;
								6: uop[15-:6] = 6'd2;
								7: uop[15-:6] = 6'd3;
							endcase
						end
						else if (instr[31-:7] == 7'h20) begin
							invalidEnc = (instr[14-:3] != 0) && (instr[14-:3] != 5);
							uop[9-:2] = 2'd0;
							case (instr[14-:3])
								0: uop[15-:6] = 6'd8;
								5: uop[15-:6] = 6'd9;
							endcase
						end
						if (instr[31-:7] == 7'b0010000) begin
							if (instr[14-:3] == 3'b010) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd22;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b100) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd23;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b110) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd24;
								uop[9-:2] = 2'd0;
							end
						end
						else if (instr[31-:7] == 7'b0100000) begin
							if (instr[14-:3] == 3'b111) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd26;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b110) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd27;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b100) begin
								invalidEnc = 0;
								uop[15-:6] = 6'd25;
								uop[9-:2] = 2'd0;
							end
						end
						else if (instr[31-:7] == 7'b0000101) begin
							if (instr[14-:3] == 3'b110) begin
								uop[15-:6] = 6'd31;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b111) begin
								uop[15-:6] = 6'd32;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b100) begin
								uop[15-:6] = 6'd33;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b101) begin
								uop[15-:6] = 6'd34;
								uop[9-:2] = 2'd0;
							end
						end
						else if (((instr[31-:7] == 7'b0000100) && (instr[24-:5] == 0)) && (instr[14-:3] == 3'b100)) begin
							invalidEnc = 0;
							uop[27-:5] = 0;
							uop[15-:6] = 6'd37;
						end
						else if (instr[31-:7] == 7'b0110000) begin
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd38;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b101) begin
								uop[15-:6] = 6'd39;
								uop[9-:2] = 2'd0;
							end
						end
						else if (instr[31-:7] == 7'b0100100) begin
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd42;
								uop[9-:2] = 2'd0;
							end
							else if (instr[14-:3] == 3'b101) begin
								uop[15-:6] = 6'd43;
								uop[9-:2] = 2'd0;
							end
						end
						else if (instr[31-:7] == 7'b0110100) begin
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd44;
								uop[9-:2] = 2'd0;
							end
						end
						else if (instr[31-:7] == 7'b0010100)
							if (instr[14-:3] == 3'b001) begin
								uop[15-:6] = 6'd45;
								uop[9-:2] = 2'd0;
							end
					end
					default: invalidEnc = 1;
				endcase
				if (invalidEnc) begin
					uop[15-:6] = 6'd21;
					uop[9-:2] = 2'd0;
				end
				OUT_uop[i * 97+:97] = uop;
			end
endmodule
