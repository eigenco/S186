//`default_nettype none
module IP(input logic clk,
          input logic reset,
          input logic start_instruction,
          input logic next_instruction,
          input logic rollback,
          input logic [3:0] inc,
          input logic wr_en,
          input logic [15:0] wr_val,
          output logic [15:0] val);

reg [15:0] cur_val;
reg [15:0] instruction_start_addr;
assign val = cur_val;

always_ff @(posedge clk or posedge reset)
    if (reset)
        instruction_start_addr <= 16'b0;
    else if (start_instruction || next_instruction)
        instruction_start_addr <= wr_en ? wr_val : cur_val;
    else if (next_instruction)
        instruction_start_addr <= cur_val;

always @(posedge clk or posedge reset)
    if (reset)
        cur_val <= 16'b0;
    else if (wr_en)
        cur_val <= wr_val;
    else if (rollback)
        cur_val <= instruction_start_addr;
    else if (start_instruction)
        cur_val <= cur_val + {12'b0, inc};

endmodule