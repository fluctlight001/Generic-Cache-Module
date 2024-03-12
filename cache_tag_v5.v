`include "def_cache.vh"
// 单行16条的版本
module cache_tag_v5(
    input wire clk,
    input wire rst,
    input wire flush,
    
    output wire stallreq,

    input wire cached,   //  根据是不是uncache，来控制cacheline是否可复用

    // sram_port
    input wire sram_en,
    input wire [3:0] sram_wen,
    input wire [31:0] sram_addr,
    // input wire [31:0] sram_wdata,
    // output wire [31:0] sram_rdata,
    // axi
    input wire refresh, // 刷新,控制新pc写入

    output wire miss,
    output wire [31:0] axi_raddr,
    output wire write_back,
    output wire [31:0] axi_waddr,

    // cache_data
    output wire [`HIT_WIDTH-1:0] hit,
    output wire lru
);
    reg [`TAG_WIDTH-1:0] tag_way0 [`INDEX_WIDTH-1:0]; // v + tag 
    reg [`TAG_WIDTH-1:0] tag_way1 [`INDEX_WIDTH-1:0];
    reg [`INDEX_WIDTH-1:0] lru_r;
    wire [`TAG_WIDTH-2:0] tag;
    wire [5:0] index;
    wire [5:0] offset;
    wire cached_v;
    // wire [`TAG_WIDTH-1:0] tag_ram_out;

    wire hit_way0;
    wire hit_way1;
    wire [31:0] axi_waddr_way0;
    wire [31:0] axi_waddr_way1;
    wire write_back_way0;
    wire write_back_way1;
    
    assign cached_v = cached;
    
    assign {
        tag,
        index,
        offset
    } = sram_addr;

    // tag_dist_ram u_tag_ram(
    //     .clk(clk),
    //     .we(refresh),
    //     .a(index),
    //     .d({cached_v,tag}),
    //     .spo(tag_ram_out)
    // );

    // lru lru_r指向的即为最闲的那个
    always @ (posedge clk) begin
        if (rst) begin
            lru_r  <= {`INDEX_WIDTH'b0};
        end
        else if (hit_way0 & ~hit_way1) begin
            lru_r[index] <= 1'b1;
        end
        else if (~hit_way0 & hit_way1) begin
            lru_r[index] <= 1'b0;
        end
        else if (refresh) begin
            lru_r[index] <= ~lru_r[index];
        end
    end

    // way0
    always @ (posedge clk) begin
        if (rst) begin
            tag_way0[  0] <= 21'b0;
            tag_way0[  1] <= 21'b0;
            tag_way0[  2] <= 21'b0;
            tag_way0[  3] <= 21'b0;
            tag_way0[  4] <= 21'b0;
            tag_way0[  5] <= 21'b0;
            tag_way0[  6] <= 21'b0;
            tag_way0[  7] <= 21'b0;
            tag_way0[  8] <= 21'b0;
            tag_way0[  9] <= 21'b0;
            tag_way0[ 10] <= 21'b0;
            tag_way0[ 11] <= 21'b0;
            tag_way0[ 12] <= 21'b0;
            tag_way0[ 13] <= 21'b0;
            tag_way0[ 14] <= 21'b0;
            tag_way0[ 15] <= 21'b0;
            tag_way0[ 16] <= 21'b0;
            tag_way0[ 17] <= 21'b0;
            tag_way0[ 18] <= 21'b0;
            tag_way0[ 19] <= 21'b0;
            tag_way0[ 20] <= 21'b0;
            tag_way0[ 21] <= 21'b0;
            tag_way0[ 22] <= 21'b0;
            tag_way0[ 23] <= 21'b0;
            tag_way0[ 24] <= 21'b0;
            tag_way0[ 25] <= 21'b0;
            tag_way0[ 26] <= 21'b0;
            tag_way0[ 27] <= 21'b0;
            tag_way0[ 28] <= 21'b0;
            tag_way0[ 29] <= 21'b0;
            tag_way0[ 30] <= 21'b0;
            tag_way0[ 31] <= 21'b0;
            tag_way0[ 32] <= 21'b0;
            tag_way0[ 33] <= 21'b0;
            tag_way0[ 34] <= 21'b0;
            tag_way0[ 35] <= 21'b0;
            tag_way0[ 36] <= 21'b0;
            tag_way0[ 37] <= 21'b0;
            tag_way0[ 38] <= 21'b0;
            tag_way0[ 39] <= 21'b0;
            tag_way0[ 40] <= 21'b0;
            tag_way0[ 41] <= 21'b0;
            tag_way0[ 42] <= 21'b0;
            tag_way0[ 43] <= 21'b0;
            tag_way0[ 44] <= 21'b0;
            tag_way0[ 45] <= 21'b0;
            tag_way0[ 46] <= 21'b0;
            tag_way0[ 47] <= 21'b0;
            tag_way0[ 48] <= 21'b0;
            tag_way0[ 49] <= 21'b0;
            tag_way0[ 50] <= 21'b0;
            tag_way0[ 51] <= 21'b0;
            tag_way0[ 52] <= 21'b0;
            tag_way0[ 53] <= 21'b0;
            tag_way0[ 54] <= 21'b0;
            tag_way0[ 55] <= 21'b0;
            tag_way0[ 56] <= 21'b0;
            tag_way0[ 57] <= 21'b0;
            tag_way0[ 58] <= 21'b0;
            tag_way0[ 59] <= 21'b0;
            tag_way0[ 60] <= 21'b0;
            tag_way0[ 61] <= 21'b0;
            tag_way0[ 62] <= 21'b0;
            tag_way0[ 63] <= 21'b0;
        end
        else if (refresh&(~lru_r[index])) begin
            tag_way0[index] <= {cached_v,tag};
        end
    end

    // way1
    always @ (posedge clk) begin
        if (rst) begin
            tag_way1[  0] <= 21'b0;
            tag_way1[  1] <= 21'b0;
            tag_way1[  2] <= 21'b0;
            tag_way1[  3] <= 21'b0;
            tag_way1[  4] <= 21'b0;
            tag_way1[  5] <= 21'b0;
            tag_way1[  6] <= 21'b0;
            tag_way1[  7] <= 21'b0;
            tag_way1[  8] <= 21'b0;
            tag_way1[  9] <= 21'b0;
            tag_way1[ 10] <= 21'b0;
            tag_way1[ 11] <= 21'b0;
            tag_way1[ 12] <= 21'b0;
            tag_way1[ 13] <= 21'b0;
            tag_way1[ 14] <= 21'b0;
            tag_way1[ 15] <= 21'b0;
            tag_way1[ 16] <= 21'b0;
            tag_way1[ 17] <= 21'b0;
            tag_way1[ 18] <= 21'b0;
            tag_way1[ 19] <= 21'b0;
            tag_way1[ 20] <= 21'b0;
            tag_way1[ 21] <= 21'b0;
            tag_way1[ 22] <= 21'b0;
            tag_way1[ 23] <= 21'b0;
            tag_way1[ 24] <= 21'b0;
            tag_way1[ 25] <= 21'b0;
            tag_way1[ 26] <= 21'b0;
            tag_way1[ 27] <= 21'b0;
            tag_way1[ 28] <= 21'b0;
            tag_way1[ 29] <= 21'b0;
            tag_way1[ 30] <= 21'b0;
            tag_way1[ 31] <= 21'b0;
            tag_way1[ 32] <= 21'b0;
            tag_way1[ 33] <= 21'b0;
            tag_way1[ 34] <= 21'b0;
            tag_way1[ 35] <= 21'b0;
            tag_way1[ 36] <= 21'b0;
            tag_way1[ 37] <= 21'b0;
            tag_way1[ 38] <= 21'b0;
            tag_way1[ 39] <= 21'b0;
            tag_way1[ 40] <= 21'b0;
            tag_way1[ 41] <= 21'b0;
            tag_way1[ 42] <= 21'b0;
            tag_way1[ 43] <= 21'b0;
            tag_way1[ 44] <= 21'b0;
            tag_way1[ 45] <= 21'b0;
            tag_way1[ 46] <= 21'b0;
            tag_way1[ 47] <= 21'b0;
            tag_way1[ 48] <= 21'b0;
            tag_way1[ 49] <= 21'b0;
            tag_way1[ 50] <= 21'b0;
            tag_way1[ 51] <= 21'b0;
            tag_way1[ 52] <= 21'b0;
            tag_way1[ 53] <= 21'b0;
            tag_way1[ 54] <= 21'b0;
            tag_way1[ 55] <= 21'b0;
            tag_way1[ 56] <= 21'b0;
            tag_way1[ 57] <= 21'b0;
            tag_way1[ 58] <= 21'b0;
            tag_way1[ 59] <= 21'b0;
            tag_way1[ 60] <= 21'b0;
            tag_way1[ 61] <= 21'b0;
            tag_way1[ 62] <= 21'b0;
            tag_way1[ 63] <= 21'b0;
        end
        else if (refresh&lru_r[index]) begin
            tag_way1[index] <= {cached_v,tag};
        end
    end

    // assign hit = cached_v & sram_en & ({1'b1,tag} == tag_ram_out);
    assign lru = lru_r[index];
    assign hit = {
        hit_way1,
        hit_way0
    };
    assign hit_way0 = ~flush & cached_v & sram_en & ({1'b1,tag} == tag_way0[index]);
    assign hit_way1 = ~flush & cached_v & sram_en & ({1'b1,tag} == tag_way1[index]);
    assign miss = cached_v & sram_en & ~(hit_way0|hit_way1) & ~flush;
    assign stallreq = miss;
    assign axi_raddr = cached_v ? {sram_addr[31:6],6'b0} : sram_addr;
    assign write_back = flush ? 1'b0 : lru ? write_back_way1 : write_back_way0;
    assign write_back_way0 = cached_v & sram_en & miss & tag_way0[index][`TAG_WIDTH-1];
    assign write_back_way1 = cached_v & sram_en & miss & tag_way1[index][`TAG_WIDTH-1];
    assign axi_waddr = lru_r[index] ? axi_waddr_way1 : axi_waddr_way0;
    assign axi_waddr_way0 = {
        tag_way0[index][`TAG_WIDTH-2:0],
        index,
        6'b0
    };
    assign axi_waddr_way1 = {
        tag_way1[index][`TAG_WIDTH-2:0],
        index,
        6'b0
    };
endmodule