`include "defines.vh"
module mmu (
    input wire[31:0] addr_i,
    output wire [31:0] addr_o,
    output wire cache_v
);
    wire [3:0] addr_head_i,addr_head_o;
    assign addr_head_i = addr_i[31:28];
    wire kseg0_l,kseg0_h,kseg1_l,kseg1_h;
    assign kseg0_l = addr_head_i == 4'b1000;
    assign kseg0_h = addr_head_i == 4'b1001;
    assign kseg1_l = addr_head_i == 4'b1010;
    assign kseg1_h = addr_head_i == 4'b1011;
    wire other_seg;
    assign other_seg = ~kseg0_l & ~kseg0_h & ~kseg1_l & ~kseg1_h;
    assign addr_head_o = {4{kseg0_l}}&4'b0000 | {4{kseg0_h}}&4'b0001 | {4{kseg1_l}}&4'b0000 | {4{kseg1_h}}&4'b0001 | {4{other_seg}}&addr_head_i;
    assign addr_o = {addr_head_o, addr_i[27:0]};

    assign cache_v = ~(kseg1_h|kseg1_l);
endmodule