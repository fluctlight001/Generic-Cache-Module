`include "def_cache.vh"
module mycpu_top(
    input wire aclk,
    input wire aresetn,
    input wire [5:0] ext_int,

    output wire[3:0]   arid,
    output wire[31:0]  araddr,
    output wire[3:0]   arlen,
    output wire[2:0]   arsize,
    output wire[1:0]   arburst,
    output wire[1:0]   arlock,
    output wire[3:0]   arcache,
    output wire[2:0]   arprot,
    output wire        arvalid,
    input  wire        arready,

    input  wire[3:0]   rid,
    input  wire[31:0]  rdata,
    input  wire[1:0]   rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,

    output wire[3:0]   awid,
    output wire[31:0]  awaddr,
    output wire[3:0]   awlen,
    output wire[2:0]   awsize,
    output wire[1:0]   awburst,
    output wire[1:0]   awlock,
    output wire[3:0]   awcache,
    output wire[2:0]   awprot,
    output wire        awvalid,
    input  wire        awready,

    output wire[3:0]   wid,
    output wire[31:0]  wdata,
    output wire[3:0]   wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,

    input  wire[3:0]   bid,
    input  wire[1:0]   bresp,
    input  wire        bvalid,
    output wire        bready,

    output wire [31:0] debug_wb_pc,
    output wire [3 :0] debug_wb_rf_wen,
    output wire [4 :0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata 
);
    wire clk = aclk;
    wire rst = ~aresetn;

    wire inst_sram_en;
    wire [3:0] inst_sram_wen;
    wire [31:0] inst_sram_addr;
    wire [31:0] inst_sram_wdata;
    wire [31:0] inst_sram_rdata;

    wire data_sram_en;
    wire [3:0] data_sram_wen;
    wire [31:0] data_sram_addr;
    wire [31:0] data_sram_wdata;
    wire [31:0] data_sram_rdata;

    wire inst_cached, data_cached;
    wire [31:0] inst_sram_addr_o,data_sram_addr_o;

    

    // cache_top
    wire icache_refresh, dcache_refresh;
    wire icache_miss, dcache_miss;
    wire [31:0] icache_raddr, dcache_raddr;
    wire icache_write_back, dcache_write_back;
    wire [31:0] icache_waddr, dcache_waddr;
    wire [`CACHELINE_WIDTH-1:0] icache_cacheline_old, dcache_cacheline_old;
    wire [`CACHELINE_WIDTH-1:0] icache_cacheline_new, dcache_cacheline_new;

    // uncache
    wire        uncache_refresh;
    wire        uncache_en;
    wire [3:0]  uncache_wen;
    wire [31:0] uncache_addr;
    wire [31:0] uncache_wdata;
    wire [31:0] uncache_rdata;
    wire        uncache_hit;

    wire [31:0] dcache_temp_rdata;
    wire [31:0] uncache_temp_rdata;

    wire stallreq_outside;
    wire stallreq_icache;
    wire stallreq_dcache;
    wire stallreq_uncache;

    assign stallreq_outside = stallreq_icache | stallreq_dcache | stallreq_uncache;
    mycpu_core u_mycpu_core(
        .clk                    (clk               ),
        .rst                    (rst               ),
        .int                    (ext_int           ),

        .inst_sram_en           (inst_sram_en      ),
        .inst_sram_wen          (inst_sram_wen     ),
        .inst_sram_addr         (inst_sram_addr_o  ),
        .inst_sram_wdata        (inst_sram_wdata   ),
        .inst_sram_rdata        (inst_sram_rdata   ),

        .data_sram_en           (data_sram_en      ),
        .data_sram_wen          (data_sram_wen     ),
        .data_sram_addr         (data_sram_addr_o  ),
        .data_sram_wdata        (data_sram_wdata   ),
        .data_sram_rdata        (data_sram_rdata   ),

        .debug_wb_pc            (debug_wb_pc       ),
        .debug_wb_rf_wen        (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum       (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata      (debug_wb_rf_wdata ),

        .stallreq_from_outside  (stallreq_outside)
    );

    mmu u0_mmu(
        .addr_i  (inst_sram_addr_o  ),
        .addr_o  (inst_sram_addr    ),
        .cache_v (inst_cached       )
    );

    mmu u1_mmu(
        .addr_i  (data_sram_addr_o  ),
        .addr_o  (data_sram_addr    ),
        .cache_v (data_cached       )
    );
 
    cache u_icache(
        .clk           (clk           ),
        .rst           (rst           ),
        .sram_en       (inst_sram_en       ),
        .sram_wen      (inst_sram_wen      ),
        .sram_addr     (inst_sram_addr     ),
        .sram_wdata    (inst_sram_wdata    ),
        .refresh       (icache_refresh     ),
        .cached        (1'b1               ),
        .cacheline_new (icache_cacheline_new ),

        .stallreq      (stallreq_icache      ),
        .sram_rdata    (inst_sram_rdata    ),
        .miss          (icache_miss          ),
        .raddr         (icache_raddr         ),
        .waddr         (icache_waddr         ),
        .write_back    (icache_write_back    ),
        .cacheline_old (icache_cacheline_old )
    );

    cache u_dcache(
        .clk           (clk           ),
        .rst           (rst           ),
        .sram_en       (data_sram_en       ),
        .sram_wen      (data_sram_wen      ),
        .sram_addr     (data_sram_addr     ),
        .sram_wdata    (data_sram_wdata    ),
        .refresh       (dcache_refresh       ),
        .cached        (data_cached        ),
        .cacheline_new (dcache_cacheline_new ),

        .stallreq      (stallreq_dcache      ),
        .sram_rdata    (dcache_temp_rdata    ),
        .miss          (dcache_miss          ),
        .raddr         (dcache_raddr         ),
        .waddr         (dcache_waddr         ),
        .write_back    (dcache_write_back    ),
        .cacheline_old (dcache_cacheline_old )
    );
    

    reg data_cached_r;
    always @ (posedge clk) begin
        data_cached_r <= data_cached;
    end
    assign data_sram_rdata = data_cached_r ? dcache_temp_rdata : uncache_temp_rdata;
    
    
    uncache u_uncache(
        .clk        (clk                        ),
        .rst        (rst                        ),
        .stallreq   (stallreq_uncache      ),
        .conf_en    (data_sram_en & ~data_cached),
        .conf_wen   (data_sram_wen              ),
        .conf_addr  (data_sram_addr             ),
        .conf_wdata (data_sram_wdata            ),
        .conf_rdata (uncache_temp_rdata         ), 
        .axi_en     (uncache_en                 ),
        .axi_wsel   (uncache_wen                ),
        .axi_addr   (uncache_addr               ),
        .axi_wdata  (uncache_wdata              ),
        .reload     (uncache_refresh            ),
        .axi_rdata  (uncache_rdata              )
    );
    
    axi_control_v5 u_axi_control_v5(
        .clk                  (clk                  ),
        .rst                  (rst                  ),
        
        .icache_ren           (icache_miss          ),
        .icache_raddr         (icache_raddr         ),
        .icache_cacheline_new (icache_cacheline_new ),
        .icache_wen           (icache_write_back    ),
        .icache_waddr         (icache_waddr         ),
        .icache_cacheline_old (icache_cacheline_old ),
        .icache_refresh       (icache_refresh       ),
        
        .dcache_ren           (dcache_miss          ),
        .dcache_raddr         (dcache_raddr         ),
        .dcache_cacheline_new (dcache_cacheline_new ),
        .dcache_wen           (dcache_write_back    ),
        .dcache_waddr         (dcache_waddr         ),
        .dcache_cacheline_old (dcache_cacheline_old ),
        .dcache_refresh       (dcache_refresh       ),
        
        .uncache_en           (uncache_en           ),
        .uncache_wen          (uncache_wen          ),
        .uncache_addr         (uncache_addr         ),
        .uncache_wdata        (uncache_wdata        ),
        .uncache_rdata        (uncache_rdata        ),
        .uncache_refresh      (uncache_refresh      ),

        .arid                 (arid                 ),
        .araddr               (araddr               ),
        .arlen                (arlen                ),
        .arsize               (arsize               ),
        .arburst              (arburst              ),
        .arlock               (arlock               ),
        .arcache              (arcache              ),
        .arprot               (arprot               ),
        .arvalid              (arvalid              ),
        .arready              (arready              ),
        .rid                  (rid                  ),
        .rdata                (rdata                ),
        .rresp                (rresp                ),
        .rlast                (rlast                ),
        .rvalid               (rvalid               ),
        .rready               (rready               ),
        .awid                 (awid                 ),
        .awaddr               (awaddr               ),
        .awlen                (awlen                ),
        .awsize               (awsize               ),
        .awburst              (awburst              ),
        .awlock               (awlock               ),
        .awcache              (awcache              ),
        .awprot               (awprot               ),
        .awvalid              (awvalid              ),
        .awready              (awready              ),
        .wid                  (wid                  ),
        .wdata                (wdata                ),
        .wstrb                (wstrb                ),
        .wlast                (wlast                ),
        .wvalid               (wvalid               ),
        .wready               (wready               ),
        .bid                  (bid                  ),
        .bresp                (bresp                ),
        .bvalid               (bvalid               ),
        .bready               (bready               )
    );
    
    

endmodule 