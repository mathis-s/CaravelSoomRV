module ROB (
	clk,
	rst,
	IN_uop,
	IN_invalidate,
	IN_invalidateSqN,
	OUT_maxSqN,
	OUT_curSqN,
	OUT_comNames,
	OUT_comTags,
	OUT_comSqNs,
	OUT_comIsBranch,
	OUT_comBranchTaken,
	OUT_comBranchID,
	OUT_comPC,
	OUT_comValid,
	IN_irqAddr,
	OUT_irqFlags,
	OUT_irqSrc,
	OUT_irqMemAddr,
	OUT_branch,
	OUT_halt
);
	parameter LENGTH = 30;
	parameter WIDTH = 2;
	parameter WIDTH_WB = 3;
	input wire clk;
	input wire rst;
	input wire [(WIDTH_WB * 92) - 1:0] IN_uop;
	input wire IN_invalidate;
	input wire [5:0] IN_invalidateSqN;
	output wire [5:0] OUT_maxSqN;
	output wire [5:0] OUT_curSqN;
	output reg [(WIDTH * 5) - 1:0] OUT_comNames;
	output reg [(WIDTH * 6) - 1:0] OUT_comTags;
	output reg [(WIDTH * 6) - 1:0] OUT_comSqNs;
	output reg [WIDTH - 1:0] OUT_comIsBranch;
	output reg [WIDTH - 1:0] OUT_comBranchTaken;
	output reg [(WIDTH * 6) - 1:0] OUT_comBranchID;
	output reg [(WIDTH * 30) - 1:0] OUT_comPC;
	output reg [WIDTH - 1:0] OUT_comValid;
	input wire [31:0] IN_irqAddr;
	output reg [1:0] OUT_irqFlags;
	output reg [31:0] OUT_irqSrc;
	output reg [11:0] OUT_irqMemAddr;
	output reg [51:0] OUT_branch;
	output reg OUT_halt;
	reg [57:0] entries [LENGTH - 1:0];
	reg [5:0] baseIndex;
	reg [31:0] committedInstrs;
	assign OUT_maxSqN = (baseIndex + LENGTH) - 1;
	assign OUT_curSqN = baseIndex;
	integer i;
	integer j;
	reg headValid;
	always @(*) begin
		headValid = 1;
		for (i = 0; i < WIDTH; i = i + 1)
			if (!entries[i][57] || (entries[i][56-:2] != 2'd0))
				headValid = 0;
		if (entries[1][7])
			headValid = 0;
	end
	reg allowSingleDequeue;
	always @(*) begin
		allowSingleDequeue = 1;
		if (!entries[0][57])
			allowSingleDequeue = 0;
	end
	wire doDequeue = headValid;
	always @(posedge clk) begin
		OUT_branch[51] <= 0;
		OUT_halt <= 0;
		if (rst) begin
			baseIndex = 0;
			for (i = 0; i < LENGTH; i = i + 1)
				entries[i][57] <= 0;
			for (i = 0; i < WIDTH; i = i + 1)
				OUT_comValid[i] <= 0;
			committedInstrs <= 0;
			OUT_branch[51] <= 0;
		end
		else if (IN_invalidate)
			for (i = 0; i < LENGTH; i = i + 1)
				if ($signed((baseIndex + i[5:0]) - IN_invalidateSqN) > 0)
					entries[i][57] <= 0;
		if (!rst) begin
			if (doDequeue && !IN_invalidate) begin
				for (i = 0; i < (LENGTH - WIDTH); i = i + 1)
					entries[i] <= entries[i + WIDTH];
				for (i = LENGTH - WIDTH; i < LENGTH; i = i + 1)
					entries[i][57] <= 0;
				committedInstrs <= committedInstrs + 2;
				for (i = 0; i < WIDTH; i = i + 1)
					begin
						OUT_comNames[i * 5+:5] <= entries[i][12-:5];
						OUT_comTags[i * 6+:6] <= entries[i][54-:6];
						OUT_comSqNs[i * 6+:6] <= baseIndex + i[5:0];
						OUT_comIsBranch[i] <= entries[i][7];
						OUT_comBranchTaken[i] <= entries[i][6];
						OUT_comBranchID[i * 6+:6] <= entries[i][5-:6];
						OUT_comValid[i] <= 1;
						OUT_comPC[i * 30+:30] <= entries[i][42-:30];
					end
				baseIndex = baseIndex + WIDTH;
			end
			else if (allowSingleDequeue && !IN_invalidate) begin
				for (i = 0; i < (LENGTH - 1); i = i + 1)
					entries[i] <= entries[i + 1];
				for (i = LENGTH - 1; i < LENGTH; i = i + 1)
					entries[i][57] <= 0;
				for (i = 0; i < 1; i = i + 1)
					begin
						OUT_comNames[i * 5+:5] <= entries[i][12-:5];
						OUT_comTags[i * 6+:6] <= entries[i][54-:6];
						OUT_comSqNs[i * 6+:6] <= baseIndex + i[5:0];
						OUT_comIsBranch[i] <= entries[i][7];
						OUT_comBranchTaken[i] <= entries[i][6];
						OUT_comBranchID[i * 6+:6] <= entries[i][5-:6];
						OUT_comValid[i] <= 1;
						OUT_comPC[i * 30+:30] <= entries[i][42-:30];
						if (entries[i][56-:2] == 2'd1) begin
							OUT_halt <= 1;
							OUT_branch[51] <= 1;
							OUT_branch[50-:32] <= {entries[i][42-:30] + 1'b1, 2'b00};
							OUT_branch[18-:6] <= baseIndex + i[5:0];
							OUT_branch[0] <= 1;
							OUT_branch[12-:6] <= 0;
							OUT_branch[6-:6] <= 0;
							OUT_comNames[i * 5+:5] <= 0;
						end
						else if ((entries[i][56-:2] == 2'd2) || (entries[i][56-:2] == 2'd3)) begin
							OUT_branch[51] <= 1;
							OUT_branch[50-:32] <= IN_irqAddr;
							OUT_branch[18-:6] <= baseIndex + i[5:0];
							OUT_branch[0] <= 1;
							OUT_branch[12-:6] <= 0;
							OUT_branch[6-:6] <= 0;
							if (entries[i][56-:2] == 2'd3)
								OUT_comNames[i * 5+:5] <= 0;
							OUT_irqFlags <= entries[i][56-:2];
							OUT_irqSrc <= {entries[i][42-:30], 2'b00};
							OUT_irqMemAddr <= {entries[i][12-:5], entries[i][6], entries[i][5-:6]};
						end
					end
				for (i = 1; i < WIDTH; i = i + 1)
					OUT_comValid[i] <= 0;
				committedInstrs <= committedInstrs + 1;
				baseIndex = baseIndex + 1;
			end
			else
				for (i = 0; i < WIDTH; i = i + 1)
					OUT_comValid[i] <= 0;
			for (i = 0; i < WIDTH_WB; i = i + 1)
				if (IN_uop[i * 92] && (!IN_invalidate || ($signed(IN_uop[(i * 92) + 48-:6] - IN_invalidateSqN) <= 0))) begin
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][57] <= 1;
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][56-:2] <= IN_uop[(i * 92) + 2-:2];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][54-:6] <= IN_uop[(i * 92) + 59-:6];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][12-:5] <= IN_uop[(i * 92) + 53-:5];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][48-:6] <= IN_uop[(i * 92) + 48-:6];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][42-:30] <= IN_uop[(i * 92) + 42-:30];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][7] <= IN_uop[(i * 92) + 10];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][6] <= IN_uop[(i * 92) + 9];
					entries[IN_uop[(i * 92) + 47-:5] - baseIndex[4:0]][5-:6] <= IN_uop[(i * 92) + 8-:6];
				end
		end
	end
endmodule
