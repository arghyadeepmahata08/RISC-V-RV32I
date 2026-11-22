// ============================================================================
// Testbench: tb_risc_processor
// Description: Comprehensive Testbench for the RV32I Multi-Cycle Processor
//              Monitors instruction execution, cycles, PC progression,
//              and verifies register writeback results.
// ============================================================================

`timescale 1ns / 1ps

module tb_risc_processor;

    reg         clk;
    reg         rst;
    reg  [2:0]  SW;
    wire [7:0]  LED;
    wire        halt;
    wire [31:0] pc_out;
    wire [31:0] instr_out;
    wire [31:0] reg_debug;

    // Instantiate Top-Level Processor
    risc_processor uut (
        .clk(clk),
        .rst(rst),
        .SW(SW),
        .LED(LED),
        .halt(halt),
        .pc_out(pc_out),
        .instr_out(instr_out),
        .reg_debug(reg_debug)
    );

    // Clock generation: 100MHz (10ns period)
    always #5 clk = ~clk;

    integer cycles;

    initial begin
        // Initialize inputs
        clk    = 0;
        rst    = 1;
        SW     = 3'd1; // Read x1
        cycles = 0;

        $display("=================================================================");
        $display("   RV32I MULTI-CYCLE PROCESSOR SIMULATION STARTED               ");
        $display("=================================================================");

        // Apply reset for 2 clock cycles
        #20;
        @(negedge clk);
        rst = 0;
        $display("[Time %0t] Reset released. Processor executing from PC = 0x%08h...", $time, pc_out);

        // Run simulation until HALT or max cycles reached
        while (!halt && cycles < 300) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        // Wait a few extra cycles after halt
        #40;

        $display("\n=================================================================");
        $display("   EXECUTION SUMMARY");
        $display("=================================================================");
        $display("Simulation finished in %0d clock cycles.", cycles);
        $display("Halt Signal Status: %b", halt);
        $display("Final PC: 0x%08h", pc_out);

        $display("\n--- Register File Inspection ---");
        $display("x1  (addi x1, x0, 10)  = %0d (Expected: 10)", uut.u_dp.u_rf.regs[1]);
        $display("x2  (addi x2, x0, 20)  = %0d (Expected: 20)", uut.u_dp.u_rf.regs[2]);
        $display("x3  (add  x3, x1, x2)  = %0d (Expected: 30)", uut.u_dp.u_rf.regs[3]);
        $display("x4  (sub  x4, x2, x1)  = %0d (Expected: 10)", uut.u_dp.u_rf.regs[4]);
        $display("x5  (and  x5, x1, x2)  = %0d (Expected: 0)",  uut.u_dp.u_rf.regs[5]);
        $display("x6  (or   x6, x1, x2)  = %0d (Expected: 30)", uut.u_dp.u_rf.regs[6]);
        $display("x7  (xor  x7, x1, x2)  = %0d (Expected: 30)", uut.u_dp.u_rf.regs[7]);
        $display("x8  (slt  x8, x1, x2)  = %0d (Expected: 1)",  uut.u_dp.u_rf.regs[8]);
        $display("x9  (lw   from mem[16])= %0d (Expected: 30)", uut.u_dp.u_rf.regs[9]);
        $display("x10 (lui  0x12345)     = 0x%08h (Expected: 0x12345000)", uut.u_dp.u_rf.regs[10]);
        $display("x11 (branch target)    = %0d (Expected: 42, branch taken)", uut.u_dp.u_rf.regs[11]);
        $display("x12 (jal return addr)  = 0x%08h (Expected: 0x0000003C)", uut.u_dp.u_rf.regs[12]);
        $display("x13 (jal target)       = %0d (Expected: 88, jump taken)", uut.u_dp.u_rf.regs[13]);

        // Self-checking verification
        if (uut.u_dp.u_rf.regs[1]  == 10 &&
            uut.u_dp.u_rf.regs[2]  == 20 &&
            uut.u_dp.u_rf.regs[3]  == 30 &&
            uut.u_dp.u_rf.regs[4]  == 10 &&
            uut.u_dp.u_rf.regs[5]  == 0  &&
            uut.u_dp.u_rf.regs[6]  == 30 &&
            uut.u_dp.u_rf.regs[7]  == 30 &&
            uut.u_dp.u_rf.regs[8]  == 1  &&
            uut.u_dp.u_rf.regs[9]  == 30 &&
            uut.u_dp.u_rf.regs[10] == 32'h12345000 &&
            uut.u_dp.u_rf.regs[11] == 42 &&
            uut.u_dp.u_rf.regs[12] == 32'h0000003C &&
            uut.u_dp.u_rf.regs[13] == 88) begin
            $display("\n=================================================================");
            $display("   *** ALL VERIFICATION TESTS PASSED SUCCESSFULLY! ***          ");
            $display("=================================================================");
        end else begin
            $display("\n=================================================================");
            $display("   *** VERIFICATION FAILED: Check discrepancies above ***       ");
            $display("=================================================================");
        end

        $finish;
    end

endmodule
