module BranchPredictor (
	clk,
	rst,
	IN_pcValid,
	IN_pc,
	OUT_branchTaken,
	OUT_isJump,
	OUT_branchSrc,
	OUT_branchDst,
	OUT_branchID,
	OUT_multipleBranches,
	OUT_branchFound,
	IN_branchValid,
	IN_branchID,
	IN_branchAddr,
	IN_branchDest,
	IN_branchTaken,
	IN_branchIsJump,
	IN_ROB_valid,
	IN_ROB_isBranch,
	IN_ROB_branchID,
	IN_ROB_branchAddr,
	IN_ROB_branchTaken,
	OUT_CSR_branchCommitted
);
	parameter NUM_IN = 2;
	parameter NUM_ENTRIES = 16;
	parameter ID_BITS = 6;
	input wire clk;
	input wire rst;
	input wire IN_pcValid;
	input wire [31:0] IN_pc;
	output reg OUT_branchTaken;
	output reg OUT_isJump;
	output reg [31:0] OUT_branchSrc;
	output reg [31:0] OUT_branchDst;
	output reg [ID_BITS - 1:0] OUT_branchID;
	output reg OUT_multipleBranches;
	output reg OUT_branchFound;
	input wire IN_branchValid;
	input wire [ID_BITS - 1:0] IN_branchID;
	input wire [31:0] IN_branchAddr;
	input wire [31:0] IN_branchDest;
	input wire IN_branchTaken;
	input wire IN_branchIsJump;
	input wire IN_ROB_valid;
	input wire IN_ROB_isBranch;
	input wire [ID_BITS - 1:0] IN_ROB_branchID;
	input wire [29:0] IN_ROB_branchAddr;
	input wire IN_ROB_branchTaken;
	output reg OUT_CSR_branchCommitted;
	integer i;
	reg [ID_BITS - 1:0] insertIndex;
	reg [76:0] entries [NUM_ENTRIES - 1:0];
	always @(*) begin
		OUT_branchFound = 0;
		OUT_branchTaken = 0;
		OUT_multipleBranches = 0;
		OUT_isJump = 1'bx;
		OUT_branchSrc = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		OUT_branchDst = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
		OUT_branchID = 6'bxxxxxx;
		if (IN_pcValid)
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				if (((entries[i][76] && (entries[i][74:46] == IN_pc[31:3])) && (entries[i][45:43] >= IN_pc[2:0])) && (!OUT_branchFound || (entries[i][45:43] < OUT_branchSrc[2:0]))) begin
					if (OUT_branchFound)
						OUT_multipleBranches = 1;
					OUT_branchFound = 1;
					OUT_branchTaken = entries[i][10] || entries[i][0 + ((entries[i][9-:2] * 2) + 1)];
					OUT_isJump = entries[i][10];
					OUT_branchSrc = entries[i][74-:32];
					OUT_branchDst = entries[i][42-:32];
					OUT_branchID = i[ID_BITS - 1:0];
				end
	end
	always @(posedge clk) begin
		OUT_CSR_branchCommitted <= 0;
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				entries[i][76] <= 0;
			insertIndex <= 0;
		end
		else if (IN_branchValid) begin
			if (IN_branchTaken && (IN_branchID == ((1 << ID_BITS) - 1))) begin
				entries[insertIndex[3:0]][76] <= 1;
				entries[insertIndex[3:0]][75] <= 1;
				entries[insertIndex[3:0]][74-:32] <= IN_branchAddr;
				entries[insertIndex[3:0]][42-:32] <= IN_branchDest;
				entries[insertIndex[3:0]][10] <= IN_branchIsJump;
				entries[insertIndex[3:0]][0+:2] <= {IN_branchTaken, IN_branchTaken};
				entries[insertIndex[3:0]][2+:2] <= {IN_branchTaken, IN_branchTaken};
				entries[insertIndex[3:0]][4+:2] <= {IN_branchTaken, IN_branchTaken};
				entries[insertIndex[3:0]][6+:2] <= {IN_branchTaken, IN_branchTaken};
				entries[insertIndex[3:0]][9-:2] <= {IN_branchTaken, IN_branchTaken};
				insertIndex <= insertIndex + 1;
			end
		end
		else if (entries[insertIndex[3:0]][76] && entries[insertIndex[3:0]][75]) begin
			insertIndex[3:0] <= insertIndex[3:0] + 1;
			entries[insertIndex[3:0]][75] <= 0;
		end
		if (((IN_ROB_valid && IN_ROB_isBranch) && (IN_ROB_branchID != ((1 << ID_BITS) - 1))) && ({IN_ROB_branchAddr, 2'b00} == entries[IN_ROB_branchID[3:0]][74-:32])) begin : sv2v_autoblock_1
			reg [1:0] hist;
			hist = entries[IN_ROB_branchID[3:0]][9-:2];
			entries[IN_ROB_branchID[3:0]][9-:2] <= {hist[0], IN_ROB_branchTaken};
			OUT_CSR_branchCommitted <= !entries[IN_ROB_branchID[3:0]][10];
			if (IN_ROB_branchTaken) begin
				if (entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] != 2'b11)
					entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] <= entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] + 1;
			end
			else if (entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] != 2'b00)
				entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] <= entries[IN_ROB_branchID[3:0]][0 + (hist * 2)+:2] - 1;
		end
		if ((!rst && IN_pcValid) && OUT_branchTaken)
			entries[OUT_branchID[3:0]][75] <= 1;
	end
endmodule
