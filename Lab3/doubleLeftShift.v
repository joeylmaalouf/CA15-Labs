module doubleLeftShift(    
    input reg[25:0]    d,
    output reg[27:0]   q,
    input              enable,
    input	       clk
);
    always @(posedge clk) begin
	if (enable) begin
	    q = d << 2;
        end
    end
endmodule
