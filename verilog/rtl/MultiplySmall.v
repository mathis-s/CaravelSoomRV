module MultiplySmall (
	clk,
	rst,
	en,
	OUT_busy,
	IN_branch,
	IN_uop,
	OUT_uop
);
	parameter NUM_STAGES = 8;
	parameter TP = 2;
	parameter NUM_REGS = NUM_STAGES / TP;
	parameter BITS = 32 / NUM_STAGES;
	input wire clk;
	input wire rst;
	input wire en;
	output wire OUT_busy;
	input wire [51:0] IN_branch;
	input wire [170:0] IN_uop;
	output reg [91:0] OUT_uop;
	integer i;
	reg [179:0] pl;
	reg [3:0] stage;
	assign OUT_busy = pl[0] && (stage < (NUM_STAGES - 1));
	reg [63:0] result;
	always @(posedge clk) begin
		OUT_uop[0] <= 0;
		if (rst)
			pl[0] <= 0;
		else begin
			if ((en && IN_uop[0]) && (!IN_branch[51] || ($signed(IN_uop[25-:6] - IN_branch[18-:6]) <= 0))) begin
				pl[0] <= 1;
				pl[49-:6] <= IN_uop[36-:6];
				pl[43-:5] <= IN_uop[30-:5];
				pl[38-:6] <= IN_uop[25-:6];
				pl[32-:32] <= IN_uop[106-:32];
				pl[115-:64] <= 0;
				stage <= 0;
				case (IN_uop[42-:6])
					6'd0, 6'd1: begin
						pl[51] <= IN_uop[170] ^ IN_uop[138];
						pl[179-:32] <= (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32]);
						pl[147-:32] <= (IN_uop[138] ? -IN_uop[138-:32] : IN_uop[138-:32]);
					end
					6'd2: begin
						pl[51] <= IN_uop[170];
						pl[179-:32] <= (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32]);
						pl[147-:32] <= IN_uop[138-:32];
					end
					6'd3: begin
						pl[51] <= 0;
						pl[179-:32] <= IN_uop[170-:32];
						pl[147-:32] <= IN_uop[138-:32];
					end
					default:
						;
				endcase
				pl[50] <= IN_uop[42-:6] != 6'd0;
			end
			if (pl[0] && (!IN_branch[51] || ($signed(pl[38-:6] - IN_branch[18-:6]) <= 0)))
				if (stage != NUM_STAGES) begin
					pl[115-:64] <= pl[115-:64] + ((pl[179-:32] * pl[116 + (BITS * stage)+:BITS]) << (BITS * stage));
					stage <= stage + 1;
				end
				else begin
					pl[0] <= 0;
					OUT_uop[0] <= 1;
					OUT_uop[59-:6] <= pl[49-:6];
					OUT_uop[53-:5] <= pl[43-:5];
					OUT_uop[48-:6] <= pl[38-:6];
					OUT_uop[42-:32] <= pl[32-:32];
					OUT_uop[10] <= 0;
					OUT_uop[9] <= 0;
					OUT_uop[8-:6] <= 0;
					OUT_uop[2-:2] <= 2'd0;
					result = (pl[51] ? -pl[115-:64] : pl[115-:64]);
					if (pl[50])
						OUT_uop[91-:32] <= result[63:32];
					else
						OUT_uop[91-:32] <= result[31:0];
				end
		end
	end
endmodule
