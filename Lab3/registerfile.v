module registerfile(
  output [31:0] read_data_1,
  output [31:0] read_data_2,
  input [31:0] write_data,
  input [4:0] read_address_1,
  input [4:0] read_address_2,
  input [4:0] write_address,
  input write_enable,
  input clk
);
  reg[31:0] registers[31:0];
  initial begin
    registers[5'd0] = 32'b0;
  end
  always @(posedge clk) begin
    if (write_enable && (write_address > 0)) begin
      registers[write_address] = write_data;
    end
  end
  assign read_data_1 = registers[read_address_1];
  assign read_data_2 = registers[read_address_2];
endmodule
