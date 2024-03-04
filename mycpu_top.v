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
    
    // wire [31:0] inst_sram_addr_o,data_sram_addr_o;
    mycpu_core u_mycpu_core(
        .clk               (aclk              ),
        .rst               (~aresetn          ),
        .int               (ext_int           ),
        .inst_sram_en      (inst_sram_en      ),
        .inst_sram_wen     (inst_sram_wen     ),
        .inst_sram_addr    (inst_sram_addr_o  ),
        .inst_sram_wdata   (inst_sram_wdata   ),
        .inst_sram_rdata   (inst_sram_rdata   ),
        .data_sram_en      (data_sram_en      ),
        .data_sram_wen     (data_sram_wen     ),
        .data_sram_addr    (data_sram_addr_o  ),
        .data_sram_wdata   (data_sram_wdata   ),
        .data_sram_rdata   (data_sram_rdata   ),
        .debug_wb_pc       (debug_wb_pc       ),
        .debug_wb_rf_wen   (debug_wb_rf_wen   ),
        .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata (debug_wb_rf_wdata ),
        .stallreq_from_outside(1'b0)
    );
    
    // mmu u_mmu_inst(
    // 	.addr_i (inst_sram_addr_o ),
    //     .addr_o (inst_sram_addr )
    // );

    // mmu u_mmu_data(
    // 	.addr_i (data_sram_addr_o ),
    //     .addr_o (data_sram_addr )
    // );
    
    
    
    

endmodule 