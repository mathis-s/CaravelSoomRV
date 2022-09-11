module Multiply (
	clk,
	rst,
	en,
	IN_wbStall,
	OUT_wbReq,
	IN_branch,
	IN_uop,
	OUT_uop
);
	parameter NUM_STAGES = 8;
	parameter BITS = 32 / NUM_STAGES;
	input wire clk;
	input wire rst;
	input wire en;
	input wire IN_wbStall;
	output wire OUT_wbReq;
	input wire [51:0] IN_branch;
	input wire [170:0] IN_uop;
	output reg [91:0] OUT_uop;
	integer i;
	reg [179:0] pl [NUM_STAGES:0];
	assign OUT_wbReq = pl[NUM_STAGES][0];
	reg [63:0] result;
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_STAGES; i = i + 1)
				pl[i][0] <= 0;
		end
		else begin
			if (((en && !IN_wbStall) && IN_uop[0]) && (!IN_branch[51] || ($signed(IN_uop[25-:6] - IN_branch[18-:6]) <= 0))) begin
				pl[0][0] <= 1;
				pl[0][49-:6] <= IN_uop[36-:6];
				pl[0][43-:5] <= IN_uop[30-:5];
				pl[0][38-:6] <= IN_uop[25-:6];
				pl[0][32-:32] <= IN_uop[106-:32];
				pl[0][115-:64] <= 0;
				case (IN_uop[42-:6])
					6'd0, 6'd1: begin
						pl[0][51] <= IN_uop[170] ^ IN_uop[138];
						pl[0][179-:32] <= (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32]);
						pl[0][147-:32] <= (IN_uop[138] ? -IN_uop[138-:32] : IN_uop[138-:32]);
					end
					6'd2: begin
						pl[0][51] <= IN_uop[170];
						pl[0][179-:32] <= (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32]);
						pl[1][147-:32] <= IN_uop[138-:32];
					end
					6'd3: begin
						pl[0][51] <= 0;
						pl[0][179-:32] <= IN_uop[170-:32];
						pl[0][147-:32] <= IN_uop[138-:32];
					end
					default:
						;
				endcase
				pl[0][50] <= IN_uop[42-:6] != 6'd0;
			end
			else
				pl[0][0] <= 0;
			if (!IN_wbStall) begin
				for (i = 0; i < NUM_STAGES; i = i + 1)
					if (pl[i][0] && (!IN_branch[51] || ($signed(pl[i][38-:6] - IN_branch[18-:6]) <= 0))) begin
						pl[i + 1] <= pl[i];
						pl[i + 1][115-:64] <= pl[i][115-:64] + ((pl[i][179-:32] * pl[i][116 + (BITS * i)+:BITS]) << (BITS * i));
					end
					else
						pl[i + 1][0] <= 0;
				if (pl[NUM_STAGES][0] && (!IN_branch[51] || ($signed(pl[NUM_STAGES][38-:6] - IN_branch[18-:6]) <= 0))) begin
					OUT_uop[0] <= 1;
					OUT_uop[59-:6] <= pl[NUM_STAGES][49-:6];
					OUT_uop[53-:5] <= pl[NUM_STAGES][43-:5];
					OUT_uop[48-:6] <= pl[NUM_STAGES][38-:6];
					OUT_uop[42-:32] <= pl[NUM_STAGES][32-:32];
					OUT_uop[10] <= 0;
					OUT_uop[9] <= 0;
					OUT_uop[8-:6] <= 0;
					OUT_uop[2-:2] <= 2'd0;
					result = (pl[NUM_STAGES][51] ? -pl[NUM_STAGES][115-:64] : pl[NUM_STAGES][115-:64]);
					if (pl[NUM_STAGES][50])
						OUT_uop[91-:32] <= result[63:32];
					else
						OUT_uop[91-:32] <= result[31:0];
				end
				else
					OUT_uop[0] <= 0;
			end
		end
endmodule
