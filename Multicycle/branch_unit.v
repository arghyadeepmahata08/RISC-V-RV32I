// ============================================================================
// Module: branch_unit
// Description: RV32I Branch Decision Unit
//              Evaluates branch conditions for BEQ, BNE, BLT, BGE, BLTU, BGEU
// ============================================================================

module branch_unit (
    input  wire [2:0] funct3,
    input  wire       zero,
    input  wire       less_than,
    input  wire       less_than_u,
    output reg        branch_taken
);

    always @(*) begin
        case (funct3)
            3'b000:  branch_taken = zero;         // BEQ
            3'b001:  branch_taken = ~zero;        // BNE
            3'b100:  branch_taken = less_than;    // BLT
            3'b101:  branch_taken = ~less_than;   // BGE
            3'b110:  branch_taken = less_than_u;  // BLTU
            3'b111:  branch_taken = ~less_than_u; // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

endmodule
