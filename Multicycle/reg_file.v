// ============================================================================
// Module: reg_file
// Description: RV32I 32x32-bit General Purpose Register File (x0 - x31)
//              x0 is hardwired to 0 (reads return 0, writes to x0 ignored)
// ============================================================================

module reg_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        reg_write,
    input  wire [4:0]  rd_addr1,
    input  wire [4:0]  rd_addr2,
    input  wire [4:0]  wr_addr,
    input  wire [31:0] wr_data,
    output wire [31:0] rd_data1,
    output wire [31:0] rd_data2
);

    reg [31:0] regs [0:31];
    integer i;

    // Synchronous write with x0 hardwired to 0
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
        end else if (reg_write && (wr_addr != 5'd0)) begin
            regs[wr_addr] <= wr_data;
        end
    end

    // Asynchronous read (x0 always returns 0)
    assign rd_data1 = (rd_addr1 != 5'd0) ? regs[rd_addr1] : 32'd0;
    assign rd_data2 = (rd_addr2 != 5'd0) ? regs[rd_addr2] : 32'd0;

endmodule
