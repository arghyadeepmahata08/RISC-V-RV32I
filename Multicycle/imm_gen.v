// ============================================================================
// Module: imm_gen
// Description: RV32I Immediate Generator
//              Extracts and sign-extends immediates for all RV32I instruction formats:
//              I-type, S-type, B-type, U-type, and J-type.
// ============================================================================

module imm_gen (
    input  wire [31:0] instr,
    output wire [31:0] imm_i,
    output wire [31:0] imm_s,
    output wire [31:0] imm_b,
    output wire [31:0] imm_u,
    output wire [31:0] imm_j
);

    // I-type: immediate in [31:20] (used in ADDI, SLTI, LW, JALR, etc.)
    assign imm_i = {{20{instr[31]}}, instr[31:20]};

    // S-type: immediate in [31:25] and [11:7] (used in SW, SH, SB)
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};

    // B-type: branch offset in [31], [7], [30:25], [11:8], with LSB=0 (used in BEQ, BNE, etc.)
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};

    // U-type: upper 20-bit immediate in [31:12], zero-filled lower 12 bits (LUI, AUIPC)
    assign imm_u = {instr[31:12], 12'b0};

    // J-type: jump target in [31], [19:12], [20], [30:21], with LSB=0 (JAL)
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

endmodule
