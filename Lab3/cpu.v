`include "alu.v"
`include "adder.v"
`include "control_module.v"
`include "concatenator.v"
`include "mux.v"
`include "doubleLeftShift.v"
`include "signExtends.v"
`include "registerfile.v"
`include "PCregister.v"
`include "datamemory.v"
`include "instrmemory.v"
module mips_cpu
(
  input clk,
  output reg[31:0] error_code
);
  initial error_code = 32'd0;
  wire[31:0] instruction_addr, next_instruction_addr, write_data, normal_write_data,
             mem_read, alu_res, instruction_addr_plus4, instruction_addr_plus_immediate,
             jumped_pc, extended_immediate, shifted_extended_immediate, b,
             normal_pc, pc_jump_addr, read_1, read_2;
  wire[31:26] op;
  wire[25:21] rs;
  wire[25:0] jump_instruction_addr;
  wire[27:0] jump_instruction_addr_shifted;
  wire[20:16] rt, rt_or_2;
  wire[15:11] rd;
  wire[10:6] shft;
  wire[5:0] func;
  wire[15:0] imm;
  wire[4:0] write_addr, normal_write_addr;
  wire[2:0] alu_op;
  wire reg_dest, alu_src, zero_flag,reg_write_enable, mem_write_enable, mem_read_enable, mem_to_reg, 
       pc_src, jump_enable, bne_pc_override, pc_choose, jal_reg_override;

  // control module
  control_module cpu_control(op, func, reg_dest, alu_src, mem_write_enable, mem_to_reg, pc_src, reg_write_enable, mem_read_enable, alu_op, jump_enable, bne_pc_override, jal_reg_override);

  // ties pc_chooser mux directly to zero flag of ALU for use in BNE operations
  // input 0, input 1, selector, output
  mux #(1) bne_pc_override_mux(pc_src, zero_flag, bne_pc_override, pc_choose);

  // PC register
  PCreg PC(instruction_addr, next_instruction_addr, clk);

  // PC incrementer
  adder pc_incrementer(instruction_addr_plus4, instruction_addr, 32'd4);

  // PC adder
  adder pc_jumper(instruction_addr_plus_immediate, instruction_addr_plus4, shifted_extended_immediate);

  // PC chooser
  mux #(32) pc_chooser(instruction_addr_plus4, instruction_addr_plus_immediate, pc_choose, normal_pc);

  // PC Jumper
  mux #(32) jump_mux(normal_pc, pc_jump_addr, jump_enable, next_instruction_addr);

  // take address from instruction and shift left by 2
  doubleLeftShift26 jump_shifter(jump_instruction_addr, jump_instruction_addr_shifted, 1'b1, clk);

  // concat shifted jump address with 4 most significant bits of PC+4
  // stick the 4 most significant bits of PC+4 on to the shifted immediate from the instruction
  concatenator jump_add_concat(instruction_addr_plus4, jump_instruction_addr_shifted, clk, pc_jump_addr);

  // instruction memory module
  instrmemory #(100) instruction_memory(instruction_addr, op, rs, rt, rd, shft, func, imm, jump_instruction_addr);

  // instruction register destination mux
  mux #(5) reg_dest_mux(rt, rd, reg_dest, normal_write_addr);

  // mux to choose address to write to for jal op
  mux #(5) jal_reg_mux(normal_write_addr, 5'd31, jal_reg_override, write_addr);

  // sign extending module
  signExtends immediate_extender(imm, clk, extended_immediate);

  // shift left by 2'er module
  leftShift32 #(2) immediate_shifter(extended_immediate, shifted_extended_immediate, 1'b1, clk);

  // mux selector for error output
  // uses clk as selector to repeatedly get output from $v0 for error code
  mux #(5) rt_mux(rt, 5'd2, clk, rt_or_2);

  // operational register module
  // async_register register(read_1, read_2, write_data, read_addr_1, read_addr_2, write_addr, write_enable, clk);
  registerfile register(read_1, read_2, write_data, rs, rt_or_2, write_addr, reg_write_enable, clk);

  // alu source mux
  mux #(32) alu_src_mux(read_2, extended_immediate, alu_src, b);

  // alu module
  // ALU alu(res, zero, a, b, op);
  ALU alu(alu_res, zero_flag, read_1, b, alu_op);

  // data memory module
  // data_memory data_mem(clk, mem_read_addr, mem_write_addr, mem_read_enable, mem_write_enable, mem_write_data_in, mem_read_data_out);
  datamemory data_memory(clk, alu_res, alu_res, mem_read_enable, mem_write_enable, read_2, mem_read);

  // memory to register mux
  mux #(32) mem_to_reg_mux(alu_res, mem_read, mem_to_reg, normal_write_data);

  // optionally forces register to write PC+4 to whatever address
  // useful for jal operations
  mux #(32) jal_data_mux(normal_write_data, instruction_addr_plus4, jal_reg_override, write_data);

  always @(posedge clk) begin
    if(rt_or_2 == 5'd2) begin
      error_code = read_2;
    end
  end
endmodule
