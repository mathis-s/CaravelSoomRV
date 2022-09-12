module Core (
	clk,
	rst,
	en,
	IN_instrRaw,
	IN_MEM_readData,
	OUT_MEM_addr,
	OUT_MEM_writeData,
	OUT_MEM_writeEnable,
	OUT_MEM_readEnable,
	OUT_MEM_writeMask,
	OUT_instrAddr,
	OUT_instrReadEnable,
	OUT_halt,
	OUT_GPIO_oe,
	OUT_GPIO,
	IN_GPIO,
	OUT_SPI_clk,
	OUT_SPI_mosi,
	IN_SPI_miso,
	OUT_instrMappingMiss,
	IN_instrMappingBase,
	IN_instrMappingHalfSize,
	OUT_LA_robPCsample
);
	parameter NUM_UOPS = 2;
	parameter NUM_WBS = 3;
	input wire clk;
	input wire rst;
	input en;
	input wire [63:0] IN_instrRaw;
	input wire [31:0] IN_MEM_readData;
	output wire [29:0] OUT_MEM_addr;
	output wire [31:0] OUT_MEM_writeData;
	output wire OUT_MEM_writeEnable;
	output wire OUT_MEM_readEnable;
	output wire [3:0] OUT_MEM_writeMask;
	output wire [28:0] OUT_instrAddr;
	output wire OUT_instrReadEnable;
	output wire OUT_halt;
	output wire [15:0] OUT_GPIO_oe;
	output wire [15:0] OUT_GPIO;
	input wire [15:0] IN_GPIO;
	output wire OUT_SPI_clk;
	output wire OUT_SPI_mosi;
	input wire IN_SPI_miso;
	output wire OUT_instrMappingMiss;
	input wire [31:0] IN_instrMappingBase;
	input wire IN_instrMappingHalfSize;
	output wire [31:0] OUT_LA_robPCsample;
	integer i;
	wire dbgIsPrint = OUT_MEM_addr == 255;
	wire [(NUM_WBS * 92) - 1:0] wbUOp;
	wire [NUM_WBS - 1:0] wbHasResult;
	assign wbHasResult[0] = wbUOp[0] && (wbUOp[53-:5] != 0);
	assign wbHasResult[1] = wbUOp[92] && (wbUOp[145-:5] != 0);
	assign wbHasResult[2] = wbUOp[184] && (wbUOp[237-:5] != 0);
	wire [(NUM_UOPS * 5) - 1:0] comRegNm;
	wire [(NUM_UOPS * 6) - 1:0] comRegTag;
	wire [(NUM_UOPS * 6) - 1:0] comSqN;
	wire [NUM_UOPS - 1:0] comIsBranch;
	wire [NUM_UOPS - 1:0] comBranchTaken;
	wire [(NUM_UOPS * 6) - 1:0] comBranchID;
	wire [(NUM_UOPS * 30) - 1:0] comPC;
	assign OUT_LA_robPCsample[15:0] = comPC[15-:16];
	assign OUT_LA_robPCsample[31:16] = comPC[45-:16];
	wire [NUM_UOPS - 1:0] comValid;
	wire frontendEn;
	reg [3:0] stateValid;
	assign OUT_instrReadEnable = !(frontendEn && stateValid[0]);
	reg [63:0] instrRawBackup;
	reg useInstrRawBackup;
	wire [63:0] instrRaw = (useInstrRawBackup ? instrRawBackup : IN_instrRaw);
	always @(posedge clk)
		if (rst)
			useInstrRawBackup <= 0;
		else if (!(frontendEn && stateValid[0])) begin
			instrRawBackup <= instrRaw;
			useInstrRawBackup <= 1;
		end
		else
			useInstrRawBackup <= 0;
	reg [51:0] branchProvs [3:0];
	reg [51:0] branch;
	reg mispredFlush;
	reg [5:0] mispredFlushSqN;
	always @(*) begin
		branch[51] = 0;
		branch = 0;
		for (i = 0; i < 4; i = i + 1)
			if ((branchProvs[i][51] && (!branch[51] || ($signed(branchProvs[i][18-:6] - branch[18-:6]) < 0))) && (!mispredFlush || ($signed(branchProvs[i][18-:6] - mispredFlushSqN) < 0))) begin
				branch[51] = 1;
				branch[50-:32] = branchProvs[i][50-:32];
				branch[18-:6] = branchProvs[i][18-:6];
				branch[6-:6] = branchProvs[i][6-:6];
				branch[12-:6] = branchProvs[i][12-:6];
				branch[0] = branchProvs[i][0];
			end
	end
	reg disableMispredFlush;
	reg [(NUM_UOPS * 32) - 1:0] IF_pc;
	wire [(NUM_UOPS * 32) - 1:0] IF_instr;
	wire [NUM_UOPS - 1:0] IF_instrValid;
	wire [31:0] PC_pc;
	assign OUT_instrAddr = PC_pc[31:3];
	wire BP_branchTaken;
	wire BP_isJump;
	wire [31:0] BP_branchSrc;
	wire [31:0] BP_branchDst;
	wire [5:0] BP_branchID;
	wire BP_multipleBranches;
	wire BP_branchFound;
	wire [(NUM_UOPS * 6) - 1:0] IF_branchID;
	wire [NUM_UOPS - 1:0] IF_branchPred;
	wire [NUM_UOPS * 32:1] sv2v_tmp_progCnt_OUT_pc;
	always @(*) IF_pc = sv2v_tmp_progCnt_OUT_pc;
	ProgramCounter progCnt(
		.clk(clk),
		.en0(stateValid[0] && frontendEn),
		.en1(stateValid[1] && frontendEn),
		.rst(rst),
		.IN_pc(branch[50-:32]),
		.IN_write(branch[51]),
		.IN_instr(instrRaw),
		.IN_BP_branchTaken(BP_branchTaken),
		.IN_BP_isJump(BP_isJump),
		.IN_BP_branchSrc(BP_branchSrc),
		.IN_BP_branchDst(BP_branchDst),
		.IN_BP_branchID(BP_branchID),
		.IN_BP_multipleBranches(BP_multipleBranches),
		.IN_BP_branchFound(BP_branchFound),
		.OUT_pcRaw(PC_pc),
		.OUT_pc(sv2v_tmp_progCnt_OUT_pc),
		.OUT_instr(IF_instr),
		.OUT_branchID(IF_branchID),
		.OUT_branchPred(IF_branchPred),
		.OUT_instrValid(IF_instrValid),
		.IN_instrMappingBase(IN_instrMappingBase),
		.IN_instrMappingHalfSize(IN_instrMappingHalfSize),
		.OUT_instrMappingMiss(OUT_instrMappingMiss)
	);
	wire isBranch;
	wire [31:0] branchSource;
	wire branchIsJump;
	wire [5:0] branchID;
	wire branchTaken;
	wire CSR_branchCommitted;
	BranchPredictor bp(
		.clk(clk),
		.rst(rst),
		.IN_pcValid(stateValid[0] && frontendEn),
		.IN_pc(PC_pc),
		.OUT_branchTaken(BP_branchTaken),
		.OUT_isJump(BP_isJump),
		.OUT_branchSrc(BP_branchSrc),
		.OUT_branchDst(BP_branchDst),
		.OUT_branchID(BP_branchID),
		.OUT_multipleBranches(BP_multipleBranches),
		.OUT_branchFound(BP_branchFound),
		.IN_branchValid(isBranch),
		.IN_branchID(branchID),
		.IN_branchAddr(branchSource),
		.IN_branchDest(branchProvs[1][50-:32]),
		.IN_branchTaken(branchTaken),
		.IN_branchIsJump(branchIsJump),
		.IN_ROB_valid(comValid[0]),
		.IN_ROB_isBranch(comIsBranch[0]),
		.IN_ROB_branchID(comBranchID[0+:6]),
		.IN_ROB_branchAddr(comPC[0+:30]),
		.IN_ROB_branchTaken(comBranchTaken[0]),
		.OUT_CSR_branchCommitted(CSR_branchCommitted)
	);
	wire [5:0] RN_nextSqN;
	wire [5:0] ROB_curSqN;
	always @(posedge clk)
		if (rst) begin
			stateValid <= 4'b0000;
			mispredFlush <= 0;
			disableMispredFlush <= 0;
			mispredFlushSqN <= 0;
		end
		else if (branch[51]) begin
			stateValid <= 4'b0000;
			mispredFlush <= ROB_curSqN != RN_nextSqN;
			disableMispredFlush <= 0;
			mispredFlushSqN <= branch[18-:6];
		end
		else if (mispredFlush) begin
			stateValid <= 4'b0000;
			disableMispredFlush <= ROB_curSqN == RN_nextSqN;
			if (disableMispredFlush)
				mispredFlush <= 0;
		end
		else if (frontendEn)
			stateValid <= {stateValid[2:0], 1'b1};
	wire [(NUM_UOPS * 97) - 1:0] DE_uop;
	InstrDecoder idec(
		.IN_instr(IF_instr),
		.IN_branchID(IF_branchID),
		.IN_branchPred(IF_branchPred),
		.IN_instrValid(IF_instrValid),
		.IN_pc(IF_pc),
		.OUT_uop(DE_uop)
	);
	wire [31:0] dbg_DUOp_pc0 = DE_uop[64-:32];
	wire [31:0] dbg_DUOp_pc1 = DE_uop[161-:32];
	wire [4:0] dbg_DUOp_nmDst = DE_uop[20-:5];
	wire [4:0] dbg_DUOp_srcA0 = DE_uop[32-:5];
	wire [4:0] dbg_DUOp_srcA1 = DE_uop[129-:5];
	wire [4:0] dbg_DUOp_srcB0 = DE_uop[27-:5];
	wire [4:0] dbg_DUOp_srcB1 = DE_uop[124-:5];
	wire [(NUM_UOPS * 124) - 1:0] RN_uop;
	reg [NUM_UOPS - 1:0] RN_uopValid;
	wire [5:0] RN_nextLoadSqN;
	wire [5:0] RN_nextStoreSqN;
	wire [NUM_UOPS:1] sv2v_tmp_rn_OUT_uopValid;
	always @(*) RN_uopValid = sv2v_tmp_rn_OUT_uopValid;
	Rename rn(
		.clk(clk),
		.en(!branch[51] && stateValid[2]),
		.frontEn(frontendEn),
		.rst(rst),
		.IN_uop(DE_uop),
		.comValid(comValid),
		.comRegNm(comRegNm),
		.comRegTag(comRegTag),
		.comSqN(comSqN),
		.IN_wbHasResult(wbHasResult),
		.IN_wbUOp(wbUOp),
		.IN_branchTaken(branch[51]),
		.IN_branchFlush(branch[0]),
		.IN_branchSqN(branch[18-:6]),
		.IN_branchLoadSqN(branch[6-:6]),
		.IN_branchStoreSqN(branch[12-:6]),
		.IN_mispredFlush(mispredFlush),
		.OUT_uopValid(sv2v_tmp_rn_OUT_uopValid),
		.OUT_uop(RN_uop),
		.OUT_nextSqN(RN_nextSqN),
		.OUT_nextLoadSqN(RN_nextLoadSqN),
		.OUT_nextStoreSqN(RN_nextStoreSqN)
	);
	wire [31:0] dbg_RUOp_pc0 = RN_uop[91-:32];
	wire [31:0] dbg_RUOp_pc1 = RN_uop[215-:32];
	wire [5:0] dbg_RUOp_sqN0 = RN_uop[43-:6];
	wire [5:0] dbg_RUOp_sqN1 = RN_uop[167-:6];
	wire [5:0] dbg_RUOp_tagDst0 = RN_uop[37-:6];
	wire [5:0] dbg_RUOp_tagDst1 = RN_uop[161-:6];
	wire [4:0] dbg_RUOp_nmDst0 = RN_uop[31-:5];
	wire [4:0] dbg_RUOp_nmDst1 = RN_uop[155-:5];
	wire [5:0] dbg_RUOp_tagA0 = RN_uop[58-:6];
	wire [5:0] dbg_RUOp_tagA1 = RN_uop[182-:6];
	wire [5:0] dbg_RUOp_tagB0 = RN_uop[51-:6];
	wire [5:0] dbg_RUOp_tagB1 = RN_uop[175-:6];
	wire dbg_RUOp_availA0 = RN_uop[59];
	wire dbg_RUOp_availA1 = RN_uop[183];
	wire dbg_RUOp_availB0 = RN_uop[52];
	wire dbg_RUOp_availB1 = RN_uop[176];
	wire [NUM_UOPS - 1:0] RV_uopValid;
	wire [(NUM_UOPS * 124) - 1:0] RV_uop;
	wire [1:0] stall;
	assign stall[0] = 0;
	assign stall[1] = 0;
	wire wbStall [1:0];
	assign wbStall[0] = 0;
	assign wbStall[1] = 0;
	wire [4:0] RV_freeEntries;
	wire DIV_busy;
	wire [(NUM_UOPS * 171) - 1:0] LD_uop;
	wire [(NUM_UOPS * 4) - 1:0] enabledXUs;
	wire DIV_doNotIssue = (DIV_busy || (LD_uop[0] && enabledXUs[3])) || (RV_uopValid[0] && (RV_uop[1-:2] == 2'd3));
	wire MUL_busy;
	wire MUL_doNotIssue = (MUL_busy || (LD_uop[171] && enabledXUs[6])) || (RV_uopValid[1] && (RV_uop[125-:2] == 2'd2));
	ReservationStation rv(
		.clk(clk),
		.rst(rst),
		.frontEn(stateValid[3] && frontendEn),
		.IN_DIV_doNotIssue(DIV_doNotIssue),
		.IN_MUL_doNotIssue(MUL_doNotIssue),
		.IN_stall(stall),
		.IN_uopValid(RN_uopValid),
		.IN_uop(RN_uop),
		.IN_resultValid(wbHasResult),
		.IN_resultUOp(wbUOp),
		.IN_invalidate(branch[51]),
		.IN_invalidateSqN(branch[18-:6]),
		.IN_nextCommitSqN(ROB_curSqN),
		.OUT_valid(RV_uopValid),
		.OUT_uop(RV_uop),
		.OUT_free(RV_freeEntries)
	);
	wire [3:0] RF_readEnable;
	wire [23:0] RF_readAddress;
	wire [127:0] RF_readData;
	wire [17:0] RF_writeAddress;
	assign RF_writeAddress[0+:6] = wbUOp[59-:6];
	assign RF_writeAddress[6+:6] = wbUOp[151-:6];
	assign RF_writeAddress[12+:6] = wbUOp[243-:6];
	wire [95:0] RF_writeData;
	assign RF_writeData[0+:32] = wbUOp[91-:32];
	assign RF_writeData[32+:32] = wbUOp[183-:32];
	assign RF_writeData[64+:32] = wbUOp[275-:32];
	RF rf(
		.clk(clk),
		.rst(rst),
		.IN_readEnable(RF_readEnable),
		.IN_readAddress(RF_readAddress),
		.OUT_readData(RF_readData),
		.IN_writeEnable(wbHasResult),
		.IN_writeAddress(RF_writeAddress),
		.IN_writeData(RF_writeData)
	);
	wire [(NUM_UOPS * 2) - 1:0] LD_fu;
	wire [63:0] LD_zcFwdResult;
	wire [11:0] LD_zcFwdTag;
	wire [1:0] LD_zcFwdValid;
	Load ld(
		.clk(clk),
		.rst(rst),
		.IN_uopValid(RV_uopValid),
		.IN_uop(RV_uop),
		.IN_wbHasResult(wbHasResult),
		.IN_wbUOp(wbUOp),
		.IN_invalidate(branch[51]),
		.IN_invalidateSqN(branch[18-:6]),
		.IN_zcFwdResult(LD_zcFwdResult),
		.IN_zcFwdTag(LD_zcFwdTag),
		.IN_zcFwdValid(LD_zcFwdValid),
		.OUT_rfReadValid(RF_readEnable),
		.OUT_rfReadAddr(RF_readAddress),
		.IN_rfReadData(RF_readData),
		.OUT_enableXU(enabledXUs),
		.OUT_funcUnit(LD_fu),
		.OUT_uop(LD_uop)
	);
	wire [31:0] dbg_LdUOp_pc0 = LD_uop[106-:32];
	wire [31:0] dbg_LdUOp_pc1 = LD_uop[277-:32];
	wire [5:0] dbg_LdUOp_sqN0 = LD_uop[25-:6];
	wire [5:0] dbg_LdUOp_sqN1 = LD_uop[196-:6];
	wire [5:0] dbg_LdUOp_tagDst0 = LD_uop[36-:6];
	wire [5:0] dbg_LdUOp_tagDst1 = LD_uop[207-:6];
	wire [4:0] dbg_LdUOp_nmDst0 = LD_uop[30-:5];
	wire [4:0] dbg_LdUOp_nmDst1 = LD_uop[201-:5];
	wire [31:0] dbg_LdUOp_srcA0 = LD_uop[170-:32];
	wire [31:0] dbg_LdUOp_srcA1 = LD_uop[341-:32];
	wire [31:0] dbg_LdUOp_srcB0 = LD_uop[138-:32];
	wire [31:0] dbg_LdUOp_srcB1 = LD_uop[309-:32];
	wire [31:0] dbg_LdUOp_imm0 = LD_uop[74-:32];
	wire [31:0] dbg_LdUOp_imm1 = LD_uop[245-:32];
	wire dbg_LdUOp_valid = LD_uop[0];
	wire INTALU_wbReq;
	initial branchProvs[0][0] = 0;
	wire [91:0] INT0_uop;
	wire [1:1] sv2v_tmp_ialu_OUT_branchMispred;
	always @(*) branchProvs[0][51] = sv2v_tmp_ialu_OUT_branchMispred;
	wire [32:1] sv2v_tmp_ialu_OUT_branchAddress;
	always @(*) branchProvs[0][50-:32] = sv2v_tmp_ialu_OUT_branchAddress;
	wire [6:1] sv2v_tmp_ialu_OUT_branchSqN;
	always @(*) branchProvs[0][18-:6] = sv2v_tmp_ialu_OUT_branchSqN;
	wire [6:1] sv2v_tmp_ialu_OUT_branchLoadSqN;
	always @(*) branchProvs[0][6-:6] = sv2v_tmp_ialu_OUT_branchLoadSqN;
	wire [6:1] sv2v_tmp_ialu_OUT_branchStoreSqN;
	always @(*) branchProvs[0][12-:6] = sv2v_tmp_ialu_OUT_branchStoreSqN;
	IntALU ialu(
		.clk(clk),
		.en(enabledXUs[0]),
		.rst(rst),
		.IN_wbStall(1'b0),
		.IN_uop(LD_uop[0+:171]),
		.IN_invalidate(branch[51]),
		.IN_invalidateSqN(branch[18-:6]),
		.OUT_wbReq(INTALU_wbReq),
		.OUT_branchMispred(sv2v_tmp_ialu_OUT_branchMispred),
		.OUT_branchAddress(sv2v_tmp_ialu_OUT_branchAddress),
		.OUT_branchSqN(sv2v_tmp_ialu_OUT_branchSqN),
		.OUT_branchLoadSqN(sv2v_tmp_ialu_OUT_branchLoadSqN),
		.OUT_branchStoreSqN(sv2v_tmp_ialu_OUT_branchStoreSqN),
		.OUT_zcFwdResult(LD_zcFwdResult[0+:32]),
		.OUT_zcFwdTag(LD_zcFwdTag[0+:6]),
		.OUT_zcFwdValid(LD_zcFwdValid[0]),
		.OUT_uop(INT0_uop)
	);
	wire [91:0] DIV_uop;
	Divide div(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[3]),
		.OUT_busy(DIV_busy),
		.IN_branch(branch),
		.IN_uop(LD_uop[0+:171]),
		.OUT_uop(DIV_uop)
	);
	assign wbUOp[0+:92] = (INT0_uop[0] ? INT0_uop : DIV_uop);
	wire [136:0] AGU_uop;
	wire [335:0] AGU_mapping;
	AGU agu(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[1]),
		.IN_branch(branch),
		.IN_mapping(AGU_mapping),
		.IN_uop(LD_uop[0+:171]),
		.OUT_uop(AGU_uop)
	);
	wire [5:0] LB_maxLoadSqN;
	wire [52:1] sv2v_tmp_lb_OUT_branch;
	always @(*) branchProvs[2] = sv2v_tmp_lb_OUT_branch;
	LoadBuffer lb(
		.clk(clk),
		.rst(rst),
		.commitSqN(ROB_curSqN),
		.valid({AGU_uop[0]}),
		.isLoad({AGU_uop[63]}),
		.pc({AGU_uop[62-:32]}),
		.addr({AGU_uop[136-:32]}),
		.sqN({AGU_uop[19-:6]}),
		.loadSqN({AGU_uop[7-:6]}),
		.storeSqN({AGU_uop[13-:6]}),
		.IN_branch(branch),
		.OUT_branch(sv2v_tmp_lb_OUT_branch),
		.OUT_maxLoadSqN(LB_maxLoadSqN)
	);
	wire [5:0] SQ_maxStoreSqN;
	wire [0:0] CSR_ce;
	wire [31:0] CSR_dataOut;
	wire IO_busy;
	StoreQueue sq(
		.clk(clk),
		.rst(rst),
		.IN_uop({AGU_uop}),
		.IN_curSqN(ROB_curSqN),
		.IN_branch(branch),
		.IN_MEM_data({IN_MEM_readData}),
		.OUT_MEM_addr({OUT_MEM_addr}),
		.OUT_MEM_data({OUT_MEM_writeData}),
		.OUT_MEM_we({OUT_MEM_writeEnable}),
		.OUT_MEM_ce({OUT_MEM_readEnable}),
		.OUT_MEM_wm({OUT_MEM_writeMask}),
		.IN_CSR_data(CSR_dataOut),
		.OUT_CSR_ce(CSR_ce),
		.OUT_uop({wbUOp[184+:92]}),
		.OUT_maxStoreSqN(SQ_maxStoreSqN),
		.IN_IO_busy(IO_busy)
	);
	initial branchProvs[1][0] = 0;
	wire [91:0] INT1_uop;
	wire [1:1] sv2v_tmp_ialu1_OUT_branchMispred;
	always @(*) branchProvs[1][51] = sv2v_tmp_ialu1_OUT_branchMispred;
	wire [32:1] sv2v_tmp_ialu1_OUT_branchAddress;
	always @(*) branchProvs[1][50-:32] = sv2v_tmp_ialu1_OUT_branchAddress;
	wire [6:1] sv2v_tmp_ialu1_OUT_branchSqN;
	always @(*) branchProvs[1][18-:6] = sv2v_tmp_ialu1_OUT_branchSqN;
	wire [6:1] sv2v_tmp_ialu1_OUT_branchLoadSqN;
	always @(*) branchProvs[1][6-:6] = sv2v_tmp_ialu1_OUT_branchLoadSqN;
	wire [6:1] sv2v_tmp_ialu1_OUT_branchStoreSqN;
	always @(*) branchProvs[1][12-:6] = sv2v_tmp_ialu1_OUT_branchStoreSqN;
	IntALU ialu1(
		.clk(clk),
		.en(enabledXUs[4]),
		.rst(rst),
		.IN_wbStall(1'b0),
		.IN_uop(LD_uop[171+:171]),
		.IN_invalidate(branch[51]),
		.IN_invalidateSqN(branch[18-:6]),
		.OUT_isBranch(isBranch),
		.OUT_branchTaken(branchTaken),
		.OUT_branchMispred(sv2v_tmp_ialu1_OUT_branchMispred),
		.OUT_branchSource(branchSource),
		.OUT_branchAddress(sv2v_tmp_ialu1_OUT_branchAddress),
		.OUT_branchIsJump(branchIsJump),
		.OUT_branchID(branchID),
		.OUT_branchSqN(sv2v_tmp_ialu1_OUT_branchSqN),
		.OUT_branchLoadSqN(sv2v_tmp_ialu1_OUT_branchLoadSqN),
		.OUT_branchStoreSqN(sv2v_tmp_ialu1_OUT_branchStoreSqN),
		.OUT_zcFwdResult(LD_zcFwdResult[32+:32]),
		.OUT_zcFwdTag(LD_zcFwdTag[6+:6]),
		.OUT_zcFwdValid(LD_zcFwdValid[1]),
		.OUT_uop(INT1_uop)
	);
	wire [91:0] MUL_uop;
	wire MUL_wbReq;
	MultiplySmall mul(
		.clk(clk),
		.rst(rst),
		.en(enabledXUs[6]),
		.OUT_busy(MUL_busy),
		.IN_branch(branch),
		.IN_uop(LD_uop[171+:171]),
		.OUT_uop(MUL_uop)
	);
	assign wbUOp[92+:92] = (INT1_uop[0] ? INT1_uop : MUL_uop);
	wire [5:0] ROB_maxSqN;
	wire [31:0] CR_irqAddr;
	wire [1:0] ROB_irqFlags;
	wire [31:0] ROB_irqSrc;
	wire [11:0] ROB_irqMemAddr;
	wire [52:1] sv2v_tmp_rob_OUT_branch;
	always @(*) branchProvs[3] = sv2v_tmp_rob_OUT_branch;
	ROB rob(
		.clk(clk),
		.rst(rst),
		.IN_uop(wbUOp),
		.IN_invalidate(branch[51]),
		.IN_invalidateSqN(branch[18-:6]),
		.OUT_maxSqN(ROB_maxSqN),
		.OUT_curSqN(ROB_curSqN),
		.OUT_comNames(comRegNm),
		.OUT_comTags(comRegTag),
		.OUT_comIsBranch(comIsBranch),
		.OUT_comBranchTaken(comBranchTaken),
		.OUT_comBranchID(comBranchID),
		.OUT_comPC(comPC),
		.OUT_comValid(comValid),
		.OUT_comSqNs(comSqN),
		.IN_irqAddr(CR_irqAddr),
		.OUT_irqFlags(ROB_irqFlags),
		.OUT_irqSrc(ROB_irqSrc),
		.OUT_irqMemAddr(ROB_irqMemAddr),
		.OUT_branch(sv2v_tmp_rob_OUT_branch),
		.OUT_halt(OUT_halt)
	);
	ControlRegs cr(
		.clk(clk),
		.rst(rst),
		.IN_ce(CSR_ce[0]),
		.IN_we(OUT_MEM_writeEnable),
		.IN_wm(OUT_MEM_writeMask),
		.IN_addr(OUT_MEM_addr[6:0]),
		.IN_data(OUT_MEM_writeData),
		.OUT_data(CSR_dataOut[0+:32]),
		.IN_comValid(comValid),
		.IN_branch(branchProvs[1]),
		.IN_wbValid({wbUOp[0], wbUOp[92], wbUOp[184]}),
		.IN_ifValid(IF_instrValid),
		.IN_comBranch(CSR_branchCommitted),
		.OUT_irqAddr(CR_irqAddr),
		.IN_irqTaken(branchProvs[3][51]),
		.IN_irqSrc(ROB_irqSrc),
		.IN_irqFlags(ROB_irqFlags),
		.IN_irqMemAddr(ROB_irqMemAddr),
		.OUT_GPIO_oe(OUT_GPIO_oe),
		.OUT_GPIO(OUT_GPIO),
		.IN_GPIO(IN_GPIO),
		.OUT_SPI_clk(OUT_SPI_clk),
		.OUT_SPI_mosi(OUT_SPI_mosi),
		.IN_SPI_miso(IN_SPI_miso),
		.OUT_AGU_mapping(AGU_mapping),
		.OUT_IO_busy(IO_busy)
	);
	assign frontendEn = ((((((RV_freeEntries > NUM_UOPS) && ($signed(RN_nextLoadSqN - LB_maxLoadSqN) <= -NUM_UOPS)) && ($signed(RN_nextStoreSqN - SQ_maxStoreSqN) <= -NUM_UOPS)) && ($signed(RN_nextSqN - ROB_maxSqN) <= -NUM_UOPS)) && !branch[51]) && en) && !OUT_instrMappingMiss;
endmodule
