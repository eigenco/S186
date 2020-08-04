task common_flags;
    inout [15:0] flags;
    input is_8_bit;
    input [15:0] out;
    input [15:0] a;
    input [15:0] b;

    begin
        flags[PF_IDX] = ~^out[7:0];
        flags[AF_IDX] = a[4] ^ b[4] ^ out[4];
        flags[SF_IDX] = out[is_8_bit ? 7 : 15];
        flags[ZF_IDX] = is_8_bit ? ~|out[7:0] : ~|out;
    end
endtask