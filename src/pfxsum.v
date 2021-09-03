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
localparam DOWN = 1;
localparam DONE = 2;


reg [7:0] pfxsum_state;
// current level for sweep, log2-based
reg [15:0] level = 0;
// tracking steps for down sweep
reg [2:0] count = 0;
// temporary array for down sweep
reg [IWIDTH-1:0] tmp [V_LEN-1:0];
// in-place array to compute pfxsum
reg [IWIDTH-1:0] vec [V_LEN-1:0];

	// down:
	// 1: x[n – 1] <- 0
	// 2: for d = log2(n – 1) down to 0 do
	// 3:       for all k = 0 to n – 1 by 2^d +1 in parallel do
	// 4:            t = x[k +  2^d  – 1]
	// 5:            x[k +  2^d  – 1] = x[k +  2^d+1 – 1]
	// 6:            x[k +  2^d+1 – 1] = t +  x[k +  2^d+1 – 1]

genvar n;
generate
for (n = 0; n < V_LEN; n = n + 1) begin
	always @(posedge clk) begin
		// initialize vec, unflatten into 2d array
		if (valid_in) vec[n] <= ivec[(n+1)*IWIDTH-1:n*IWIDTH];

		if (pfxsum_state == UP & n+2**(level+1)-1 < V_LEN & n % (2 ** (level+1)) == 0) begin
			/* $display("adding %d [%d] to %d [%d]",  vec[n + 2 ** level - 1], n + 2 ** level - 1, */ 
			/* 									   vec[n + 2 ** (level + 1) - 1], n + 2 ** (level + 1) - 1 ); */
			vec[n + 2 ** (level + 1) - 1] <= vec[n + 2 ** level - 1] + vec[n + 2 ** (level + 1) - 1];
		end
		else if (pfxsum_state == DOWN & n+2**(level+1)-1 < V_LEN & n % (2 ** (level+1)) == 0) begin
			case(count)
				0: tmp[n] <= vec[n + 2 ** level - 1];
				1: vec[n + 2 ** level - 1] <= vec[n + 2 ** (level + 1) - 1];
				2: vec[n + 2 ** (level+1) - 1] <= tmp[n] + vec[n + 2 ** (level + 1) - 1];
			endcase
			count <= (count + 1) % 3;
		end
	end
end
endgenerate

// DEBUG
genvar i;
generate
for (i = 0; i < V_LEN; i = i + 1) begin
	always @(posedge clk) begin
		if (pfxsum_state == DOWN & level == $clog2(V_LEN) - 1) $display("up %d: %h", i, vec[i]);
		else if (pfxsum_state == DONE) $display("fin %d: %h", i, vec[i]);
	end
end
endgenerate

always @(posedge clk) begin

	if (valid_in)
		pfxsum_state <= UP;

	case(pfxsum_state)
		UP: begin
			// check if done with up-sweep
			if (level == $clog2(V_LEN) - 1) begin
				vec[V_LEN-1] <= 0;
				pfxsum_state <= DOWN;
			end
			else
				level <= level + 1;
		end
		DOWN: begin
			level <= level - 1;
			if (level == 0) begin
				valid_out <= 1;
				pfxsum_state <= DONE;
			end
		end
	endcase
end

endmodule
