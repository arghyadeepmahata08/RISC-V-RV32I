// ============================================================================
// Module: datapath
// Description: RV32I Multi-Cycle Datapath
//              Integrates PC, Instruction Memory, Instruction Register,
//              Decoder, Immediate Generator, Register File, ALU Control, ALU,
//              Branch Unit, Data Memory, and multi-cycle pipeline registers
//              (A, B, ALUOut, MDR).
// ============================================================================

module datapath (
    input  wire        clk,
    input  wire        rst,

    // Control signals from control_unit
    input  wire        pc_write,
    input  wire [1:0]  pc_src,
    input  wire        imem_read,
    input  wire        ir_write,
    input  wire        reg_write,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [1:0]  alu_src_a,
    input  wire [1:0]  alu_src_b,
    input  wire [1:0]  alu_op,
    input  wire [1:0]  wb_sel,

    // Status to control_unit
    output wire [6:0]  opcode,
    output wire        branch_taken,

    // Debug / observation outputs
    output wire [31:0] pc_current,
    output wire [31:0] instr_current,
    output wire [31:0] reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7,
    output wire [31:0] reg8, reg9, reg10, reg11, reg12, reg13, reg14, reg15
);

    // ------------------------------------------------------------------------
    // Program Counter (PC)
    // ------------------------------------------------------------------------
    wire [31:0] pc_out;
    reg  [31:0] next_pc;

    pc u_pc (
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write),
        .pc_in(next_pc),
        .pc_out(pc_out)
    );

    assign pc_current = pc_out;

    // ------------------------------------------------------------------------
    // Instruction Memory & Instruction Register (IR)
    // ------------------------------------------------------------------------
    wire [31:0] imem_instr;
    wire [31:0] ir_out;

    instr_mem u_imem (
        .clk(clk),
        .imem_read(imem_read),
        .addr(pc_out),
        .instr(imem_instr)
    );

    instr_reg u_ir (
        .clk(clk),
        .rst(rst),
        .ir_write(ir_write),
        .ir_in(imem_instr),
        .ir_out(ir_out)
    );

    assign instr_current = ir_out;

    // ------------------------------------------------------------------------
    // Instruction Decoder
    // ------------------------------------------------------------------------
    wire [6:0] dec_opcode;
    wire [4:0] dec_rd, dec_rs1, dec_rs2;
    wire [2:0] dec_funct3;
    wire [6:0] dec_funct7;

    instr_decoder u_dec (
        .instr(ir_out),
        .opcode(dec_opcode),
        .rd(dec_rd),
        .funct3(dec_funct3),
        .rs1(dec_rs1),
        .rs2(dec_rs2),
        .funct7(dec_funct7)
    );

    assign opcode = dec_opcode;

    // ------------------------------------------------------------------------
    // Immediate Generator
    // ------------------------------------------------------------------------
    wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    imm_gen u_imm (
        .instr(ir_out),
        .imm_i(imm_i),
        .imm_s(imm_s),
        .imm_b(imm_b),
        .imm_u(imm_u),
        .imm_j(imm_j)
    );

    // ------------------------------------------------------------------------
    // Register File & Stage Registers A, B
    // ------------------------------------------------------------------------
    wire [31:0] rf_data1, rf_data2;
    reg  [31:0] wb_data;

    reg_file u_rf (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .rd_addr1(dec_rs1),
        .rd_addr2(dec_rs2),
        .wr_addr(dec_rd),
        .wr_data(wb_data),
        .rd_data1(rf_data1),
        .rd_data2(rf_data2)
    );

    reg [31:0] reg_a, reg_b;

    always @(posedge clk) begin
        if (rst) begin
            reg_a <= 32'd0;
            reg_b <= 32'd0;
        end else begin
            reg_a <= rf_data1;
            reg_b <= rf_data2;
        end
    end

    // ------------------------------------------------------------------------
    // Branch Unit
    // ------------------------------------------------------------------------
    wire branch_zero        = (reg_a == reg_b);
    wire branch_less_than   = ($signed(reg_a) < $signed(reg_b));
    wire branch_less_than_u = (reg_a < reg_b);

    branch_unit u_bu (
        .funct3(dec_funct3),
        .zero(branch_zero),
        .less_than(branch_less_than),
        .less_than_u(branch_less_than_u),
        .branch_taken(branch_taken)
    );

    // ------------------------------------------------------------------------
    // ALU Control and ALU
    // ------------------------------------------------------------------------
    wire [3:0]  alu_ctrl;
    reg  [31:0] alu_in_a;
    reg  [31:0] alu_in_b;
    wire [31:0] alu_result;
    wire        alu_zero, alu_lt, alu_ltu;

    alu_control u_alu_ctrl (
        .alu_op(alu_op),
        .funct3(dec_funct3),
        .funct7(dec_funct7),
        .alu_ctrl(alu_ctrl)
    );

    // Operand A selection
    always @(*) begin
        case (alu_src_a)
            2'b00:   alu_in_a = reg_a;
            2'b01:   alu_in_a = pc_out;
            2'b10:   alu_in_a = 32'd0;
            default: alu_in_a = reg_a;
        endcase
    end

    // Operand B selection
    always @(*) begin
        case (alu_src_b)
            2'b00:   alu_in_b = reg_b;
            2'b01:   alu_in_b = (dec_opcode == 7'b0100011) ? imm_s : imm_i; // Store uses imm_s
            2'b10:   alu_in_b = 32'd4;
            2'b11:   alu_in_b = imm_u;
            default: alu_in_b = reg_b;
        endcase
    end

    alu u_alu (
        .a(alu_in_a),
        .b(alu_in_b),
        .alu_ctrl(alu_ctrl),
        .result(alu_result),
        .zero(alu_zero),
        .less_than(alu_lt),
        .less_than_u(alu_ltu)
    );

    // Multi-cycle ALUOut Register
    reg [31:0] alu_out_reg;

    always @(posedge clk) begin
        if (rst)
            alu_out_reg <= 32'd0;
        else
            alu_out_reg <= alu_result;
    end

    // ------------------------------------------------------------------------
    // Data Memory and MDR (Memory Data Register)
    // ------------------------------------------------------------------------
    wire [31:0] dmem_read_data;
    reg  [31:0] mdr;

    data_mem u_dmem (
        .clk(clk),
        .rst(rst),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(dec_funct3),
        .addr(alu_out_reg),
        .write_data(reg_b),
        .read_data(dmem_read_data)
    );

    always @(posedge clk) begin
        if (rst)
            mdr <= 32'd0;
        else
            mdr <= dmem_read_data;
    end

    // ------------------------------------------------------------------------
    // Writeback Data Selection
    // ------------------------------------------------------------------------
    always @(*) begin
        case (wb_sel)
            2'b00:   wb_data = (dec_opcode == 7'b0010111) ? alu_result : alu_out_reg; // ALUOut or AUIPC
            2'b01:   wb_data = mdr;                                                   // Memory data
            2'b10:   wb_data = pc_out + 32'd4;                                        // Link address for JAL/JALR
            2'b11:   wb_data = imm_u;                                                 // LUI
            default: wb_data = alu_out_reg;
        endcase
    end

    // ------------------------------------------------------------------------
    // Next PC Selection
    // ------------------------------------------------------------------------
    wire [31:0] branch_target = pc_out + imm_b;
    wire [31:0] jal_target    = pc_out + imm_j;
    wire [31:0] jalr_target   = (reg_a + imm_i) & ~32'd1;

    always @(*) begin
        case (pc_src)
            2'b00:   next_pc = pc_out + 32'd4;
            2'b01:   next_pc = (dec_opcode == 7'b1101111) ? jal_target : branch_target;
            2'b10:   next_pc = jalr_target;
            default: next_pc = pc_out + 32'd4;
        endcase
    end

    // ------------------------------------------------------------------------
    // Register observation for debug / testbench / reg_select
    // ------------------------------------------------------------------------
    reg [31:0] shadow_regs [0:31];
    integer idx;

    always @(posedge clk) begin
        if (rst) begin
            for (idx = 0; idx < 32; idx = idx + 1)
                shadow_regs[idx] <= 32'd0;
        end else if (reg_write && (dec_rd != 5'd0)) begin
            shadow_regs[dec_rd] <= wb_data;
        end
    end

    assign reg0  = 32'd0;
    assign reg1  = shadow_regs[1];
    assign reg2  = shadow_regs[2];
    assign reg3  = shadow_regs[3];
    assign reg4  = shadow_regs[4];
    assign reg5  = shadow_regs[5];
    assign reg6  = shadow_regs[6];
    assign reg7  = shadow_regs[7];
    assign reg8  = shadow_regs[8];
    assign reg9  = shadow_regs[9];
    assign reg10 = shadow_regs[10];
    assign reg11 = shadow_regs[11];
    assign reg12 = shadow_regs[12];
    assign reg13 = shadow_regs[13];
    assign reg14 = shadow_regs[14];
    assign reg15 = shadow_regs[15];

endmodule
