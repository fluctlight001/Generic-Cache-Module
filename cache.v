module cache
#(
    parameter HIT_WD       = 2,
    parameter LRU_WD       = 1,
    parameter CACHELINE_WD = 512
)
(
    input wire         clk,
    input wire         rst,
    input wire         sram_en,
    input wire  [ 3:0] sram_wen,
    input wire  [31:0] sram_addr,
    input wire  [31:0] sram_wdata,
    input wire         refresh,
    input wire         cached,
    input  [CACHELINE_WD -1:0] cacheline_new,
    
    output wire        stallreq,
    output wire [31:0] sram_rdata,
    output wire        miss,
    output wire [31:0] raddr,
    output wire [31:0] waddr,
    output wire        write_back,
    output wire [CACHELINE_WD -1:0] cacheline_old
);

    wire [HIT_WD       -1:0] hit;
    wire [LRU_WD       -1:0] lru;
    
    cache_tag_v5 u_cache_tag(
    	.clk        (clk             ),
        .rst        (rst             ),
        .flush      (1'b0            ),
        .stallreq   (stallreq        ),
        .cached     (1'b1            ),
        .sram_en    (sram_en         ),
        .sram_we    (sram_we         ),
        .sram_addr  (sram_addr       ),
        .refresh    (refresh         ),
        .miss       (miss            ),
        .axi_raddr  (raddr           ),
        .write_back (write_back      ),
        .axi_waddr  (waddr           ),
        .hit        (hit             ),
        .lru        (lru             )
    );

    cache_data_v5 u_cache_data(
    	.clk           (clk          ),
        .rst           (rst          ),
        .write_back    (write_back   ),
        .hit           (hit          ),
        .lru           (lru          ),
        .cached        (cached       ),
        .sram_en       (sram_en      ),
        .sram_we       (sram_we      ),
        .sram_addr     (sram_addr    ),
        .sram_wdata    (sram_wdata   ),
        .sram_rdata    (sram_rdata   ),
        .refresh       (refresh      ),
        .cacheline_new (cacheline_new   ),
        .cacheline_old (cacheline_old   ) 
    );

endmodule