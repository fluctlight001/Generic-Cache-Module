module cache_top(
    input wire clk,
    input wire rst,

    input wire inst_sram_en,
    input wire [3:0] inst_sram_wen,
    input wire [31:0] inst_sram_addr,
    input wire [31:0] inst_sram_wdata,
    output wire [31:0] inst_sram_rdata,

    input wire data_sram_en,
    input wire [3:0] data_sram_wen,
    input wire [31:0] data_sram_addr,
    input wire [31:0] data_sram_wdata,
    output wire [31:0] data_sram_rdata
);

    cache_tag_v5 u_cache_tag_v5(
        .clk        (clk        ),
        .rst        (rst        ),
        .flush      (flush      ),
        .stallreq   (stallreq   ),
        .cached     (cached     ),
        .sram_en    (sram_en    ),
        .sram_wen   (sram_wen   ),
        .sram_addr  (sram_addr  ),
        .refresh    (refresh    ),
        .miss       (miss       ),
        .axi_raddr  (axi_raddr  ),
        .write_back (write_back ),
        .axi_waddr  (axi_waddr  ),
        .hit        (hit        ),
        .lru        (lru        )
    );

    cache_data_v5 u_cache_data_v5(
        .clk           (clk           ),
        .rst           (rst           ),
        .write_back    (write_back    ),
        .hit           (hit           ),
        .lru           (lru           ),
        .cached        (cached        ),
        .sram_en       (sram_en       ),
        .sram_wen      (sram_wen      ),
        .sram_addr     (sram_addr     ),
        .sram_wdata    (sram_wdata    ),
        .sram_rdata    (sram_rdata    ),
        .refresh       (refresh       ),
        .cacheline_new (cacheline_new ),
        .cacheline_old (cacheline_old )
    );
    
    
endmodule