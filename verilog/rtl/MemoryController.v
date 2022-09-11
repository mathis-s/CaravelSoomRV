module MemoryController (
	clk,
	rst,
	clkMem,
	IN_bus,
	OUT_busOEn,
	OUT_bus,
	OUT_busClk,
	OUT_busClkOEn,
	OUT_busActive,
	OUT_busActiveOEn,
	IN_busWait,
	OUT_busWaitOEn,
	OUT_busRst,
	OUT_busRstOEn,
	OUT_sramData,
	OUT_sramAddr,
	IN_sramData,
	OUT_sramCE,
	OUT_sramWE,
	OUT_sramWM,
	OUT_sramUsed,
	OUT_sramUsedWarn,
	IN_IF_startRead,
	IN_IF_writeBack,
	IN_IF_sramAddr,
	IN_IF_extAddr,
	IN_IF_extWBAddr,
	IN_IF_size,
	OUT_IF_busy
);
	input wire clk;
	input wire rst;
	input wire clkMem;
	input wire [15:0] IN_bus;
	output reg [15:0] OUT_busOEn;
	output reg [15:0] OUT_bus;
	output wire OUT_busClk;
	output wire OUT_busClkOEn;
	output reg OUT_busActive;
	output wire OUT_busActiveOEn;
	input wire IN_busWait;
	output wire OUT_busWaitOEn;
	output wire OUT_busRst;
	output wire OUT_busRstOEn;
	output reg [31:0] OUT_sramData;
	output reg [31:0] OUT_sramAddr;
	input wire [31:0] IN_sramData;
	output reg OUT_sramCE;
	output reg OUT_sramWE;
	output reg [3:0] OUT_sramWM;
	output reg OUT_sramUsed;
	output reg OUT_sramUsedWarn;
	input wire IN_IF_startRead;
	input wire IN_IF_writeBack;
	input wire [31:0] IN_IF_sramAddr;
	input wire [31:0] IN_IF_extAddr;
	input wire [31:0] IN_IF_extWBAddr;
	input wire [15:0] IN_IF_size;
	output reg OUT_IF_busy;
	assign OUT_busClkOEn = 1;
	assign OUT_busActiveOEn = 1;
	assign OUT_busClk = clkMem;
	assign OUT_busWaitOEn = 0;
	assign OUT_busRstOEn = 1;
	assign OUT_busRst = rst;
	reg [3:0] state;
	reg [3:0] returnState;
	reg [15:0] xferCnt;
	reg [15:0] curCnt;
	reg [3:0] delayCycles;
	reg doInc;
	always @(posedge clkMem)
		if (rst) begin
			state <= 0;
			OUT_sramUsed <= 0;
			OUT_sramCE <= 1;
			OUT_sramWE <= 1;
			OUT_sramWM <= 4'b0000;
			OUT_busOEn <= 16'hffff;
			OUT_busActive <= 0;
		end
		else
			case (state)
				0:
					if (IN_IF_startRead) begin
						if (IN_IF_writeBack) begin
							OUT_IF_busy <= 1;
							OUT_sramUsedWarn <= 1;
							OUT_sramCE <= 1;
							OUT_sramWE <= 1;
							OUT_sramWM <= 4'b1111;
							delayCycles <= 0;
							OUT_busOEn <= 16'hffff;
							OUT_bus <= {1'b1, IN_IF_extWBAddr[31:17]};
							OUT_busActive <= 1;
							xferCnt <= IN_IF_size;
							state <= 1;
						end
						else begin
							OUT_IF_busy <= 1;
							OUT_sramUsedWarn <= 1;
							OUT_sramCE <= 1;
							OUT_sramWE <= 1;
							OUT_sramWM <= 1;
							delayCycles <= 0;
							OUT_busOEn <= 16'hffff;
							OUT_bus <= {1'b0, IN_IF_extAddr[31:17]};
							OUT_busActive <= 1;
							xferCnt <= IN_IF_size;
							state <= 4;
						end
					end
					else begin
						OUT_IF_busy <= 0;
						OUT_sramUsedWarn <= 0;
						OUT_sramUsed <= 0;
						OUT_busActive <= 0;
						OUT_busOEn <= 16'hffff;
						xferCnt <= 0;
					end
				1: begin
					OUT_bus <= IN_IF_extWBAddr[16:1];
					state <= 2;
				end
				2: begin
					if (IN_busWait) begin
						OUT_sramCE <= 0;
						OUT_sramWE <= 1;
						OUT_sramAddr <= IN_IF_sramAddr;
						doInc <= 1;
						curCnt <= 0;
						if (delayCycles < 8)
							delayCycles <= delayCycles + 1;
						else
							OUT_sramUsed <= 1;
					end
					if (!IN_busWait) begin
						if (doInc)
							OUT_bus <= IN_sramData[15:0];
						else
							OUT_bus <= IN_sramData[31:16];
						if (doInc) begin
							curCnt <= curCnt + 1;
							OUT_sramAddr <= OUT_sramAddr + 1;
							if (curCnt == xferCnt) begin
								OUT_busActive <= 0;
								state <= 3;
								OUT_sramCE <= 1;
							end
							doInc <= 0;
						end
						else
							doInc <= 1;
					end
				end
				3: begin
					OUT_busActive <= 1;
					OUT_busOEn <= 16'hffff;
					OUT_bus <= {1'b0, IN_IF_extAddr[31:17]};
					state <= 4;
				end
				4: begin
					OUT_bus <= IN_IF_extAddr[16:1];
					state <= 5;
				end
				5:
					if (IN_busWait) begin
						OUT_sramCE <= 1;
						OUT_sramWE <= 0;
						OUT_sramWM <= 4'b0000;
						OUT_sramAddr <= IN_IF_sramAddr - 1;
						OUT_busOEn <= 16'h0000;
						curCnt <= 0;
						doInc <= 1;
						if (delayCycles < 8)
							delayCycles <= delayCycles + 1;
						else
							OUT_sramUsed <= 1;
					end
					else if (doInc) begin
						if (curCnt == xferCnt) begin
							state <= 0;
							OUT_busActive <= 0;
							OUT_sramCE <= 1;
							OUT_sramWE <= 1;
							OUT_IF_busy <= 0;
						end
						else begin
							OUT_sramWM <= 4'b0011;
							OUT_sramCE <= 0;
							OUT_sramWE <= 0;
							OUT_sramData <= {16'b0000000000000000, IN_bus};
							OUT_sramAddr <= OUT_sramAddr + 1;
							curCnt <= curCnt + 1;
							doInc <= 0;
						end
					end
					else begin
						OUT_sramWM <= 4'b1100;
						OUT_sramCE <= 0;
						OUT_sramWE <= 0;
						OUT_sramData <= {IN_bus, 16'b0000000000000000};
						doInc <= 1;
					end
			endcase
endmodule
