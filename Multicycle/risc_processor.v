// ============================================================================
// Module: risc_processor
// Description: RV32I Multi-Cycle RISC-V Processor Top-Level Module
//              Integrates the control_unit, datapath, and reg_select module.
//              Follows the modular architecture of the reference processor.
// ============================================================================

module risc_processor (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  SW,
    output wire [7:0]  LED,
    output wire        halt,
    output wire [31:0] pc_out,
    output wire [31:0] instr_out,
    output wire [31:0] reg_debug
);

    // Internal control signals
    wire        pc_write;
    wire [1:0]  pc_src;
    wire        imem_read;
    wire        ir_write;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  alu_src_a;
    wire [1:0]  alu_src_b;
    wire [1:0]  alu_op;
    wire [1:0]  wb_sel;

    // Status signals between datapath and control unit
    wire [6:0]  opcode;
    wire        branch_taken;

    // Register outputs for observation
    wire [31:0] r0, r1, r2, r3, r4, r5, r6, r7;
    wire [31:0] r8, r9, r10, r11, r12, r13, r14, r15;

    // ------------------------------------------------------------------------
    // Control Unit Instantiation
    // ------------------------------------------------------------------------
    control_unit u_cu (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .pc_write(pc_write),
        .pc_src(pc_src),
        .imem_read(imem_read),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op),
        .wb_sel(wb_sel),
        .halt(halt)
    );

    // ------------------------------------------------------------------------
    // Datapath Instantiation
    // ------------------------------------------------------------------------
    datapath u_dp (
        .clk(clk),
        .rst(rst),
        .pc_write(pc_write),
        .pc_src(pc_src),
        .imem_read(imem_read),
        .ir_write(ir_write),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .alu_op(alu_op),
        .wb_sel(wb_sel),
        .opcode(opcode),
        .branch_taken(branch_taken),
        .pc_current(pc_out),
        .instr_current(instr_out),
        .reg0(r0),   .reg1(r1),   .reg2(r2),   .reg3(r3),
        .reg4(r4),   .reg5(r5),   .reg6(r6),   .reg7(r7),
        .reg8(r8),   .reg9(r9),   .reg10(r10), .reg11(r11),
        .reg12(r12), .reg13(r13), .reg14(r14), .reg15(r15)
    );

    // ------------------------------------------------------------------------
    // Register Selection for Switch / LED Debugging
    // ------------------------------------------------------------------------
    reg_select u_reg_sel (
        .reg0(r0),
        .reg1(r1),
        .reg2(r2),
        .reg3(r3),
        .reg4(r4),
        .reg5(r5),
        .reg6(r6),
        .reg7(r7),
        .SW(SW),
        .LED(LED),
        .reg_data_out(reg_debug)
    );

endmodule
