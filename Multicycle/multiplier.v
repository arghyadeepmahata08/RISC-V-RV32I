// ============================================================================
// Module: multiplier
// Description: 32-bit Multiplier (RV32M extension support)
//              Computes 64-bit product of two 32-bit operands.
// ============================================================================

module multiplier (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output wire [31:0] result_low,
    output wire [31:0] result_high
);

    wire [63:0] product;

    assign product     = a * b;
    assign result_low  = product[31:0];
    assign result_high = product[63:32];

endmodule
