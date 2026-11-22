// ============================================================================
// Module: reg_select
// Description: Multiplexes register file outputs to onboard LEDs / debug bus
//              based on slide switch selection.
// ============================================================================

module reg_select (
    input  wire [31:0] reg0, reg1, reg2, reg3, reg4, reg5, reg6, reg7,
    input  wire [2:0]  SW,
    output wire [7:0]  LED,
    output reg  [31:0] reg_data_out
);

    always @(*) begin
        case (SW)
            3'd0: reg_data_out = reg0;
            3'd1: reg_data_out = reg1;
            3'd2: reg_data_out = reg2;
            3'd3: reg_data_out = reg3;
            3'd4: reg_data_out = reg4;
            3'd5: reg_data_out = reg5;
            3'd6: reg_data_out = reg6;
            3'd7: reg_data_out = reg7;
            default: reg_data_out = reg0;
        endcase
    end

    // Display lower 8 bits of selected register on LEDs (useful for FPGA boards)
    assign LED = reg_data_out[7:0];

endmodule
