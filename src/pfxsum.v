module Pfxsum #(
	// length of integers in bits
	parameter INT_WIDTH = 32,
	// length of array to sum
	parameter V_LEN = 16
) (
	input wire clk,
	input wire valid_in,
    input wire [V_LEN * INT_WIDTH-1:0] ivec,
    output wire valid_out, 
    output reg [V_LEN * INT_WIDTH-1:0] ovec
);                                       

localparam INIT = 0;
localparam UP = 1;
localparam DOWN = 2;


reg [7:0] pfxsum_state = INIT;
reg [V_LEN * INT_WIDTH-1:0] vec;
// current level for sweep, log2-based
reg [15:0] level = 0;

always @(posedge clk) begin

    // TODO if data ready, read it into data array
	// get rid of INIT state?

	// up:
	// 1: for d = 0 to log2(n – 1) do
	// 2:      for all k = 0 to n – 1 by 2^d+1 in parallel do
	// 3:           x[k +  2^d+1 – 1] = x[k +  2^d  – 1] + x[k +  2^d +1 – 1]

	case(pfxsum_state)
		INIT: begin
			if (valid_in) begin
				vec <= ivec;
				pfxsum_state <= UP;
			end
		end
    	UP: begin
			level <= level + 1;
			genvar c;
			generate
				for (c = 0; c < V_LEN; c = c + 1) begin
					// TODO put in variable?
					if ((c  + 2 ** (level + 1) - 1) < V_LEN)
							vec[c + 2 ** (level + 1) - 1] <= vec[c + 2 ** level - 1] + vec[c + 2 ** (d + 1) - 1]
 				end
			endgenerate

			// check if done with up-sweep
			if (level == $clog2(V_LEN) - 1) begin
				$displayh("done: %p", vec);
				pfxsum_state <= DOWN;
			end
		end
		DOWN: begin
			// TODO
			valid_out <= 1;
		end
	endcase

	// down:
	// 1: x[n – 1] <- 0
	// 2: for d = log2(n – 1) down to 0 do
	// 3:       for all k = 0 to n – 1 by 2^d +1 in parallel do
	// 4:            t = x[k +  2^d  – 1]
	// 5:            x[k +  2^d  – 1] = x[k +  2^d+1 – 1]
	// 6:            x[k +  2^d+1 – 1] = t +  x[k +  2^d+1 – 1]
end

endmodule
