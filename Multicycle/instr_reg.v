// ============================================================================
// Module: instr_reg
// Description: RV32I 32-bit Instruction Register (IR)
//              Holds the fetched instruction during execution across cycles
// ============================================================================

module instr_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        ir_write,
    input  wire [31:0] ir_in,
    output reg  [31:0] ir_out
);

    always @(posedge clk) begin
        if (rst)
            ir_out <= 32'h00000013; // Reset to NOP (addi x0, x0, 0)
        else if (ir_write)
            ir_out <= ir_in;
    end

endmodule
