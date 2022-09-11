module LoadBuffer (
	clk,
	rst,
	commitSqN,
	valid,
	isLoad,
	pc,
	addr,
	sqN,
	loadSqN,
	storeSqN,
	IN_branch,
	OUT_branch,
	OUT_maxLoadSqN
);
	parameter NUM_PORTS = 1;
	parameter NUM_ENTRIES = 8;
	input wire clk;
	input wire rst;
	input wire [5:0] commitSqN;
	input wire [NUM_PORTS - 1:0] valid;
	input wire [NUM_PORTS - 1:0] isLoad;
	input wire [(NUM_PORTS * 32) - 1:0] pc;
	input wire [(NUM_PORTS * 32) - 1:0] addr;
	input wire [(NUM_PORTS * 6) - 1:0] sqN;
	input wire [(NUM_PORTS * 6) - 1:0] loadSqN;
	input wire [(NUM_PORTS * 6) - 1:0] storeSqN;
	input wire [51:0] IN_branch;
	output reg [51:0] OUT_branch;
	output reg [5:0] OUT_maxLoadSqN;
	integer i;
	integer j;
	reg [36:0] entries [NUM_ENTRIES - 1:0];
	reg [5:0] baseIndex;
	reg [5:0] indexIn;
	reg mispredict [NUM_PORTS - 1:0];
	always @(posedge clk)
		if (rst) begin
			for (i = 0; i < NUM_ENTRIES; i = i + 1)
				entries[i][36] <= 0;
			baseIndex = 0;
			OUT_branch[51] <= 0;
			OUT_maxLoadSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
		else begin
			if (IN_branch[51]) begin
				for (i = 0; i < NUM_ENTRIES; i = i + 1)
					if ($signed(entries[i][35-:6] - IN_branch[18-:6]) > 0)
						entries[i][36] <= 0;
				if (IN_branch[0])
					baseIndex = IN_branch[6-:6];
			end
			else if (entries[0][36] && ($signed(commitSqN - entries[0][35-:6]) > 0)) begin
				for (i = 0; i < (NUM_ENTRIES - 1); i = i + 1)
					entries[i] <= entries[i + 1];
				entries[NUM_ENTRIES - 1][36] <= 0;
				baseIndex = baseIndex + 1;
			end
			for (i = 0; i < NUM_PORTS; i = i + 1)
				if (valid[i] && (!IN_branch[51] || ($signed(sqN[i * 6+:6] - IN_branch[18-:6]) <= 0))) begin
					if (isLoad[i]) begin : sv2v_autoblock_1
						reg [2:0] index;
						index = loadSqN[(i * 6) + 2-:3] - baseIndex[2:0];
						entries[index][35-:6] <= sqN[i * 6+:6];
						entries[index][29-:30] <= addr[(i * 32) + 31-:30];
						entries[index][36] <= 1;
					end
					else begin : sv2v_autoblock_2
						reg temp;
						temp = 0;
						for (j = 0; j < NUM_ENTRIES; j = j + 1)
							if ((entries[j][36] && (entries[j][29-:30] == addr[(i * 32) + 31-:30])) && ($signed(sqN[i * 6+:6] - entries[j][35-:6]) <= 0))
								temp = 1;
						if (temp) begin
							OUT_branch[51] <= 1;
							OUT_branch[50-:32] <= pc[i * 32+:32];
							OUT_branch[18-:6] <= sqN[i * 6+:6];
							OUT_branch[6-:6] <= loadSqN[i * 6+:6];
							OUT_branch[12-:6] <= storeSqN[i * 6+:6];
							OUT_branch[0] <= 0;
						end
						else
							OUT_branch[51] <= 0;
					end
				end
				else
					OUT_branch[51] <= 0;
			OUT_maxLoadSqN <= (baseIndex + NUM_ENTRIES[5:0]) - 1;
		end
endmodule
