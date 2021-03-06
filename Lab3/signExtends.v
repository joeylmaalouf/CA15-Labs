module signExtends( //sign extend signed, for use with 2's compliment
  input[15:0]      d,
  input            clk,
  output reg[31:0] q
);
  always @(posedge clk) begin
    q <= {{16{d[15]}}, d};
  end
endmodule
