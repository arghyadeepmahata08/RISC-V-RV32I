
// Decode - RTL (Refined)
import risc_pkg::*;

module decode(
  input  logic [31:0]  instruction,  // 32-bit instruction from IF stage

  // Decoded fields
  output logic [4:0]   rs1_addr,
  output logic [4:0]   rs2_addr,
  output logic [4:0]   rd_addr,
  output logic [6:0]   opcode,
  output logic [2:0]   funct3,
  output logic [6:0]   funct7,
  output logic         r_type,
  output logic         i_type,
  output logic         s_type,
  output logic         b_type,
  output logic         u_type,
  output logic         j_type,
  output logic [31:0]  immediate         // Final immediate value
);

  logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

assign opcode = instruction[6:0];
assign rd_addr = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1_addr = instruction[19:15];
assign rs2_addr = instruction[24:20]; 
assign funct7 = instruction[31:25];

// assign immediate values for different types  
assign imm_i = {{20{instruction[31]}},instruction [31:20]};
assign imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
assign imm_b = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8],1'b0};
assign imm_u = {instruction[31:12], 12'b0};
assign imm_j = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};

// Determine instruction type based on opcode
always_comb begin
  r_type = 0;
  i_type = 0;   
  s_type = 0; 
  b_type = 0; 
  u_type = 0; 
  j_type = 0;
  case (opcode)
    OPCODE_R_TYPE: r_type = 1;
    OPCODE_I_LOAD, OPCODE_I_ALU, OPCODE_I_JALR: i_type = 1;
    OPCODE_S_TYPE: s_type = 1;
    OPCODE_B_TYPE: b_type = 1;
    OPCODE_LUI, OPCODE_AUIPC: u_type = 1;
    OPCODE_JAL: j_type = 1;
    default: begin
      r_type = 0; i_type = 0; s_type = 0; b_type = 0; u_type = 0; j_type = 0;
    end
endcase
end

// final immediate selection based on instruction type
always_comb begin
  if (i_type) immediate = imm_i;
  else if (s_type) immediate = imm_s;
  else if (b_type) immediate = imm_b;
  else if (u_type) immediate = imm_u;
  else if (j_type) immediate = imm_j;
  else immediate = 32'b0; // Default for R-type and unknown types
end
endmodule

