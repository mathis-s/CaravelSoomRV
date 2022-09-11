module Rename (
	clk,
	en,
	frontEn,
	rst,
	IN_uop,
	comValid,
	comRegNm,
	comRegTag,
	comSqN,
	IN_wbHasResult,
	IN_wbUOp,
	IN_branchTaken,
	IN_branchFlush,
	IN_branchSqN,
	IN_branchLoadSqN,
	IN_branchStoreSqN,
	IN_mispredFlush,
	OUT_uopValid,
	OUT_uop,
	OUT_nextSqN,
	OUT_nextLoadSqN,
	OUT_nextStoreSqN
);
	parameter WIDTH_UOPS = 2;
	parameter WIDTH_WR = 3;
	input wire clk;
	input wire en;
	input wire frontEn;
	input wire rst;
	input wire [(WIDTH_UOPS * 97) - 1:0] IN_uop;
	input wire [WIDTH_UOPS - 1:0] comValid;
	input wire [(WIDTH_UOPS * 5) - 1:0] comRegNm;
	input wire [(WIDTH_UOPS * 6) - 1:0] comRegTag;
	input wire [(WIDTH_UOPS * 6) - 1:0] comSqN;
	input wire [WIDTH_WR - 1:0] IN_wbHasResult;
	input wire [(WIDTH_WR * 92) - 1:0] IN_wbUOp;
	input wire IN_branchTaken;
	input wire IN_branchFlush;
	input wire [5:0] IN_branchSqN;
	input wire [5:0] IN_branchLoadSqN;
	input wire [5:0] IN_branchStoreSqN;
	input wire IN_mispredFlush;
	output reg [WIDTH_UOPS - 1:0] OUT_uopValid;
	output reg [(WIDTH_UOPS * 124) - 1:0] OUT_uop;
	output wire [5:0] OUT_nextSqN;
	output reg [5:0] OUT_nextLoadSqN;
	output reg [5:0] OUT_nextStoreSqN;
	reg [7:0] tags [63:0];
	reg [18:0] rat [31:0];
	integer i;
	integer j;
	reg [5:0] counterSqN;
	reg [5:0] counterStoreSqN;
	reg [5:0] counterLoadSqN;
	assign OUT_nextSqN = counterSqN;
	reg temp;
	reg isNewestCommit [WIDTH_UOPS - 1:0];
	always @(*)
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			begin
				isNewestCommit[i] = comValid[i];
				if (comValid[i])
					for (j = i + 1; j < WIDTH_UOPS; j = j + 1)
						if (comValid[j] && (comRegNm[j * 5+:5] == comRegNm[i * 5+:5]))
							isNewestCommit[i] = 0;
			end
	reg [5:0] newTags [WIDTH_UOPS - 1:0];
	reg newTagsAvail [WIDTH_UOPS - 1:0];
	wire [5:0] newTagsDbg0 = newTags[0];
	wire [5:0] newTagsDbg1 = newTags[1];
	always @(*)
		for (i = 0; i < WIDTH_UOPS; i = i + 1)
			begin
				newTagsAvail[i] = 1'b0;
				newTags[i] = 6'bxxxxxx;
				for (j = 0; j < 64; j = j + 1)
					if (!tags[j][7] && ((i == 0) || (newTags[0] != j[5:0]))) begin
						newTags[i] = j[5:0];
						newTagsAvail[i] = 1'b1;
					end
			end
	reg signed [31:0] usedTags;
	always @(*) begin
		usedTags = 0;
		for (i = 0; i < 64; i = i + 1)
			if (tags[i][7])
				usedTags = usedTags + 1;
	end
	always @(posedge clk) begin
		if (rst) begin
			for (i = 0; i < 32; i = i + 1)
				begin
					tags[i][7] <= 1'b1;
					tags[i][6] <= 1'b1;
					tags[i][5-:6] <= 6'bxxxxxx;
				end
			for (i = 32; i < 64; i = i + 1)
				begin
					tags[i][7] <= 1'b0;
					tags[i][6] <= 1'b0;
					tags[i][5-:6] <= 6'bxxxxxx;
				end
			counterSqN = 0;
			counterStoreSqN = 63;
			counterLoadSqN = 0;
			OUT_nextLoadSqN <= counterLoadSqN;
			OUT_nextStoreSqN <= counterStoreSqN + 1;
			for (i = 0; i < 32; i = i + 1)
				begin
					rat[i][18] <= 1;
					rat[i][17-:6] <= i[5:0];
					rat[i][11-:6] <= i[5:0];
				end
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				begin
					OUT_uop[(i * 124) + 43-:6] <= i[5:0];
					OUT_uopValid[i] <= 0;
				end
		end
		else if (IN_branchTaken) begin
			counterSqN = IN_branchSqN + 1;
			counterLoadSqN = IN_branchLoadSqN;
			counterStoreSqN = IN_branchStoreSqN;
			for (i = 0; i < 32; i = i + 1)
				if ((rat[i][17-:6] != rat[i][11-:6]) && (($signed(rat[i][5-:6] - IN_branchSqN) > 0) || IN_branchFlush)) begin
					rat[i][18] <= 1;
					rat[i][11-:6] <= rat[i][17-:6];
				end
			for (i = 0; i < 64; i = i + 1)
				if (!tags[i][6] && ($signed(tags[i][5-:6] - IN_branchSqN) > 0))
					tags[i][7] <= 0;
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				OUT_uopValid[i] <= 0;
		end
		else if (en && frontEn) begin
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				begin
					OUT_uop[(i * 124) + 123-:32] <= IN_uop[(i * 97) + 96-:32];
					OUT_uop[(i * 124) + 26-:6] <= IN_uop[(i * 97) + 15-:6];
					OUT_uop[(i * 124) + 1-:2] <= IN_uop[(i * 97) + 9-:2];
					OUT_uop[(i * 124) + 31-:5] <= IN_uop[(i * 97) + 20-:5];
					OUT_uop[(i * 124) + 91-:32] <= IN_uop[(i * 97) + 64-:32];
					OUT_uop[(i * 124) + 44] <= IN_uop[(i * 97) + 21];
					OUT_uop[(i * 124) + 45] <= IN_uop[(i * 97) + 22];
					OUT_uop[(i * 124) + 20-:6] <= IN_uop[(i * 97) + 7-:6];
					OUT_uop[(i * 124) + 14] <= IN_uop[(i * 97) + 1];
				end
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				if (IN_uop[i * 97]) begin
					OUT_uopValid[i] <= 1;
					OUT_uop[(i * 124) + 7-:6] <= counterLoadSqN;
					if (IN_uop[(i * 97) + 9-:2] == 2'd1)
						if (((IN_uop[(i * 97) + 15-:6] == 6'd5) || (IN_uop[(i * 97) + 15-:6] == 6'd6)) || (IN_uop[(i * 97) + 15-:6] == 6'd7))
							counterStoreSqN = counterStoreSqN + 1;
						else
							counterLoadSqN = counterLoadSqN + 1;
					OUT_uop[(i * 124) + 43-:6] <= counterSqN;
					OUT_uop[(i * 124) + 13-:6] <= counterStoreSqN;
					OUT_uop[(i * 124) + 58-:6] <= rat[IN_uop[(i * 97) + 32-:5]][11-:6];
					OUT_uop[(i * 124) + 51-:6] <= rat[IN_uop[(i * 97) + 27-:5]][11-:6];
					if (((IN_wbHasResult[0] && (IN_wbUOp[59-:6] == rat[IN_uop[(i * 97) + 32-:5]][11-:6])) || (IN_wbHasResult[1] && (IN_wbUOp[151-:6] == rat[IN_uop[(i * 97) + 32-:5]][11-:6]))) || (IN_wbHasResult[2] && (IN_wbUOp[243-:6] == rat[IN_uop[(i * 97) + 32-:5]][11-:6])))
						OUT_uop[(i * 124) + 59] <= 1;
					else
						OUT_uop[(i * 124) + 59] <= rat[IN_uop[(i * 97) + 32-:5]][18];
					if (((IN_wbHasResult[0] && (IN_wbUOp[59-:6] == rat[IN_uop[(i * 97) + 27-:5]][11-:6])) || (IN_wbHasResult[1] && (IN_wbUOp[151-:6] == rat[IN_uop[(i * 97) + 27-:5]][11-:6]))) || (IN_wbHasResult[2] && (IN_wbUOp[243-:6] == rat[IN_uop[(i * 97) + 27-:5]][11-:6])))
						OUT_uop[(i * 124) + 52] <= 1;
					else
						OUT_uop[(i * 124) + 52] <= rat[IN_uop[(i * 97) + 27-:5]][18];
					if (IN_uop[(i * 97) + 20-:5] != 0) begin
						OUT_uop[(i * 124) + 37-:6] <= newTags[i];
						rat[IN_uop[(i * 97) + 20-:5]][18] = 0;
						rat[IN_uop[(i * 97) + 20-:5]][11-:6] = newTags[i];
						rat[IN_uop[(i * 97) + 20-:5]][5-:6] = counterSqN;
						tags[newTags[i]][7] <= 1;
						tags[newTags[i]][5-:6] <= counterSqN;
					end
					counterSqN = counterSqN + 1;
				end
				else
					OUT_uopValid[i] <= 0;
		end
		else if (!en)
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				OUT_uopValid[i] <= 0;
		if (!rst) begin
			for (i = 0; i < WIDTH_UOPS; i = i + 1)
				if ((comValid[i] && (comRegNm[i * 5+:5] != 0)) && (!IN_branchTaken || ($signed(comSqN[i * 6+:6] - IN_branchSqN) <= 0)))
					if (isNewestCommit[i]) begin
						tags[rat[comRegNm[i * 5+:5]][17-:6]][6] <= 0;
						tags[rat[comRegNm[i * 5+:5]][17-:6]][7] <= 0;
						rat[comRegNm[i * 5+:5]][17-:6] <= comRegTag[i * 6+:6];
						tags[comRegTag[i * 6+:6]][6] <= 1;
						tags[comRegTag[i * 6+:6]][7] <= 1;
						if (IN_mispredFlush || IN_branchTaken) begin
							rat[comRegNm[i * 5+:5]][11-:6] <= comRegTag[i * 6+:6];
							rat[comRegNm[i * 5+:5]][18] <= 1;
						end
					end
					else begin
						tags[comRegTag[i * 6+:6]][6] <= 0;
						tags[comRegTag[i * 6+:6]][7] <= 0;
					end
			for (i = 0; i < WIDTH_WR; i = i + 1)
				begin
					if (IN_wbHasResult[i] && (rat[IN_wbUOp[(i * 92) + 53-:5]][11-:6] == IN_wbUOp[(i * 92) + 59-:6]))
						rat[IN_wbUOp[(i * 92) + 53-:5]][18] = 1;
					if ((en && !frontEn) && IN_wbHasResult[i])
						for (j = 0; j < WIDTH_UOPS; j = j + 1)
							if (OUT_uopValid[j]) begin
								if (OUT_uop[(j * 124) + 58-:6] == IN_wbUOp[(i * 92) + 59-:6])
									OUT_uop[(j * 124) + 59] <= 1;
								if (OUT_uop[(j * 124) + 51-:6] == IN_wbUOp[(i * 92) + 59-:6])
									OUT_uop[(j * 124) + 52] <= 1;
							end
				end
		end
		OUT_nextLoadSqN <= counterLoadSqN;
		OUT_nextStoreSqN <= counterStoreSqN + 1;
	end
endmodule
