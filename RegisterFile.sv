//`default_nettype none
module RegisterFile(input logic clk,
                    input logic reset,
                    input logic is_8_bit,
                    output logic [15:0] si,
                    output logic [15:0] di,
                    output logic [15:0] bp,
                    output logic [15:0] bx,
                    // Read port.
                    input logic [2:0] rd_sel[2],
                    output logic [15:0] rd_val[2],
                    // Write port.
                    input logic [2:0] wr_sel,
                    input logic [15:0] wr_val,
                    input logic wr_en);

reg [15:0] gprs[8];

wire wr_sel_low_byte = ~wr_sel[2];
wire [2:0] wr_8_bit_sel = {1'b0, wr_sel[1:0]};

always_ff @(posedge reset)
    ; // Reset is handled by the microcode.

always_ff @(posedge clk) begin
    if (wr_en) begin
        if (is_8_bit) begin
            if (wr_sel_low_byte)
                gprs[wr_8_bit_sel][7:0] <= wr_val[7:0];
            else
                gprs[wr_8_bit_sel][15:8] <= wr_val[7:0];
        end else begin
            gprs[wr_sel] <= wr_val;
        end
    end
end

always_ff @(posedge clk) begin
    si <= wr_en && !is_8_bit && wr_sel == SI ? wr_val : gprs[SI];
    di <= wr_en && !is_8_bit && wr_sel == DI ? wr_val : gprs[DI];
    bp <= wr_en && !is_8_bit && wr_sel == BP ? wr_val : gprs[BP];

    bx <= gprs[BX];
    if (wr_en && !is_8_bit && wr_sel == BX)
        bx <= wr_val;
    if (wr_en && is_8_bit && wr_sel == BL)
        bx <= {gprs[BX][15:8], wr_val[7:0]};
    if (wr_en && is_8_bit && wr_sel == BH)
        bx <= {wr_val[7:0], gprs[BX][7:0]};
end

genvar rd_port;

generate
for (rd_port = 0; rd_port < 2; ++rd_port) begin: read_port
    wire rd_sel_low_byte = ~rd_sel[rd_port][2];
    wire [2:0] rd_8_bit_sel = {1'b0, rd_sel[rd_port][1:0]};
    wire bypass = wr_en && wr_sel == rd_sel[rd_port];

    always_ff @(posedge clk) begin
        if (is_8_bit)
            rd_val[rd_port] <= bypass ? {8'b0, wr_val[7:0]} :
                {8'b0, rd_sel_low_byte ?
                    gprs[rd_8_bit_sel][7:0] : gprs[rd_8_bit_sel][15:8]};
        else
            rd_val[rd_port] <= bypass ? wr_val :
                gprs[rd_sel[rd_port]];
    end
end
endgenerate

endmodule