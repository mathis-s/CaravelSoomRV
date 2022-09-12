module AGU (
	clk,
	rst,
	en,
	IN_branch,
	IN_mapping,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	input wire [51:0] IN_branch;
	input wire [335:0] IN_mapping;
	input wire [170:0] IN_uop;
	output reg [136:0] OUT_uop;
	integer i;
	wire [31:0] addr = IN_uop[170-:32] + {20'b00000000000000000000, IN_uop[54:43]};
	reg [3:0] mapping;
	reg mappingValid;
	reg mappingExcept;
	always @(*) begin
		mappingValid = 0;
		mapping = 0;
		for (i = 0; i < 16; i = i + 1)
			if (addr[31:11] == IN_mapping[i * 21+:21]) begin
				mappingValid = 1;
				mapping = i[3:0];
			end
	end
	always @(posedge clk)
		if (rst)
			OUT_uop[0] <= 0;
		else if ((en && IN_uop[0]) && (!IN_branch[51] || ($signed(IN_uop[25-:6] - IN_branch[18-:6]) <= 0))) begin
			mappingExcept = 0;
			if (addr[31:24] == 8'hff)
				OUT_uop[136-:32] <= addr;
			else if (!mappingValid) begin
				mappingExcept = 1;
				OUT_uop[136-:32] <= addr;
			end
			else
				OUT_uop[136-:32] <= {17'b00000000000000000, mapping, addr[10:0]};
			OUT_uop[62-:32] <= IN_uop[106-:32];
			OUT_uop[30-:6] <= IN_uop[36-:6];
			OUT_uop[24-:5] <= IN_uop[30-:5];
			OUT_uop[19-:6] <= IN_uop[25-:6];
			OUT_uop[13-:6] <= IN_uop[12-:6];
			OUT_uop[7-:6] <= IN_uop[6-:6];
			OUT_uop[0] <= 1;
			case (IN_uop[42-:6])
				6'd0, 6'd3, 6'd5: OUT_uop[1] <= mappingExcept || (addr == 0);
				6'd1, 6'd4, 6'd6: OUT_uop[1] <= (mappingExcept || (addr == 0)) || addr[0];
				6'd2, 6'd7: OUT_uop[1] <= (mappingExcept || (addr == 0)) || (addr[0] || addr[1]);
				default:
					;
			endcase
			case (IN_uop[42-:6])
				6'd0: begin
					OUT_uop[63] <= 1;
					OUT_uop[67-:2] <= addr[1:0];
					OUT_uop[65-:2] <= 0;
					OUT_uop[68] <= 1;
				end
				6'd1: begin
					OUT_uop[63] <= 1;
					OUT_uop[67-:2] <= {addr[1], 1'b0};
					OUT_uop[65-:2] <= 1;
					OUT_uop[68] <= 1;
				end
				6'd2: begin
					OUT_uop[63] <= 1;
					OUT_uop[67-:2] <= 2'b00;
					OUT_uop[65-:2] <= 2;
					OUT_uop[68] <= 0;
				end
				6'd3: begin
					OUT_uop[63] <= 1;
					OUT_uop[67-:2] <= addr[1:0];
					OUT_uop[65-:2] <= 0;
					OUT_uop[68] <= 0;
				end
				6'd4: begin
					OUT_uop[63] <= 1;
					OUT_uop[67-:2] <= {addr[1], 1'b0};
					OUT_uop[65-:2] <= 1;
					OUT_uop[68] <= 0;
				end
				6'd5: begin
					OUT_uop[63] <= 0;
					case (addr[1:0])
						0: begin
							OUT_uop[72-:4] <= 4'b0001;
							OUT_uop[104-:32] <= IN_uop[138-:32];
						end
						1: begin
							OUT_uop[72-:4] <= 4'b0010;
							OUT_uop[104-:32] <= IN_uop[138-:32] << 8;
						end
						2: begin
							OUT_uop[72-:4] <= 4'b0100;
							OUT_uop[104-:32] <= IN_uop[138-:32] << 16;
						end
						3: begin
							OUT_uop[72-:4] <= 4'b1000;
							OUT_uop[104-:32] <= IN_uop[138-:32] << 24;
						end
					endcase
				end
				6'd6: begin
					OUT_uop[63] <= 0;
					case (addr[1])
						0: begin
							OUT_uop[72-:4] <= 4'b0011;
							OUT_uop[104-:32] <= IN_uop[138-:32];
						end
						1: begin
							OUT_uop[72-:4] <= 4'b1100;
							OUT_uop[104-:32] <= IN_uop[138-:32] << 16;
						end
					endcase
				end
				6'd7: begin
					OUT_uop[63] <= 0;
					OUT_uop[72-:4] <= 4'b1111;
					OUT_uop[104-:32] <= IN_uop[138-:32];
				end
				default:
					;
			endcase
		end
		else
			OUT_uop[0] <= 0;
endmodule
