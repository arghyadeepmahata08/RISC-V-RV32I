// ============================================================================
// Module: rv32i_processor
// Description: RV32I Multi-Cycle RISC-V Processor Top-Level Wrapper
//              Directly instantiates risc_processor for alternative naming
// ============================================================================

module rv32i_processor (
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  SW,
    output wire [7:0]  LED,
    output wire        halt,
    output wire [31:0] pc_out,
    output wire [31:0] instr_out,
    output wire [31:0] reg_debug
);

    risc_processor u_core (
        .clk(clk),
        .rst(rst),
        .SW(SW),
        .LED(LED),
        .halt(halt),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .reg_debug(reg_debug)
    );

endmodule
