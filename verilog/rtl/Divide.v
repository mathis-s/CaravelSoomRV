module Divide (
	clk,
	rst,
	en,
	OUT_busy,
	IN_branch,
	IN_uop,
	OUT_uop
);
	input wire clk;
	input wire rst;
	input wire en;
	output wire OUT_busy;
	input wire [51:0] IN_branch;
	input wire [170:0] IN_uop;
	output reg [91:0] OUT_uop;
	reg [170:0] uop;
	reg [5:0] cnt;
	reg [63:0] r;
	reg [31:0] q;
	reg [31:0] d;
	reg invert;
	reg running;
	assign OUT_busy = running && ((cnt != 0) && (cnt != 63));
	always @(posedge clk)
		if (rst) begin
			OUT_uop[0] <= 0;
			running <= 0;
		end
		else if ((en && IN_uop[0]) && (!IN_branch[51] || ($signed(IN_uop[25-:6] - IN_branch[18-:6]) <= 0))) begin
			running <= 1;
			uop <= IN_uop;
			cnt <= 31;
			if (IN_uop[42-:6] == 6'd0) begin
				invert <= IN_uop[170] ^ IN_uop[138];
				r <= {32'b00000000000000000000000000000000, (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32])};
				d <= (IN_uop[138] ? -IN_uop[138-:32] : IN_uop[138-:32]);
			end
			else if (IN_uop[42-:6] == 6'd2) begin
				invert <= IN_uop[170];
				r <= {32'b00000000000000000000000000000000, (IN_uop[170] ? -IN_uop[170-:32] : IN_uop[170-:32])};
				d <= (IN_uop[138] ? -IN_uop[138-:32] : IN_uop[138-:32]);
			end
			else begin
				invert <= 0;
				r <= {32'b00000000000000000000000000000000, IN_uop[170-:32]};
				d <= IN_uop[138-:32];
			end
			OUT_uop[0] <= 0;
		end
		else if (running) begin
			if (IN_branch[51] && ($signed(IN_branch[18-:6] - uop[25-:6]) < 0)) begin
				running <= 0;
				uop[0] <= 0;
				OUT_uop[0] <= 0;
			end
			else if (cnt != 63) begin
				if (!r[63]) begin
					q[cnt[4:0]] <= 1;
					r <= (2 * r) - {d, 32'b00000000000000000000000000000000};
				end
				else begin
					q[cnt[4:0]] <= 0;
					r <= (2 * r) + {d, 32'b00000000000000000000000000000000};
				end
				cnt <= cnt - 1;
				OUT_uop[0] <= 0;
			end
			else begin : sv2v_autoblock_1
				reg [31:0] qRestored;
				reg [31:0] remainder;
				qRestored = (q - ~q) - (r[63] ? 1 : 0);
				remainder = (r[63] ? r[63:32] + d : r[63:32]);
				running <= 0;
				OUT_uop[48-:6] <= uop[25-:6];
				OUT_uop[59-:6] <= uop[36-:6];
				OUT_uop[53-:5] <= uop[30-:5];
				OUT_uop[42-:32] <= uop[106-:32];
				OUT_uop[10] <= 0;
				OUT_uop[9] <= 0;
				OUT_uop[8-:6] <= 0;
				OUT_uop[2-:2] <= 2'd0;
				OUT_uop[0] <= 1;
				if ((uop[42-:6] == 6'd2) || (uop[42-:6] == 6'd3))
					OUT_uop[91-:32] <= (invert ? -remainder : remainder);
				else
					OUT_uop[91-:32] <= (invert ? -qRestored : qRestored);
			end
		end
		else begin
			OUT_uop[0] <= 0;
			running <= 0;
		end
endmodule
