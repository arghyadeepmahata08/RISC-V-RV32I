
// ALU - RTL 
import risc_pkg::*;

module alu (
  // Operands
  input  logic [31:0] alu_a,   // ALU input A
  input  logic [31:0] alu_b,   // ALU input B

  // Operation selector
  input  alu_op_t     alu_op,      // ALU operation from risc_pkg

  output logic [31:0] alu_res       // ALU output
);

logic signed [31:0] a_signed;
logic signed [31:0] b_signed;

assign a_signed = alu_a;
assign b_signed = alu_b;

always_comb begin

  case (alu_op)
    ADD: alu_res = alu_a + alu_b;
    SUB: alu_res = alu_a - alu_b;
    AND: alu_res = alu_a & alu_b;
    OR:  alu_res = alu_a | alu_b;
    XOR: alu_res = alu_a ^ alu_b;
    SLL: alu_res = alu_a << alu_b[4:0];
    SRL: alu_res = alu_a >> alu_b[4:0];
    SRA: alu_res = a_signed >>> alu_b[4:0];
    SLTU: alu_res = (alu_a < alu_b) ? 32'b1 : 32'b0;
    SLT: alu_res = (a_signed < b_signed) ? 32'b1 : 32'b0;
    default: alu_res = 32'b0; // Default case to avoid latches
  endcase
  
end
endmodule
