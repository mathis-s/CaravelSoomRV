module CacheController (
	clk,
	rst,
	branch,
	IN_uop,
	OUT_uop,
	OUT_MC_startRead,
	OUT_MC_writeBack,
	OUT_MC_sramAddr,
	OUT_MC_extAddr,
	OUT_MC_extWBAddr,
	OUT_MC_size,
	IN_MC_busy
);
	parameter NUM_ENTRIES = 4;
	parameter CTABLE_SIZE = 32;
	parameter NUM_INPUTS = 1;
	input wire clk;
	input wire rst;
	input wire [51:0] branch;
	input wire [(NUM_INPUTS * 137) - 1:0] IN_uop;
	output reg [(NUM_INPUTS * 137) - 1:0] OUT_uop;
	output reg OUT_MC_startRead;
	output reg OUT_MC_writeBack;
	output reg [31:0] OUT_MC_sramAddr;
	output reg [31:0] OUT_MC_extAddr;
	output reg [31:0] OUT_MC_extWBAddr;
	output reg [15:0] OUT_MC_size;
	input wire IN_MC_busy;
	integer i;
	integer j;
	LSU_UOp entries [NUM_ENTRIES - 1:0];
	reg [$clog2(NUM_ENTRIES) - 1:0] inIndex;
	reg [$clog2(NUM_ENTRIES) - 1:0] outIndex;
	reg [27:0] ctable [CTABLE_SIZE - 1:0];
	reg [4:0] lruPointer;
	reg [23:0] loadAddr;
	reg loadInProgress;
	reg [4:0] cacheLookupAddr [NUM_INPUTS - 1:0];
	reg cacheLookupFound [NUM_INPUTS - 1:0];
	always @(*)
		for (i = 0; i < NUM_INPUTS; i = i + 1)
			begin
				cacheLookupFound[i] = 0;
				cacheLookupAddr[i] = 5'bxxxxx;
				for (j = 0; j < CTABLE_SIZE; j = j + 1)
					if (ctable[j][3] && (ctable[j][27-:24] == IN_uop[(i * 137) + 136-:24])) begin
						cacheLookupFound[i] = 1;
						cacheLookupAddr[i] = j[4:0];
					end
			end
	reg hasFreeLine;
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < (CTABLE_SIZE - 1); i = i + 1)
				begin
					ctable[i][3] <= 1;
					ctable[i][27-:24] <= i[23:0];
					ctable[i][1] <= 1;
					ctable[i][0] <= 1;
				end
			ctable[CTABLE_SIZE - 1][3] <= 0;
			ctable[CTABLE_SIZE - 1][1] <= 0;
			ctable[CTABLE_SIZE - 1][0] <= 0;
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				begin
					entries[i].valid <= 0;
					inIndex = 0;
					outIndex = 0;
				end
			lruPointer <= 0;
			loadInProgress <= 0;
			OUT_uop.valid <= 0;
			hasFreeLine <= 1;
		end
		else begin
			if (!ctable[lruPointer][0])
				lruPointer <= lruPointer + 1;
			else if (ctable[lruPointer][3] && ctable[lruPointer][2]) begin
				ctable[lruPointer][2] <= 0;
				lruPointer <= lruPointer + 1;
			end
			for (i = 0; i < NUM_INPUTS; i = i + 1)
				if (IN_uop[i * 137] && cacheLookupFound[i]) begin
					ctable[cacheLookupAddr[i]][2] <= 1;
					if (!IN_uop[(i * 137) + 63])
						ctable[cacheLookupAddr[i]][1] <= 1;
				end
			for (i = 0; i < NUM_INPUTS; i = i + 1)
				if (IN_uop[i * 137] && (!branch[51] || ($signed(IN_uop[(i * 137) + 19-:6] - branch[18-:6]) <= 0))) begin
					if (IN_uop[(i * 137) + 136-:8] == 8'hff)
						OUT_uop[i * 137+:137] <= IN_uop[i * 137+:137];
					else if (cacheLookupFound[i]) begin
						OUT_uop[i * 137+:137] <= IN_uop[i * 137+:137];
						OUT_uop[(i * 137) + 136-:32] <= {19'b0000000000000000000, cacheLookupAddr, IN_uop[(i * 137) + 112-:8]};
					end
					else begin
						OUT_uop[i * 137] <= 0;
						entries[inIndex] <= IN_uop[i * 137+:137];
						entries[inIndex].ready <= 0;
						inIndex = inIndex + 1;
					end
				end
				else
					OUT_uop[i * 137] <= 0;
			if (loadInProgress && !IN_MC_busy) begin
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if (entries[i].addr[31:8] == loadAddr)
						entries[i].ready <= 1;
				loadInProgress <= 0;
			end
			else if (((hasFreeLine && (inIndex != outIndex)) && !IN_MC_busy) && !entries[outIndex].ready) begin
				OUT_MC_startRead <= 1;
				OUT_MC_writeBack <= 0;
				OUT_MC_sramAddr <= {27'b000000000000000000000000000, lruPointer} << 6;
				OUT_MC_extAddr <= entries[outIndex].addr & 32'hffffff00;
				OUT_MC_size <= 16'd64;
				ctable[lruPointer][0] <= 0;
				ctable[lruPointer][3] <= 1;
				ctable[lruPointer][2] <= 1;
				loadInProgress <= 1;
				loadAddr <= entries[outIndex].addr[31:8];
			end
			else
				OUT_MC_startRead <= 0;
		end
endmodule
