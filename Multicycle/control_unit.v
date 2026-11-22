// ============================================================================
// Module: control_unit
// Description: RV32I Multi-Cycle FSM Control Unit
//              Sequences the processor through FETCH, DECODE, EXECUTE,
//              MEMORY, and WRITEBACK states according to instruction type.
// ============================================================================

module control_unit (
    input  wire       clk,
    input  wire       rst,
    input  wire [6:0] opcode,
    input  wire       branch_taken,
    output reg        pc_write,
    output reg  [1:0] pc_src,      // 00: PC+4, 01: PC+imm, 10: (A+imm)&~1
    output reg        imem_read,
    output reg        ir_write,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [1:0] alu_src_a,   // 00: A, 01: PC, 10: 0
    output reg  [1:0] alu_src_b,   // 00: B, 01: imm_i/s, 10: 4, 11: imm_u
    output reg  [1:0] alu_op,      // 00: ADD, 01: SUB, 10: R-type, 11: I-type
    output reg  [1:0] wb_sel,      // 00: ALUOut, 01: MDR, 10: PC+4, 11: imm_u
    output reg        halt
);

    // RV32I Opcodes
    localparam OP_R_TYPE   = 7'b0110011;
    localparam OP_I_ARITH  = 7'b0010011;
    localparam OP_LOAD     = 7'b0000011;
    localparam OP_STORE    = 7'b0100011;
    localparam OP_BRANCH   = 7'b1100011;
    localparam OP_JAL      = 7'b1101111;
    localparam OP_JALR     = 7'b1100111;
    localparam OP_LUI      = 7'b0110111;
    localparam OP_AUIPC    = 7'b0010111;
    localparam OP_SYSTEM   = 7'b1110011;

    // FSM State Encoding
    localparam S_FETCH     = 4'd0;
    localparam S_DECODE    = 4'd1;
    localparam S_EXEC_R    = 4'd2;
    localparam S_EXEC_I    = 4'd3;
    localparam S_MEM_ADDR  = 4'd4;
    localparam S_MEM_READ  = 4'd5;
    localparam S_MEM_WRITE = 4'd6;
    localparam S_BRANCH    = 4'd7;
    localparam S_JAL       = 4'd8;
    localparam S_JALR      = 4'd9;
    localparam S_LUI       = 4'd10;
    localparam S_AUIPC     = 4'd11;
    localparam S_WRITEBACK = 4'd12;
    localparam S_WB_MEM    = 4'd13;
    localparam S_HALT      = 4'd14;

    reg [3:0] state, next_state;
    reg [6:0] opcode_reg;

    // State Register and Opcode Latch
    always @(posedge clk) begin
        if (rst) begin
            state      <= S_FETCH;
            opcode_reg <= 7'b0000000;
        end else begin
            state <= next_state;
            if (state == S_DECODE)
                opcode_reg <= opcode;
        end
    end

    // Next State Logic
    always @(*) begin
        case (state)
            S_FETCH: begin
                next_state = S_DECODE;
            end

            S_DECODE: begin
                case (opcode)
                    OP_R_TYPE:  next_state = S_EXEC_R;
                    OP_I_ARITH: next_state = S_EXEC_I;
                    OP_LOAD,
                    OP_STORE:   next_state = S_MEM_ADDR;
                    OP_BRANCH:  next_state = S_BRANCH;
                    OP_JAL:     next_state = S_JAL;
                    OP_JALR:    next_state = S_JALR;
                    OP_LUI:     next_state = S_LUI;
                    OP_AUIPC:   next_state = S_AUIPC;
                    OP_SYSTEM:  next_state = S_HALT;
                    default:    next_state = S_FETCH;
                endcase
            end

            S_EXEC_R,
            S_EXEC_I: begin
                next_state = S_WRITEBACK;
            end

            S_MEM_ADDR: begin
                if (opcode_reg == OP_LOAD)
                    next_state = S_MEM_READ;
                else
                    next_state = S_MEM_WRITE;
            end

            S_MEM_READ: begin
                next_state = S_WB_MEM;
            end

            S_MEM_WRITE,
            S_BRANCH,
            S_JAL,
            S_JALR,
            S_LUI,
            S_AUIPC,
            S_WRITEBACK,
            S_WB_MEM: begin
                next_state = S_FETCH;
            end

            S_HALT: begin
                next_state = S_HALT;
            end

            default: next_state = S_FETCH;
        endcase
    end

    // Output Control Signals
    always @(*) begin
        // Default control signal values
        pc_write  = 1'b0;
        pc_src    = 2'b00;
        imem_read = 1'b0;
        ir_write  = 1'b0;
        reg_write = 1'b0;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        alu_src_a = 2'b00;
        alu_src_b = 2'b00;
        alu_op    = 2'b00;
        wb_sel    = 2'b00;
        halt      = 1'b0;

        case (state)
            S_FETCH: begin
                imem_read = 1'b1;
                ir_write  = 1'b1;
            end

            S_DECODE: begin
                // Register file reading and immediate generation occur combinationally
            end

            S_EXEC_R: begin
                alu_src_a = 2'b00; // A (rs1)
                alu_src_b = 2'b00; // B (rs2)
                alu_op    = 2'b10; // R-type ALU operation
            end

            S_EXEC_I: begin
                alu_src_a = 2'b00; // A (rs1)
                alu_src_b = 2'b01; // imm_i
                alu_op    = 2'b11; // I-type ALU operation
            end

            S_MEM_ADDR: begin
                alu_src_a = 2'b00; // A (rs1 base address)
                alu_src_b = 2'b01; // imm_i (load) / imm_s (store)
                alu_op    = 2'b00; // ADD
            end

            S_MEM_READ: begin
                mem_read = 1'b1;
            end

            S_MEM_WRITE: begin
                mem_write = 1'b1;
                pc_write  = 1'b1;
                pc_src    = 2'b00; // PC <= PC + 4
            end

            S_BRANCH: begin
                pc_write = 1'b1;
                pc_src   = (branch_taken) ? 2'b01 : 2'b00; // Taken: PC+imm_b, else PC+4
            end

            S_JAL: begin
                reg_write = 1'b1;
                wb_sel    = 2'b10; // wr_data <= PC + 4 (link)
                pc_write  = 1'b1;
                pc_src    = 2'b01; // PC <= PC + imm_j
            end

            S_JALR: begin
                reg_write = 1'b1;
                wb_sel    = 2'b10; // wr_data <= PC + 4 (link)
                pc_write  = 1'b1;
                pc_src    = 2'b10; // PC <= (A + imm_i) & ~1
            end

            S_LUI: begin
                reg_write = 1'b1;
                wb_sel    = 2'b11; // wr_data <= imm_u
                pc_write  = 1'b1;
                pc_src    = 2'b00; // PC <= PC + 4
            end

            S_AUIPC: begin
                reg_write = 1'b1;
                wb_sel    = 2'b00; // wr_data <= ALUOut (PC + imm_u)
                alu_src_a = 2'b01; // PC
                alu_src_b = 2'b11; // imm_u
                alu_op    = 2'b00; // ADD
                pc_write  = 1'b1;
                pc_src    = 2'b00; // PC <= PC + 4
            end

            S_WRITEBACK: begin
                reg_write = 1'b1;
                wb_sel    = 2'b00; // ALUOut
                pc_write  = 1'b1;
                pc_src    = 2'b00; // PC <= PC + 4
            end

            S_WB_MEM: begin
                reg_write = 1'b1;
                wb_sel    = 2'b01; // MDR (data memory output)
                pc_write  = 1'b1;
                pc_src    = 2'b00; // PC <= PC + 4
            end

            S_HALT: begin
                halt = 1'b1;
            end
        endcase
    end

endmodule
