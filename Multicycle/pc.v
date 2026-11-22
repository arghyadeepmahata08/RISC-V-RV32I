// ============================================================================
// Module: pc
// Description: RV32I 32-bit Program Counter Register
// ============================================================================

module pc (
    input  wire        clk,
    input  wire        rst,
    input  wire        pc_write,
    input  wire [31:0] pc_in,
    output reg  [31:0] pc_out
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'h00000000;
        else if (pc_write)
            pc_out <= pc_in;
    end

endmodule
