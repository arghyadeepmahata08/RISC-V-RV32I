// ============================================================================
// Module: instr_mem
// Description: RV32I Instruction Memory (ROM / RAM)
//              Stores 32-bit instructions addressed by 32-bit byte address PC.
//              Contains a built-in verification suite testing R, I, S, B, U, J types.
// ============================================================================

module instr_mem (
    input  wire        clk,
    input  wire        imem_read,
    input  wire [31:0] addr,
    output reg  [31:0] instr
);

    // 256 words = 1024 bytes
    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // NOP (addi x0, x0, 0)

        // PC 0x000: addi x1, x0, 10       -> x1 = 10 (0x0A)
        mem[0]  = 32'h00A00093;

        // PC 0x004: addi x2, x0, 20       -> x2 = 20 (0x14)
        mem[1]  = 32'h01400113;

        // PC 0x008: add  x3, x1, x2       -> x3 = 30 (0x1E)
        mem[2]  = 32'h002081B3;

        // PC 0x00C: sub  x4, x2, x1       -> x4 = 10 (0x0A)
        mem[3]  = 32'h40110233;

        // PC 0x010: and  x5, x1, x2       -> x5 = 10 & 20 = 0 (0x00)
        mem[4]  = 32'h0020F2B3;

        // PC 0x014: or   x6, x1, x2       -> x6 = 10 | 20 = 30 (0x1E)
        mem[5]  = 32'h0020E333;

        // PC 0x018: xor  x7, x1, x2       -> x7 = 10 ^ 20 = 30 (0x1E)
        mem[6]  = 32'h0020C3B3;

        // PC 0x01C: slt  x8, x1, x2       -> x8 = 1 (10 < 20)
        mem[7]  = 32'h0020A433;

        // PC 0x020: sw   x3, 16(x0)       -> mem[16] = 30
        mem[8]  = 32'h00302823;

        // PC 0x024: lw   x9, 16(x0)       -> x9 = mem[16] = 30
        mem[9]  = 32'h01002483;

        // PC 0x028: lui  x10, 0x12345     -> x10 = 0x12345000
        mem[10] = 32'h12345537;

        // PC 0x02C: beq  x1, x1, 8        -> Branch to PC + 8 (0x034), skip next
        mem[11] = 32'h00108463;

        // PC 0x030: addi x11, x0, 99      -> Skipped!
        mem[12] = 32'h06300593;

        // PC 0x034: addi x11, x0, 42      -> x11 = 42 (0x2A)
        mem[13] = 32'h02A00593;

        // PC 0x038: jal  x12, 8           -> Jump to PC + 8 (0x040), x12 = PC+4 = 0x03C
        mem[14] = 32'h0080066F;

        // PC 0x03C: addi x13, x0, 99      -> Skipped!
        mem[15] = 32'h06300693;

        // PC 0x040: addi x13, x0, 88      -> x13 = 88 (0x58)
        mem[16] = 32'h05800693;

        // PC 0x044: ecall                 -> Halt execution
        mem[17] = 32'h00000073;
    end

    // Word address: addr[9:2]
    wire [7:0] word_addr = addr[9:2];

    always @(posedge clk) begin
        if (imem_read)
            instr <= mem[word_addr];
    end

endmodule
