module RF (
	clk,
	rst,
	IN_readEnable,
	IN_readAddress,
	OUT_readData,
	IN_writeEnable,
	IN_writeAddress,
	IN_writeData
);
	parameter NUM_READ = 4;
	parameter NUM_WRITE = 3;
	parameter SIZE = 64;
	input wire clk;
	input wire rst;
	input wire [NUM_READ - 1:0] IN_readEnable;
	input wire [(NUM_READ * 6) - 1:0] IN_readAddress;
	output reg [(NUM_READ * 32) - 1:0] OUT_readData;
	input wire [NUM_WRITE - 1:0] IN_writeEnable;
	input wire [(NUM_WRITE * 6) - 1:0] IN_writeAddress;
	input wire [(NUM_WRITE * 32) - 1:0] IN_writeData;
	integer i;
	reg [31:0] mem [SIZE - 1:0];
	wire [31:0] tt = mem[22];
	always @(*)
		for (i = 0; i < NUM_READ; i = i + 1)
			if (IN_readEnable[i])
				OUT_readData[i * 32+:32] = mem[IN_readAddress[i * 6+:6]];
			else
				OUT_readData[i * 32+:32] = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
	always @(posedge clk) begin
		if (rst)
			;
		else
			for (i = 0; i < NUM_WRITE; i = i + 1)
				if (IN_writeEnable[i])
					mem[IN_writeAddress[i * 6+:6]] <= IN_writeData[i * 32+:32];
		mem[0] <= 0;
	end
endmodule
