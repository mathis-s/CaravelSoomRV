module StoreQueue (
	clk,
	rst,
	IN_uop,
	IN_curSqN,
	IN_branch,
	IN_MEM_data,
	OUT_MEM_addr,
	OUT_MEM_data,
	OUT_MEM_we,
	OUT_MEM_ce,
	OUT_MEM_wm,
	IN_CSR_data,
	OUT_CSR_ce,
	OUT_uop,
	OUT_maxStoreSqN,
	IN_IO_busy
);
	parameter NUM_PORTS = 1;
	parameter NUM_ENTRIES = 8;
	input wire clk;
	input wire rst;
	input wire [(NUM_PORTS * 137) - 1:0] IN_uop;
	input wire [5:0] IN_curSqN;
	input wire [51:0] IN_branch;
	input wire [(NUM_PORTS * 32) - 1:0] IN_MEM_data;
	output reg [(NUM_PORTS * 30) - 1:0] OUT_MEM_addr;
	output reg [(NUM_PORTS * 32) - 1:0] OUT_MEM_data;
	output reg [NUM_PORTS - 1:0] OUT_MEM_we;
	output reg [NUM_PORTS - 1:0] OUT_MEM_ce;
	output reg [(NUM_PORTS * 4) - 1:0] OUT_MEM_wm;
	input wire [(NUM_PORTS * 32) - 1:0] IN_CSR_data;
	output reg [NUM_PORTS - 1:0] OUT_CSR_ce;
	output reg [(NUM_PORTS * 92) - 1:0] OUT_uop;
	output reg [5:0] OUT_maxStoreSqN;
	input wire IN_IO_busy;
	integer i;
	integer j;
	reg [73:0] entries [NUM_ENTRIES - 1:0];
	reg [5:0] baseIndex;
	reg doingDequeue;
	reg isCsrRead [NUM_PORTS - 1:0];
	reg isCsrWrite [NUM_PORTS - 1:0];
	reg [29:0] iAddr [NUM_PORTS - 1:0];
	reg [5:0] iSqN [NUM_PORTS - 1:0];
	reg [3:0] iMask [NUM_PORTS - 1:0];
	reg [31:0] iData [NUM_PORTS - 1:0];
	reg [136:0] i0 [NUM_PORTS - 1:0];
	reg [136:0] i1 [NUM_PORTS - 1:0];
	reg i0_isCsrRead [NUM_PORTS - 1:0];
	reg i1_isCsrRead [NUM_PORTS - 1:0];
	reg [31:0] queueLookupData [NUM_PORTS - 1:0];
	reg [3:0] queueLookupMask [NUM_PORTS - 1:0];
	reg didCSRwrite;
	always @(*)
		for (i = 0; i < NUM_PORTS; i = i + 1)
			begin : sv2v_autoblock_1
				reg [31:0] result;
				result = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
				if (i1[i][63]) begin : sv2v_autoblock_2
					reg [31:0] data;
					data[31:24] = (queueLookupMask[i][3] ? queueLookupData[i][31:24] : (i1_isCsrRead[i] ? IN_CSR_data[(i * 32) + 31-:8] : IN_MEM_data[(i * 32) + 31-:8]));
					data[23:16] = (queueLookupMask[i][2] ? queueLookupData[i][23:16] : (i1_isCsrRead[i] ? IN_CSR_data[(i * 32) + 23-:8] : IN_MEM_data[(i * 32) + 23-:8]));
					data[15:8] = (queueLookupMask[i][1] ? queueLookupData[i][15:8] : (i1_isCsrRead[i] ? IN_CSR_data[(i * 32) + 15-:8] : IN_MEM_data[(i * 32) + 15-:8]));
					data[7:0] = (queueLookupMask[i][0] ? queueLookupData[i][7:0] : (i1_isCsrRead[i] ? IN_CSR_data[(i * 32) + 7-:8] : IN_MEM_data[(i * 32) + 7-:8]));
					case (i1[i][65-:2])
						0: begin
							case (i1[i][67-:2])
								0: result[7:0] = data[7:0];
								1: result[7:0] = data[15:8];
								2: result[7:0] = data[23:16];
								3: result[7:0] = data[31:24];
							endcase
							result[31:8] = {24 {(i1[i][68] ? result[7] : 1'b0)}};
						end
						1: begin
							case (i1[i][67-:2])
								default: result[15:0] = data[15:0];
								2: result[15:0] = data[31:16];
							endcase
							result[31:16] = {16 {(i1[i][68] ? result[15] : 1'b0)}};
						end
						default: result = data;
					endcase
				end
				OUT_uop[(i * 92) + 91-:32] = result;
				OUT_uop[(i * 92) + 59-:6] = i1[i][30-:6];
				OUT_uop[(i * 92) + 53-:5] = (i1[i][1] ? i1[i][127:123] : i1[i][24-:5]);
				OUT_uop[(i * 92) + 48-:6] = i1[i][19-:6];
				OUT_uop[(i * 92) + 42-:32] = i1[i][62-:32];
				OUT_uop[i * 92] = i1[i][0];
				OUT_uop[(i * 92) + 2-:2] = (i1[i][1] ? 2'd3 : 2'd0);
				OUT_uop[(i * 92) + 10] = 0;
				OUT_uop[(i * 92) + 9] = i1[i][122];
				OUT_uop[(i * 92) + 8-:6] = i1[i][121:116];
			end
	always @(*) begin
		doingDequeue = 0;
		for (i = 0; i < NUM_PORTS; i = i + 1)
			begin
				isCsrRead[i] = 0;
				isCsrWrite[i] = 0;
				if (((!rst && IN_uop[i * 137]) && IN_uop[(i * 137) + 63]) && (!IN_branch[51] || ($signed(IN_uop[(i * 137) + 19-:6] - IN_branch[18-:6]) <= 0))) begin
					OUT_MEM_data[i * 32+:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
					OUT_MEM_addr[i * 30+:30] = IN_uop[(i * 137) + 136-:30];
					OUT_MEM_we[i] = 1;
					OUT_MEM_wm[i * 4+:4] = 4'bxxxx;
					if (IN_uop[(i * 137) + 136-:8] == 8'hff) begin
						OUT_MEM_ce[i] = 1;
						OUT_CSR_ce[i] = 0;
						isCsrRead[i] = 1;
					end
					else begin
						OUT_MEM_ce[i] = 0;
						OUT_CSR_ce[i] = 1;
					end
				end
				else if (((((!rst && (i == 0)) && entries[0][73]) && !IN_branch[51]) && entries[0][72]) && (!(IN_IO_busy || didCSRwrite) || (entries[0][65:58] != 8'hff))) begin
					doingDequeue = 1;
					OUT_MEM_data[i * 32+:32] = entries[0][35-:32];
					OUT_MEM_addr[i * 30+:30] = entries[0][65-:30];
					OUT_MEM_we[i] = 0;
					OUT_MEM_wm[i * 4+:4] = entries[0][3-:4];
					if (entries[0][65:58] == 8'hff) begin
						OUT_MEM_ce[i] = 1;
						OUT_CSR_ce[i] = 0;
						isCsrWrite[i] = 1;
					end
					else begin
						OUT_MEM_ce[i] = 0;
						OUT_CSR_ce[i] = 1;
					end
				end
				else begin
					OUT_MEM_data[i * 32+:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
					OUT_MEM_addr[i * 30+:30] = 30'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
					OUT_MEM_we[i] = 1'b1;
					OUT_MEM_ce[i] = 1'b1;
					OUT_MEM_wm[i * 4+:4] = 4'bxxxx;
					OUT_CSR_ce[i] = 1'b1;
				end
			end
		for (j = 0; j < NUM_PORTS; j = j + 1)
			begin
				iMask[j] = 0;
				iData[j] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if (((i0[j][63] && entries[i][73]) && (entries[i][65-:30] == i0[j][136:107])) && ($signed(entries[i][71-:6] - i0[j][19-:6]) < 0)) begin
						if (entries[i][0])
							iData[j][7:0] = entries[i][11:4];
						if (entries[i][1])
							iData[j][15:8] = entries[i][19:12];
						if (entries[i][2])
							iData[j][23:16] = entries[i][27:20];
						if (entries[i][3])
							iData[j][31:24] = entries[i][35:28];
						iMask[j] = iMask[j] | entries[i][3-:4];
					end
			end
	end
	always @(posedge clk) begin
		didCSRwrite <= 0;
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				entries[i][73] <= 0;
			for (i = 0; i < NUM_PORTS; i = i + 1)
				begin
					i0[i][0] <= 0;
					i1[i][0] <= 0;
				end
			baseIndex = 0;
			OUT_maxStoreSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
		else begin
			if (doingDequeue) begin
				for (i = 0; i < (NUM_ENTRIES - 1); i = i + 1)
					entries[i] <= entries[i + 1];
				entries[NUM_ENTRIES - 1][73] <= 0;
				didCSRwrite <= isCsrWrite[0];
				baseIndex = baseIndex + 1;
			end
			else if (IN_branch[51]) begin
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if ($signed(entries[i][71-:6] - IN_branch[18-:6]) > 0)
						entries[i][73] <= 0;
				if (IN_branch[0])
					baseIndex = IN_branch[12-:6] + 1;
			end
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				if ($signed(IN_curSqN - entries[i][71-:6]) > 0)
					entries[i][72] <= 1;
			for (i = 0; i < NUM_PORTS; i = i + 1)
				if (((IN_uop[i * 137] && !IN_uop[(i * 137) + 63]) && (!IN_branch[51] || ($signed(IN_uop[(i * 137) + 19-:6] - IN_branch[18-:6]) <= 0))) && !IN_uop[(i * 137) + 1]) begin : sv2v_autoblock_3
					reg [2:0] index;
					index = IN_uop[(i * 137) + 10-:3] - baseIndex[2:0];
					entries[index][73] <= 1;
					entries[index][72] <= 0;
					entries[index][71-:6] <= IN_uop[(i * 137) + 19-:6];
					entries[index][65-:30] <= IN_uop[(i * 137) + 136-:30];
					entries[index][35-:32] <= IN_uop[(i * 137) + 104-:32];
					entries[index][3-:4] <= IN_uop[(i * 137) + 72-:4];
				end
			for (i = 0; i < NUM_PORTS; i = i + 1)
				begin
					if (IN_uop[i * 137] && (!IN_branch[51] || ($signed(IN_uop[(i * 137) + 19-:6] - IN_branch[18-:6]) <= 0))) begin
						i0[i] <= IN_uop[i * 137+:137];
						i0_isCsrRead[i] <= isCsrRead[i];
					end
					else
						i0[i][0] <= 0;
					if (i0[i][0] && (!IN_branch[51] || ($signed(i0[i][19-:6] - IN_branch[18-:6]) <= 0))) begin
						if (i0[i][63]) begin
							queueLookupData[i] <= iData[i];
							queueLookupMask[i] <= iMask[i];
						end
						i1[i] <= i0[i];
						i1_isCsrRead[i] <= i0_isCsrRead[i];
					end
					else
						i1[i][0] <= 0;
				end
			OUT_maxStoreSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
	end
endmodule
