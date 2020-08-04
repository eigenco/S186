//`default_nettype none
module SegmentOverride(input logic clk,
                       input logic reset,
                       input logic next_instruction,
                       input logic flush,
                       input logic update,
                       input logic force_segment,
                       input logic bp_is_base,
                       input logic segment_override,
                       input logic [1:0] override_in,
                       input logic [1:0] microcode_sr_rd_sel,
                       output logic [1:0] sr_rd_sel);

reg [1:0] override;
reg override_active;

always_comb begin
    if (force_segment)
        sr_rd_sel = microcode_sr_rd_sel;
    else if (update && segment_override)
        sr_rd_sel = override_in;
    else if (override_active)
        sr_rd_sel = override;
    else if (bp_is_base)
        sr_rd_sel = SS;
    else
        sr_rd_sel = microcode_sr_rd_sel;
end

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        override_active <= 1'b0;
        override <= 2'b00;
    end else begin
        if (next_instruction || flush) begin
            override_active <= 1'b0;
            override <= 2'b00;
        end
        if (update && segment_override) begin
            override <= override_in;
            override_active <= 1'b1;
        end
    end
end

endmodule