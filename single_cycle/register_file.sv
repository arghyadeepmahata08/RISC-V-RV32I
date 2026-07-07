
// Register File - RTL (Refined)
module register_file (
  input  logic         clk,
  input  logic         reset_n,

  // Read register addresses
  input  logic [4:0]   rs1_addr,
  input  logic [4:0]   rs2_addr,

  // Write port
  input  logic [4:0]   rd_addr,
  input  logic         rf_wr_en,
  input  logic [31:0]  wr_data,

  // Read data outputs
  output logic [31:0]  rs1_data,
  output logic [31:0]  rs2_data
);

  // Register file: 32 x 32-bit registers
  logic [31:0] regs [0:31];
  integer i;

  // Write Logic
  always_ff @(posedge clk or negedge reset_n) begin

    if (!reset_n) begin
      for (i=0;i<32;i=i+1) regs[i] <= 32'b0; // Reset all registers to zero
    end

    else if (rf_wr_en && (rd_addr != 5'b0)) begin
      regs[rd_addr] <= wr_data; // Write data to register on write enable (except x0)
    end
  end

  assign rs1_data = regs[rs1_addr]; // Read data for rs1
  assign rs2_data = regs[rs2_addr]; // Read data for rs2

endmodule

