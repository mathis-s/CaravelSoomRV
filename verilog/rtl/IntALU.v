module IntALU (
	clk,
	en,
	rst,
	IN_wbStall,
	IN_uop,
	IN_invalidate,
	IN_invalidateSqN,
	OUT_wbReq,
	OUT_isBranch,
	OUT_branchTaken,
	OUT_branchMispred,
	OUT_branchSource,
	OUT_branchAddress,
	OUT_branchIsJump,
	OUT_branchID,
	OUT_branchSqN,
	OUT_branchLoadSqN,
	OUT_branchStoreSqN,
	OUT_zcFwdResult,
	OUT_zcFwdTag,
	OUT_zcFwdValid,
	OUT_uop
);
	input wire clk;
	input wire en;
	input wire rst;
	input wire IN_wbStall;
	input wire [170:0] IN_uop;
	input IN_invalidate;
	input [5:0] IN_invalidateSqN;
	output wire OUT_wbReq;
	output reg OUT_isBranch;
	output reg OUT_branchTaken;
	output reg OUT_branchMispred;
	output reg [31:0] OUT_branchSource;
	output reg [31:0] OUT_branchAddress;
	output reg OUT_branchIsJump;
	output reg [5:0] OUT_branchID;
	output reg [5:0] OUT_branchSqN;
	output reg [5:0] OUT_branchLoadSqN;
	output reg [5:0] OUT_branchStoreSqN;
	output wire [31:0] OUT_zcFwdResult;
	output wire [5:0] OUT_zcFwdTag;
	output wire OUT_zcFwdValid;
	output reg [91:0] OUT_uop;
	integer i = 0;
	wire [31:0] srcA = IN_uop[170-:32];
	wire [31:0] srcB = IN_uop[138-:32];
	wire [31:0] imm = IN_uop[74-:32];
	assign OUT_wbReq = IN_uop[0] && en;
	reg [31:0] resC;
	reg [1:0] flags;
	assign OUT_zcFwdResult = resC;
	assign OUT_zcFwdTag = IN_uop[36-:6];
	assign OUT_zcFwdValid = (IN_uop[0] && en) && (IN_uop[30-:5] != 0);
	wire [5:0] resLzTz;
	reg [31:0] srcAbitRev;
	always @(*)
		for (i = 0; i < 32; i = i + 1)
			srcAbitRev[i] = srcA[31 - i];
	LZCnt lzc(
		.in((IN_uop[42-:6] == 6'd28 ? srcA : srcAbitRev)),
		.out(resLzTz)
	);
	wire [5:0] resPopCnt;
	PopCnt popc(
		.a(IN_uop[170-:32]),
		.res(resPopCnt)
	);
	always @(*) begin
		case (IN_uop[42-:6])
			6'd17, 6'd0: resC = srcA + srcB;
			6'd1: resC = srcA ^ srcB;
			6'd2: resC = srcA | srcB;
			6'd3: resC = srcA & srcB;
			6'd4: resC = srcA << srcB[4:0];
			6'd5: resC = srcA >> srcB[4:0];
			6'd6: resC = {31'b0000000000000000000000000000000, $signed(srcA) < $signed(srcB)};
			6'd7: resC = {31'b0000000000000000000000000000000, srcA < srcB};
			6'd8: resC = srcA - srcB;
			6'd9: resC = srcA >>> srcB[4:0];
			6'd16: resC = srcB;
			6'd19, 6'd18: resC = srcA + 4;
			6'd20: resC = 0;
			6'd22: resC = srcB + (srcA << 1);
			6'd23: resC = srcB + (srcA << 2);
			6'd24: resC = srcB + (srcA << 3);
			6'd26: resC = srcA & ~srcB;
			6'd27: resC = srcA | ~srcB;
			6'd25: resC = srcA ^ ~srcB;
			6'd35: resC = {{24 {srcA[7]}}, srcA[7:0]};
			6'd36: resC = {{16 {srcA[15]}}, srcA[15:0]};
			6'd37: resC = {16'b0000000000000000, srcA[15:0]};
			6'd28, 6'd29: resC = {26'b00000000000000000000000000, resLzTz};
			6'd30: resC = {26'b00000000000000000000000000, resPopCnt};
			default: resC = 'bx;
		endcase
		case (IN_uop[42-:6])
			6'd21: flags = 2'd3;
			6'd20: flags = (imm[0] ? 2'd1 : 2'd2);
			default: flags = 2'd0;
		endcase
	end
	reg isBranch;
	reg branchTaken;
	always @(*) begin
		case (IN_uop[42-:6])
			6'd18, 6'd19: branchTaken = 1;
			6'd10: branchTaken = srcA == srcB;
			6'd11: branchTaken = srcA != srcB;
			6'd12: branchTaken = $signed(srcA) < $signed(srcB);
			6'd13: branchTaken = !($signed(srcA) < $signed(srcB));
			6'd14: branchTaken = srcA < srcB;
			6'd15: branchTaken = !(srcA < srcB);
			default: branchTaken = 0;
		endcase
		isBranch = ((((((IN_uop[42-:6] == 6'd18) || (IN_uop[42-:6] == 6'd10)) || (IN_uop[42-:6] == 6'd11)) || (IN_uop[42-:6] == 6'd12)) || (IN_uop[42-:6] == 6'd13)) || (IN_uop[42-:6] == 6'd14)) || (IN_uop[42-:6] == 6'd15);
	end
	always @(posedge clk)
		if (rst) begin
			OUT_uop[0] <= 0;
			OUT_branchTaken <= 0;
			OUT_isBranch <= 0;
			OUT_branchMispred <= 0;
		end
		else if (((IN_uop[0] && en) && !IN_wbStall) && (!IN_invalidate || ($signed(IN_uop[25-:6] - IN_invalidateSqN) <= 0))) begin
			OUT_branchSqN <= IN_uop[25-:6];
			OUT_branchLoadSqN <= IN_uop[6-:6];
			OUT_branchStoreSqN <= IN_uop[12-:6];
			OUT_isBranch <= isBranch;
			if (isBranch) begin
				OUT_branchSource <= IN_uop[106-:32];
				OUT_branchID <= IN_uop[19-:6];
				OUT_branchIsJump <= IN_uop[42-:6] == 6'd18;
				OUT_branchTaken <= branchTaken;
				if (branchTaken != IN_uop[13]) begin
					OUT_branchMispred <= 1;
					if (branchTaken)
						OUT_branchAddress <= imm;
					else
						OUT_branchAddress <= IN_uop[106-:32] + 4;
				end
				else
					OUT_branchMispred <= 0;
			end
			else if (IN_uop[42-:6] == 6'd19) begin
				OUT_branchAddress <= srcB + imm;
				OUT_branchMispred <= 1;
			end
			else
				OUT_branchMispred <= 0;
			OUT_uop[10] <= isBranch;
			OUT_uop[9] <= branchTaken;
			OUT_uop[8-:6] <= IN_uop[19-:6];
			OUT_uop[59-:6] <= IN_uop[36-:6];
			OUT_uop[53-:5] <= IN_uop[30-:5];
			OUT_uop[91-:32] <= resC;
			OUT_uop[48-:6] <= IN_uop[25-:6];
			OUT_uop[2-:2] <= flags;
			OUT_uop[0] <= 1;
			OUT_uop[42-:32] <= IN_uop[106-:32];
		end
		else begin
			OUT_branchMispred <= 0;
			OUT_uop[0] <= 0;
			OUT_isBranch <= 0;
		end
endmodule
