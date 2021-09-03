module Pfxsum #(
	// length of integers in bits
	parameter IWIDTH = 8,
	// length of array to sum
	parameter V_LEN = 16
) (
	input wire clk,
	input wire valid_in,
	input wire [V_LEN * IWIDTH-1:0] ivec,
	output reg valid_out, 
	output reg [V_LEN * IWIDTH-1:0] ovec
);

localparam UP = 0;
localparam INT = 1;
localparam DOWN = 2;
localparam DONE = 3;

reg [7:0] pfxsum_state;
// current level for sweep, log2-based
reg [15:0] level = 0;
// temporary array for down sweep
reg [IWIDTH-1:0] tmp [V_LEN-1:0];
// in-place array to compute pfxsum
reg [IWIDTH-1:0] vec [V_LEN-1:0];
// to check whether last element is zeroed out
reg zeroed = 0;

wire [IWIDTH-1:0] lvals [V_LEN-1:0];
wire [IWIDTH-1:0] rvals [V_LEN-1:0];

genvar n;
generate
for (n = 0; n < V_LEN; n = n + 1) begin
	assign lvals[n] = n + 2 ** level - 1;
	assign rvals[n] = n + 2 ** (level + 1) - 1;
	
	always @(posedge clk) begin
		// initialize vec, unflatten into 2d array
		if (valid_in) vec[n] <= ivec[(n+1)*IWIDTH-1:n*IWIDTH];
		// reflatten vec for output
		ovec[(n+1)*IWIDTH-1:n*IWIDTH] <= vec[n];

		if (rvals[n] < V_LEN & n % (2 ** (level+1)) == 0) begin
			if (pfxsum_state == UP)
				vec[rvals[n]] <= vec[lvals[n]] + vec[rvals[n]];
			if (pfxsum_state == DOWN) begin
				vec[lvals[n]] <= vec[rvals[n]];
				vec[rvals[n]] <= vec[lvals[n]] + vec[rvals[n]];
			end
		end
	end
end
endgenerate

// state machine for stages of sum
always @(posedge clk) begin
	if (valid_in) pfxsum_state <= UP;

	case(pfxsum_state)
		UP: begin
			// check if done with up-sweep
			if (level == $clog2(V_LEN) - 1) begin
				pfxsum_state <= INT;
			end
			else level <= level + 1;
		end
		INT: begin
			vec[V_LEN-1] <= 0;
			pfxsum_state <= DOWN;
		end
		DOWN: begin
			level <= level - 1;
			if (level == 0) pfxsum_state <= DONE;
		end
		DONE: valid_out <= 1;
	endcase
end

// DEBUG
genvar i;
generate
for (i = 0; i < V_LEN; i = i + 1) begin
	always @(posedge clk) begin
		//if (pfxsum_state == DOWN & $clog2(V_LEN) - 1 == level + 1) $display("up %d: %h", i, vec[i]);
		//if (pfxsum_state == DOWN) $display("arr %d: %h", i, vec[i]);
	end
end
endgenerate

endmodule
