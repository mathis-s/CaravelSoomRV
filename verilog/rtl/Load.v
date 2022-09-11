module Load (
	clk,
	rst,
	IN_uopValid,
	IN_uop,
	IN_wbHasResult,
	IN_wbUOp,
	IN_invalidate,
	IN_invalidateSqN,
	IN_zcFwdResult,
	IN_zcFwdTag,
	IN_zcFwdValid,
	OUT_rfReadValid,
	OUT_rfReadAddr,
	IN_rfReadData,
	OUT_enableXU,
	OUT_funcUnit,
	OUT_uop
);
	parameter NUM_UOPS = 2;
	parameter NUM_WBS = 3;
	parameter NUM_XUS = 4;
	parameter NUM_ZC_FWDS = 2;
	input wire clk;
	input wire rst;
	input wire [NUM_UOPS - 1:0] IN_uopValid;
	input wire [(NUM_UOPS * 124) - 1:0] IN_uop;
	input wire [NUM_WBS - 1:0] IN_wbHasResult;
	input wire [(NUM_WBS * 92) - 1:0] IN_wbUOp;
	input wire IN_invalidate;
	input wire [5:0] IN_invalidateSqN;
	input wire [(NUM_ZC_FWDS * 32) - 1:0] IN_zcFwdResult;
	input wire [(NUM_ZC_FWDS * 6) - 1:0] IN_zcFwdTag;
	input wire [NUM_ZC_FWDS - 1:0] IN_zcFwdValid;
	output reg [(2 * NUM_UOPS) - 1:0] OUT_rfReadValid;
	output reg [((2 * NUM_UOPS) * 6) - 1:0] OUT_rfReadAddr;
	input wire [((2 * NUM_UOPS) * 32) - 1:0] IN_rfReadData;
	output reg [(NUM_UOPS * NUM_XUS) - 1:0] OUT_enableXU;
	output reg [(NUM_UOPS * 2) - 1:0] OUT_funcUnit;
	output reg [(NUM_UOPS * 171) - 1:0] OUT_uop;
	integer i;
	integer j;
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				OUT_rfReadValid[i] = 1;
				OUT_rfReadAddr[i * 6+:6] = IN_uop[(i * 124) + 58-:6];
				OUT_rfReadValid[i + NUM_UOPS] = 1;
				OUT_rfReadAddr[(i + NUM_UOPS) * 6+:6] = IN_uop[(i * 124) + 51-:6];
			end
	reg [1:0] outFU [NUM_UOPS - 1:0];
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_UOPS; i = i + 1)
				begin
					OUT_uop[i * 171] <= 0;
					OUT_funcUnit[i * 2+:2] <= 0;
					OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 0;
				end
		end
		else
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (IN_uopValid[i] && (!IN_invalidate || ($signed(IN_uop[(i * 124) + 43-:6] - IN_invalidateSqN) <= 0))) begin
					OUT_uop[(i * 171) + 74-:32] <= IN_uop[(i * 124) + 123-:32];
					OUT_uop[(i * 171) + 25-:6] <= IN_uop[(i * 124) + 43-:6];
					OUT_uop[(i * 171) + 36-:6] <= IN_uop[(i * 124) + 37-:6];
					OUT_uop[(i * 171) + 30-:5] <= IN_uop[(i * 124) + 31-:5];
					OUT_uop[(i * 171) + 42-:6] <= IN_uop[(i * 124) + 26-:6];
					OUT_uop[(i * 171) + 106-:32] <= IN_uop[(i * 124) + 91-:32];
					OUT_uop[(i * 171) + 19-:6] <= IN_uop[(i * 124) + 20-:6];
					OUT_uop[(i * 171) + 13] <= IN_uop[(i * 124) + 14];
					OUT_uop[(i * 171) + 6-:6] <= IN_uop[(i * 124) + 7-:6];
					OUT_uop[(i * 171) + 12-:6] <= IN_uop[(i * 124) + 13-:6];
					OUT_funcUnit[i * 2+:2] <= IN_uop[(i * 124) + 1-:2];
					OUT_uop[i * 171] <= 1;
					if (IN_uop[(i * 124) + 45])
						OUT_uop[(i * 171) + 170-:32] <= IN_uop[(i * 124) + 91-:32];
					else begin : sv2v_autoblock_1
						reg found;
						found = 0;
						for (j = 0; j < NUM_WBS; j = j + 1)
							if (IN_wbHasResult[j] && (IN_uop[(i * 124) + 58-:6] == IN_wbUOp[(j * 92) + 59-:6])) begin
								OUT_uop[(i * 171) + 170-:32] <= IN_wbUOp[(j * 92) + 91-:32];
								found = 1;
							end
						for (j = 0; j < NUM_ZC_FWDS; j = j + 1)
							if (IN_zcFwdValid[j] && (IN_zcFwdTag[j * 6+:6] == IN_uop[(i * 124) + 58-:6])) begin
								OUT_uop[(i * 171) + 170-:32] <= IN_zcFwdResult[j * 32+:32];
								found = 1;
							end
						if (!found)
							OUT_uop[(i * 171) + 170-:32] <= IN_rfReadData[i * 32+:32];
					end
					if (IN_uop[(i * 124) + 44])
						OUT_uop[(i * 171) + 138-:32] <= IN_uop[(i * 124) + 123-:32];
					else begin : sv2v_autoblock_2
						reg found;
						found = 0;
						for (j = 0; j < NUM_WBS; j = j + 1)
							if (IN_wbHasResult[j] && (IN_uop[(i * 124) + 51-:6] == IN_wbUOp[(j * 92) + 59-:6])) begin
								OUT_uop[(i * 171) + 138-:32] <= IN_wbUOp[(j * 92) + 91-:32];
								found = 1;
							end
						for (j = 0; j < NUM_ZC_FWDS; j = j + 1)
							if (IN_zcFwdValid[j] && (IN_zcFwdTag[j * 6+:6] == IN_uop[(i * 124) + 51-:6])) begin
								OUT_uop[(i * 171) + 138-:32] <= IN_zcFwdResult[j * 32+:32];
								found = 1;
							end
						if (!found)
							OUT_uop[(i * 171) + 138-:32] <= IN_rfReadData[(i + NUM_UOPS) * 32+:32];
					end
					case (IN_uop[(i * 124) + 1-:2])
						2'd0: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 4'b0001;
						2'd1: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 4'b0010;
						2'd2: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 4'b0100;
						2'd3: OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 4'b1000;
					endcase
					outFU[i] <= IN_uop[(i * 124) + 1-:2];
				end
				else begin
					OUT_uop[i * 171] <= 0;
					OUT_enableXU[i * NUM_XUS+:NUM_XUS] <= 0;
				end
endmodule
