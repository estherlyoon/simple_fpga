module main;
 
reg clk = 0;
always #5 clk = !clk;
reg [31:0] count = 0;
always @(posedge clk) count <= count + 1;

// configuration
localparam IWIDTH = 8;
localparam V_LEN = 8;

// init memory
reg [IWIDTH-1:0] mem [V_LEN-1:0];
initial begin
	$readmemh("./src/mem_init.hex", mem);
end

reg init = 1;
reg valid_in = 0;

wire valid_out;
wire [IWIDTH*V_LEN-1:0] ivec;
wire [IWIDTH*V_LEN-1:0] ovec;

genvar i;
generate
for (i = 0; i < V_LEN; i = i + 1) begin
	assign ivec[i * IWIDTH + IWIDTH-1:i * IWIDTH] = mem[i];

	// debug
	always @(posedge clk) begin
		if (init) $display("val %d: %h", i, ivec[(i+1)*IWIDTH-1:i*IWIDTH]);
	end
end
endgenerate

always @(posedge clk) begin
	if (init) begin
		init <= 0;
		valid_in <= 1;
	end
	else
		valid_in <= 0;
	
	if (valid_out) begin
		$display("done");
		$finish;
	end
end
 
Pfxsum #(
	.IWIDTH(IWIDTH),
	.V_LEN(V_LEN)
) pfxsum (
	.clk(clk),
	.valid_in(valid_in),
    .ivec(ivec),
    .valid_out(valid_out), 
    .ovec(ovec)
);                                       
 
endmodule
