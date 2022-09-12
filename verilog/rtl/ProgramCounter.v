module ProgramCounter (
	clk,
	en0,
	en1,
	rst,
	IN_pc,
	IN_write,
	IN_instr,
	IN_BP_branchFound,
	IN_BP_branchTaken,
	IN_BP_isJump,
	IN_BP_branchSrc,
	IN_BP_branchDst,
	IN_BP_branchID,
	IN_BP_multipleBranches,
	OUT_pcRaw,
	OUT_pc,
	OUT_instr,
	OUT_branchID,
	OUT_branchPred,
	OUT_instrValid,
	IN_instrMappingBase,
	IN_instrMappingHalfSize,
	OUT_instrMappingMiss
);
	parameter NUM_UOPS = 2;
	input wire clk;
	input wire en0;
	input wire en1;
	input wire rst;
	input wire [31:0] IN_pc;
	input wire IN_write;
	input wire [63:0] IN_instr;
	input wire IN_BP_branchFound;
	input wire IN_BP_branchTaken;
	input wire IN_BP_isJump;
	input wire [31:0] IN_BP_branchSrc;
	input wire [31:0] IN_BP_branchDst;
	input wire [5:0] IN_BP_branchID;
	input wire IN_BP_multipleBranches;
	output reg [31:0] OUT_pcRaw;
	output reg [(NUM_UOPS * 32) - 1:0] OUT_pc;
	output reg [(NUM_UOPS * 32) - 1:0] OUT_instr;
	output reg [(NUM_UOPS * 6) - 1:0] OUT_branchID;
	output reg [NUM_UOPS - 1:0] OUT_branchPred;
	output reg [NUM_UOPS - 1:0] OUT_instrValid;
	input wire [31:0] IN_instrMappingBase;
	input wire IN_instrMappingHalfSize;
	output wire OUT_instrMappingMiss;
	integer i;
	reg [30:0] pc;
	reg [30:0] pcLast;
	reg [1:0] bMaskLast;
	reg [5:0] bIndexLast [1:0];
	reg bPredLast [1:0];
	wire [32:1] sv2v_tmp_80CC4;
	assign sv2v_tmp_80CC4 = {pc, 1'b0};
	always @(*) OUT_pcRaw = sv2v_tmp_80CC4;
	always @(*) begin
		OUT_instr[0+:32] = IN_instr[31:0];
		OUT_instr[32+:32] = IN_instr[63:32];
	end
	assign OUT_instrMappingMiss = (pc[30:13] != IN_instrMappingBase[31:14]) || (IN_instrMappingHalfSize && (pc[12] != IN_instrMappingBase[13]));
	always @(posedge clk)
		if (rst)
			pc <= 0;
		else if (IN_write)
			pc <= IN_pc[31:1];
		else begin
			if (en1)
				for (i = 0; i < NUM_UOPS; i = i + 1)
					begin
						OUT_pc[i * 32+:32] <= {{pcLast[30:2], 2'b00} + (31'd2 * i[30:0]), 1'b0};
						OUT_instrValid[i] <= (i[0] >= pcLast[1]) && bMaskLast[i];
						OUT_branchID[i * 6+:6] <= bIndexLast[i];
						OUT_branchPred[i] <= bPredLast[i];
					end
			if (en0)
				if (IN_BP_branchFound) begin
					if (IN_BP_isJump || IN_BP_branchTaken) begin
						pc <= IN_BP_branchDst[31:1];
						pcLast <= pc;
						if (IN_BP_branchSrc[2]) begin
							bMaskLast <= 2'b11;
							bIndexLast[0] <= 63;
							bIndexLast[1] <= IN_BP_branchID;
							bPredLast[0] <= 0;
							bPredLast[1] <= 1;
						end
						else begin
							bMaskLast <= 2'b01;
							bIndexLast[0] <= IN_BP_branchID;
							bIndexLast[1] <= 63;
							bPredLast[0] <= 1;
							bPredLast[1] <= 0;
						end
					end
					else begin
						bPredLast[0] <= 0;
						bPredLast[1] <= 0;
						pcLast <= pc;
						if (IN_BP_multipleBranches) begin
							pc <= IN_BP_branchSrc[31:1] + 2;
							bMaskLast <= 2'b01;
						end
						else begin
							bMaskLast <= 2'b11;
							case (pc[1])
								1'b1: pc <= pc + 2;
								1'b0: pc <= pc + 4;
							endcase
						end
						if (IN_BP_branchSrc[2]) begin
							bIndexLast[0] <= 63;
							bIndexLast[1] <= IN_BP_branchID;
						end
						else begin
							bIndexLast[0] <= IN_BP_branchID;
							bIndexLast[1] <= 63;
						end
					end
				end
				else begin
					case (pc[1])
						1'b1: pc <= pc + 2;
						1'b0: pc <= pc + 4;
					endcase
					pcLast <= pc;
					bMaskLast <= 2'b11;
					bIndexLast[0] <= 63;
					bIndexLast[1] <= 63;
					bPredLast[0] <= 0;
					bPredLast[1] <= 0;
				end
		end
endmodule
