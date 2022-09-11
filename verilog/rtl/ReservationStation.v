module ReservationStation (
	clk,
	rst,
	frontEn,
	IN_DIV_doNotIssue,
	IN_MUL_doNotIssue,
	IN_stall,
	IN_uopValid,
	IN_uop,
	IN_resultValid,
	IN_resultUOp,
	IN_invalidate,
	IN_invalidateSqN,
	IN_nextCommitSqN,
	OUT_valid,
	OUT_uop,
	OUT_free
);
	parameter NUM_UOPS = 2;
	parameter QUEUE_SIZE = 8;
	parameter RESULT_BUS_COUNT = 3;
	parameter STORE_QUEUE_SIZE = 8;
	input wire clk;
	input wire rst;
	input wire frontEn;
	input wire IN_DIV_doNotIssue;
	input wire IN_MUL_doNotIssue;
	input wire [NUM_UOPS - 1:0] IN_stall;
	input wire [NUM_UOPS - 1:0] IN_uopValid;
	input wire [(NUM_UOPS * 124) - 1:0] IN_uop;
	input wire [RESULT_BUS_COUNT - 1:0] IN_resultValid;
	input wire [(RESULT_BUS_COUNT * 92) - 1:0] IN_resultUOp;
	input wire IN_invalidate;
	input wire [5:0] IN_invalidateSqN;
	input wire [5:0] IN_nextCommitSqN;
	output reg [NUM_UOPS - 1:0] OUT_valid;
	output reg [(NUM_UOPS * 124) - 1:0] OUT_uop;
	output reg [4:0] OUT_free;
	integer i;
	integer j;
	integer k;
	reg [4:0] freeEntries;
	reg [123:0] queue [QUEUE_SIZE - 1:0];
	reg [4:0] queueInfo [QUEUE_SIZE - 1:0];
	reg enqValid;
	reg [2:0] deqIndex [NUM_UOPS - 1:0];
	reg deqValid [NUM_UOPS - 1:0];
	reg [32:0] reservedWBs [NUM_UOPS - 1:0];
	always @(*)
		for (i = NUM_UOPS - 1; i >= 0; i = i - 1)
			begin
				deqValid[i] = 0;
				deqIndex[i] = 3'bxxx;
				for (j = 0; j < QUEUE_SIZE; j = j + 1)
					if (queueInfo[j][0] && (!deqValid[1] || (deqIndex[1] != j[2:0])))
						if ((((((((((((queue[j][59] || (IN_resultValid[0] && (IN_resultUOp[59-:6] == queue[j][58-:6]))) || (IN_resultValid[1] && (IN_resultUOp[151-:6] == queue[j][58-:6]))) || (IN_resultValid[2] && (IN_resultUOp[243-:6] == queue[j][58-:6]))) || (((OUT_valid[0] && (OUT_uop[31-:5] != 0)) && (OUT_uop[37-:6] == queue[j][58-:6])) && (OUT_uop[1-:2] == 2'd0))) || (((OUT_valid[1] && (OUT_uop[155-:5] != 0)) && (OUT_uop[161-:6] == queue[j][58-:6])) && (OUT_uop[125-:2] == 2'd0))) && (((((queue[j][52] || (IN_resultValid[0] && (IN_resultUOp[59-:6] == queue[j][51-:6]))) || (IN_resultValid[1] && (IN_resultUOp[151-:6] == queue[j][51-:6]))) || (IN_resultValid[2] && (IN_resultUOp[243-:6] == queue[j][51-:6]))) || (((OUT_valid[0] && (OUT_uop[31-:5] != 0)) && (OUT_uop[37-:6] == queue[j][51-:6])) && (OUT_uop[1-:2] == 2'd0))) || (((OUT_valid[1] && (OUT_uop[155-:5] != 0)) && (OUT_uop[161-:6] == queue[j][51-:6])) && (OUT_uop[125-:2] == 2'd0)))) && ((i == 0) || ((!queueInfo[j][2] && !queueInfo[j][3]) && (queue[j][1-:2] != 2'd3)))) && ((i == 1) || (queue[j][1-:2] != 2'd2))) && (!IN_DIV_doNotIssue || (queue[j][1-:2] != 2'd3))) && (!IN_MUL_doNotIssue || (queue[j][1-:2] != 2'd2))) && (!queueInfo[j][4] || (i == 1))) && ((queue[j][1-:2] != 2'd0) || !reservedWBs[i][0])) begin
							deqValid[i] = 1;
							deqIndex[i] = j[2:0];
						end
			end
	reg [2:0] insertIndex [NUM_UOPS - 1:0];
	reg insertAvail [NUM_UOPS - 1:0];
	always @(*)
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				insertAvail[i] = 0;
				insertIndex[i] = 3'bxxx;
				if (IN_uopValid[i])
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						if (!queueInfo[j][0] && (((i == 0) || !insertAvail[0]) || (insertIndex[0] != j[2:0]))) begin
							insertAvail[i] = 1;
							insertIndex[i] = j[2:0];
						end
			end
	always @(posedge clk) begin
		for (i = 0; i < NUM_UOPS; i = i + 1)
			begin
				reservedWBs[i] <= {1'b0, reservedWBs[i][32:1]};
				OUT_valid[i] <= 0;
			end
		if (!rst) begin
			for (i = 0; i < RESULT_BUS_COUNT; i = i + 1)
				if (IN_resultValid[i])
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						begin
							if ((queue[j][59] == 0) && (queue[j][58-:6] == IN_resultUOp[(i * 92) + 59-:6]))
								queue[j][59] <= 1;
							if ((queue[j][52] == 0) && (queue[j][51-:6] == IN_resultUOp[(i * 92) + 59-:6]))
								queue[j][52] <= 1;
						end
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if ((OUT_valid[i] && (OUT_uop[(i * 124) + 31-:5] != 0)) && (OUT_uop[(i * 124) + 1-:2] == 2'd0))
					for (j = 0; j < QUEUE_SIZE; j = j + 1)
						begin
							if ((queue[j][59] == 0) && (queue[j][58-:6] == OUT_uop[(i * 124) + 37-:6]))
								queue[j][59] <= 1;
							if ((queue[j][52] == 0) && (queue[j][51-:6] == OUT_uop[(i * 124) + 37-:6]))
								queue[j][52] <= 1;
						end
		end
		if (rst) begin
			for (i = 0; i < QUEUE_SIZE; i = i + 1)
				queueInfo[i][0] <= 0;
			freeEntries = 8;
			OUT_free <= 8;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				reservedWBs[i] <= 0;
		end
		else if (IN_invalidate) begin
			for (i = 0; i < QUEUE_SIZE; i = i + 1)
				if ($signed(queue[i][43-:6] - IN_invalidateSqN) > 0) begin
					queueInfo[i][0] <= 0;
					if (queueInfo[i][0])
						freeEntries = freeEntries + 1;
				end
		end
		else begin
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (!IN_stall[i])
					if (deqValid[i]) begin
						OUT_uop[i * 124+:124] <= queue[deqIndex[i]];
						freeEntries = freeEntries + 1;
						OUT_valid[i] <= 1;
						queueInfo[deqIndex[i]][0] <= 0;
						reservedWBs[i] <= {queue[deqIndex[i]][1-:2] == 2'd3, reservedWBs[i][32:10], (queue[deqIndex[i]][1-:2] == 2'd2) | reservedWBs[i][9], reservedWBs[i][8:1]};
					end
					else
						OUT_valid[i] <= 0;
			for (i = 0; i < NUM_UOPS; i = i + 1)
				if (frontEn && IN_uopValid[i]) begin : sv2v_autoblock_1
					reg [123:0] temp;
					temp = IN_uop[i * 124+:124];
					for (k = 0; k < RESULT_BUS_COUNT; k = k + 1)
						if (IN_resultValid[k]) begin
							if (!temp[59] && (temp[58-:6] == IN_resultUOp[(k * 92) + 59-:6]))
								temp[59] = 1;
							if (!temp[52] && (temp[51-:6] == IN_resultUOp[(k * 92) + 59-:6]))
								temp[52] = 1;
						end
					queue[insertIndex[i]] <= temp;
					queueInfo[insertIndex[i]][4] <= (temp[1-:2] == 2'd0) && ((((((((((temp[26-:6] == 6'd10) || (temp[26-:6] == 6'd11)) || (temp[26-:6] == 6'd12)) || (temp[26-:6] == 6'd13)) || (temp[26-:6] == 6'd14)) || (temp[26-:6] == 6'd15)) || (temp[26-:6] == 6'd18)) || (temp[26-:6] == 6'd19)) || (temp[26-:6] == 6'd20)) || (temp[26-:6] == 6'd21));
					queueInfo[insertIndex[i]][3] <= (temp[1-:2] == 2'd1) && (((temp[26-:6] == 6'd5) || (temp[26-:6] == 6'd6)) || (temp[26-:6] == 6'd7));
					queueInfo[insertIndex[i]][2] <= (temp[1-:2] == 2'd1) && (((((temp[26-:6] == 6'd0) || (temp[26-:6] == 6'd1)) || (temp[26-:6] == 6'd2)) || (temp[26-:6] == 6'd3)) || (temp[26-:6] == 6'd4));
					queueInfo[insertIndex[i]][0] <= 1;
					freeEntries = freeEntries - 1;
				end
		end
		OUT_free <= freeEntries;
	end
endmodule
