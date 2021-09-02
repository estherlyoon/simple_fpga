module main;
 
reg clk = 0;
always #5 clk = !clk;
reg [31:0] count = 0;
always @(posedge clk) count <= count + 1;

reg [INT_WIDTH*V_LEN-1:0] ivec;
initial begin
	$readmemh("./mem_init.hex", mem);
end

reg init = 1;
reg valid_in = 0;

always @(posedge clk) begin
	if (init) begin
		init <= 0;
		valid_in <= 1;
	end
	
	if (valid_out) begin
		$display("done");
		$finish;
	end
end
 
Pfxsum #(
	parameter INT_WIDTH = 32,
	parameter V_LEN = 8
) (
	.clk(clk),
	.valid_in(valid_in),
    .ivec(ivec),
    .valid_out(valid_out), 
    .ovec(ovec), 
);                                       
 
endmodule
