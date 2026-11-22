// ============================================================================
// Module: data_mem
// Description: RV32I Byte-Addressable Data Memory
//              Supports Byte (LB, LBU, SB), Halfword (LH, LHU, SH), and Word (LW, SW)
//              Standard little-endian byte ordering. Size: 1024 bytes (0x000 to 0x3FF)
// ============================================================================

module data_mem (
    input  wire        clk,
    input  wire        rst,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output reg  [31:0] read_data
);

    reg [7:0] mem [0:1023];
    integer i;

    // Memory initialization
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            mem[i] = 8'd0;

        // Sample data for testing
        // Word at address 0x004: 32'h0000002A (decimal 42)
        mem[4] = 8'h2A;
        mem[5] = 8'h00;
        mem[6] = 8'h00;
        mem[7] = 8'h00;

        // Word at address 0x008: 32'h00000064 (decimal 100)
        mem[8] = 8'h64;
        mem[9] = 8'h00;
        mem[10] = 8'h00;
        mem[11] = 8'h00;

        // Word at address 0x00C: 32'hFFFFFFFE (-2 signed)
        mem[12] = 8'hFE;
        mem[13] = 8'hFF;
        mem[14] = 8'hFF;
        mem[15] = 8'hFF;
    end

    wire [9:0] eff_addr = addr[9:0];

    // Synchronous memory write with byte, halfword, and word support
    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: begin // SB (Store Byte)
                    mem[eff_addr] <= write_data[7:0];
                end
                3'b001: begin // SH (Store Halfword)
                    mem[eff_addr]     <= write_data[7:0];
                    mem[eff_addr + 1] <= write_data[15:8];
                end
                3'b010: begin // SW (Store Word)
                    mem[eff_addr]     <= write_data[7:0];
                    mem[eff_addr + 1] <= write_data[15:8];
                    mem[eff_addr + 2] <= write_data[23:16];
                    mem[eff_addr + 3] <= write_data[31:24];
                end
                default: begin
                    mem[eff_addr]     <= write_data[7:0];
                    mem[eff_addr + 1] <= write_data[15:8];
                    mem[eff_addr + 2] <= write_data[23:16];
                    mem[eff_addr + 3] <= write_data[31:24];
                end
            endcase
        end
    end

    // Combinational read with sign/zero extension based on funct3
    wire [7:0]  b0 = mem[eff_addr];
    wire [7:0]  b1 = mem[eff_addr + 1];
    wire [7:0]  b2 = mem[eff_addr + 2];
    wire [7:0]  b3 = mem[eff_addr + 3];

    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: read_data = {{24{b0[7]}}, b0};         // LB (sign-extended byte)
                3'b001: read_data = {{16{b1[7]}}, b1, b0};     // LH (sign-extended halfword)
                3'b010: read_data = {b3, b2, b1, b0};          // LW (word)
                3'b100: read_data = {24'd0, b0};               // LBU (zero-extended byte)
                3'b101: read_data = {16'd0, b1, b0};           // LHU (zero-extended halfword)
                default: read_data = {b3, b2, b1, b0};
            endcase
        end else begin
            read_data = 32'd0;
        end
    end

endmodule
