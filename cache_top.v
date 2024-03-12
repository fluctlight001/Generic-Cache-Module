`include "def_cache.vh"
module cache_top(
    input wire clk,
    input wire rst,
    input wire flush,
    output wire stallreq,

    input wire inst_cached,
    input wire inst_sram_en,
    input wire [3:0] inst_sram_wen,
    input wire [31:0] inst_sram_addr,
    input wire [31:0] inst_sram_wdata,
    output wire [31:0] inst_sram_rdata,

    input wire icache_refresh,
    output wire icache_miss,
    output wire [31:0] icache_axi_raddr,
    output wire icache_write_back,
    output wire [31:0] icache_axi_waddr,
    output wire [`CACHELINE_WIDTH-1:0] icache_cacheline_old,
    input wire  [`CACHELINE_WIDTH-1:0] icache_cacheline_new,

    input wire data_cached,
    input wire data_sram_en,
    input wire [3:0] data_sram_wen,
    input wire [31:0] data_sram_addr,
    input wire [31:0] data_sram_wdata,
    output wire [31:0] data_sram_rdata,

    input wire dcache_refresh,
    output wire dcache_miss,
    output wire [31:0] dcache_axi_raddr,
    output wire dcache_write_back,
    output wire [31:0] dcache_axi_waddr,
    output wire [`CACHELINE_WIDTH-1:0] dcache_cacheline_old,
    input wire  [`CACHELINE_WIDTH-1:0] dcache_cacheline_new
);

    wire stallreq_from_icache, stallreq_from_dcache;
    assign stallreq = stallreq_from_icache | stallreq_from_dcache;

    cache_tag_v5 u_icache_tag(
        .clk        (clk                    ),
        .rst        (rst                    ),
        .flush      (flush                  ),
        .stallreq   (stallreq_from_icache   ),

        .cached     (inst_cached            ),
        .sram_en    (inst_sram_en           ),
        .sram_wen   (inst_sram_wen          ),
        .sram_addr  (inst_sram_addr         ),

        .refresh    (icache_refresh         ),
        .miss       (icache_miss            ),
        .axi_raddr  (icache_axi_raddr       ),
        .write_back (icache_write_back      ),
        .axi_waddr  (icache_waddr           ),
        .hit        (icache_hit             ),
        .lru        (icache_lru             )
    );

    cache_data_v5 u_icache_data(
        .clk           (clk                 ),
        .rst           (rst                 ),
        .write_back    (1'b0                ),
        .hit           (icache_hit          ),
        .lru           (icache_lru          ),
        .cached        (inst_cached         ),
        .sram_en       (inst_sram_en        ),
        .sram_wen      (inst_sram_wen       ),
        .sram_addr     (inst_sram_addr      ),
        .sram_wdata    (inst_sram_wdata     ),
        .sram_rdata    (inst_sram_rdata     ),
        .refresh       (icache_refresh      ),
        .cacheline_new (icache_cacheline_new),
        .cacheline_old (icache_cacheline_old)
    );

    cache_tag_v5 u_dcache_tag(
        .clk        (clk                    ),
        .rst        (rst                    ),
        .flush      (flush                  ),
        .stallreq   (stallreq_from_dcache   ),
        .cached     (data_cached            ),
        .sram_en    (data_sram_en           ),
        .sram_wen   (data_sram_wen          ),
        .sram_addr  (data_sram_addr         ),
        .refresh    (dcache_refresh         ),
        .miss       (dcache_miss            ),
        .axi_raddr  (dcache_axi_raddr       ),
        .write_back (dcache_write_back      ),
        .axi_waddr  (dcache_axi_waddr       ),
        .hit        (dcache_hit             ),
        .lru        (dcache_lru             )
    );
    
    cache_data_v5 u_dcache_data(
        .clk           (clk           ),
        .rst           (rst           ),

        .write_back    (dcache_write_back   ),
        .hit           (dcache_hit          ),
        .lru           (dcache_lru          ),
        .cached        (data_cached         ),
        .sram_en       (data_sram_en        ),
        .sram_wen      (data_sram_wen       ),
        .sram_addr     (data_sram_addr      ),
        .sram_wdata    (data_sram_wdata     ),
        .sram_rdata    (data_sram_rdata     ),
        .refresh       (dcache_refresh      ),
        .cacheline_new (dcache_cacheline_new),
        .cacheline_old (dcache_cacheline_old)
    );
    
    
endmodule