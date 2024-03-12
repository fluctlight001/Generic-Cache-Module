`include "def_cache.vh"
`define STAGE_WIDTH 12
// `define TAG_WIDTH 20
// `define INDEX_WIDTH 128 // 块高
// `define CACHELINE_WIDTH 256 // 块宽
module axi_control_v5(
    input wire clk,
    input wire rst,

    // icache interface
    input wire icache_ren, // miss
    input wire [31:0] icache_raddr, // miss_addr
    output reg [`CACHELINE_WIDTH-1:0] icache_cacheline_new,

    input wire icache_wen, // wen_back
    input wire [31:0] icache_waddr, // waddr
    input wire [`CACHELINE_WIDTH-1:0] icache_cacheline_old, // wback

    output reg icache_refresh, 

    // dcache interface
    input wire dcache_ren, // miss
    input wire [31:0] dcache_raddr, // miss_addr
    output reg [`CACHELINE_WIDTH-1:0] dcache_cacheline_new,

    input wire dcache_wen, // wen_back
    input wire [31:0] dcache_waddr, // waddr
    input wire [`CACHELINE_WIDTH-1:0] dcache_cacheline_old, // wback
    
    output reg dcache_refresh, // fin

    // uncache  interface
    input wire uncache_en,
    input wire [3:0] uncache_wen,
    input wire [31:0] uncache_addr,
    input wire [31:0] uncache_wdata,
    output reg [31:0] uncache_rdata,
    output reg uncache_refresh,

    //总线侧接口
    //读地址通道信号
    output reg [3:0]	    arid,//读地址ID，用来标志一组写信号
    output reg [31:0]	    araddr,//读地址，给出一次写突发传输的读地址
    output reg [3:0]	    arlen,//突发长度，给出突发传输的次数
    output reg [2:0]	    arsize,//突发大小，给出每次突发传输的字节数
    output reg [1:0]	    arburst,//突发类型
    output reg [1:0]	    arlock,//总线锁信号，可提供操作的原子性
    output reg [3:0]	    arcache,//内存类型，表明一次传输是怎样通过系统的
    output reg [2:0]	    arprot,//保护类型，表明一次传输的特权级及安全等级
    output reg 		        arvalid,//有效信号，表明此通道的地址控制信号有效
    input  wire		        arready,//表明"从"可以接收地址和对应的控制信号
    //读数据通道信号
    input  wire [3:0]	    rid,//读ID tag
    input  wire [31:0]	    rdata,//读数据
    input  wire [1:0]	    rresp,//读响应，表明读传输的状态
    input  wire		        rlast,//表明读突发的最后一次传输
    input  wire		        rvalid,//表明此通道信号有效
    output reg		        rready,//表明主机能够接收读数据和响应信息

    //写地址通道信号
    output reg [3:0]	    awid,//写地址ID，用来标志一组写信号
    output reg [31:0]	    awaddr,//写地址，给出一次写突发传输的写地址
    output reg [3:0]	    awlen,//突发长度，给出突发传输的次数
    output reg [2:0]	    awsize,//突发大小，给出每次突发传输的字节数
    output reg [1:0]	    awburst,//突发类型
    output reg [1:0]	    awlock,//总线锁信号，可提供操作的原子性
    output reg [3:0]	    awcache,//内存类型，表明一次传输是怎样通过系统的
    output reg [2:0]	    awprot,//保护类型，表明一次传输的特权级及安全等级
    output reg 		        awvalid,//有效信号，表明此通道的地址控制信号有效
    input  wire		        awready,//表明"从"可以接收地址和对应的控制信号

    //写数据通道信号
    output reg [3:0]	    wid,//一次写传输的ID tag
    output reg [31:0]	    wdata,//写数据
    output reg [3:0]	    wstrb,//写数据有效的字节线，用来表明哪8bits数据是有效的
    output reg 		        wlast,//表明此次传输是最后一个突发传输
    output reg		        wvalid,//写有效，表明此次写有效
    input  wire		        wready,//表明从机可以接收写数据
    //写响应通道信号
    input  wire [3:0]	    bid,//写响应ID tag
    input  wire [1:0]	    bresp,//写响应，表明写传输的状态 00为正常，当然可以不理会
    input  wire		        bvalid,//写响应有效
    output reg		        bready//表明主机能够接收写响应
);

    reg [`CACHELINE_WIDTH-1:0] icache_rdata_buffer;
    reg [`CACHELINE_WIDTH-1:0] icache_wdata_buffer;
    reg [`CACHELINE_WIDTH-1:0] dcache_rdata_buffer;
    reg [`CACHELINE_WIDTH-1:0] dcache_wdata_buffer;
    reg [31:0] icache_raddr_buffer;
    reg [31:0] icache_waddr_buffer;
    reg [31:0] dcache_raddr_buffer;
    reg [31:0] dcache_waddr_buffer;
    reg [3:0] icache_offset;
    reg [3:0] dcache_offset;
    reg [3:0] dcache_offset_w;
    reg icache_ren_buffer;
    reg dcache_ren_buffer;
    reg icache_wen_buffer;
    reg dcache_wen_buffer;
    
    reg uncache_en_buffer;
    reg [3:0] uncache_wen_buffer;
    reg [31:0] uncache_addr_buffer;
    reg [31:0] uncache_wdata_buffer; 
    reg [31:0] uncache_rdata_buffer;

    reg [`STAGE_WIDTH-1:0] stage;
    reg [`STAGE_WIDTH-1:0] stage_w;
    always @ (posedge clk) begin
        if (rst) begin
            arid <= 4'b0000;
            araddr <= 32'b0;
            arlen <= 4'b0000;
            arsize <= 3'b010;
            arburst <= 2'b01;
            arlock <= 2'b00;
            arcache <= 4'b0000;
            arprot <= 3'b000;
            arvalid <= 1'b0;

            rready <= 1'b0;

            
            stage <= `STAGE_WIDTH'b1;

            icache_refresh <= 1'b0;
            dcache_refresh <= 1'b0;
            icache_cacheline_new <= `CACHELINE_WIDTH'b0;
            dcache_cacheline_new <= `CACHELINE_WIDTH'b0;

            uncache_refresh <= 1'b0;
            uncache_rdata <= 32'b0;
        end
        else begin
            case (1'b1)
                stage[0]:begin
                    icache_refresh <= 1'b0;
                    dcache_refresh <= 1'b0;
                    uncache_refresh <= 1'b0;

                    icache_ren_buffer <= icache_ren;
                    icache_raddr_buffer <= icache_raddr;
                    icache_wen_buffer <= icache_wen;
                    icache_waddr_buffer <= icache_waddr;
                    
                    dcache_ren_buffer <= dcache_ren;
                    dcache_raddr_buffer <= dcache_raddr;
                    dcache_wen_buffer <= dcache_wen;
                    dcache_waddr_buffer <= dcache_waddr;

                    uncache_en_buffer <= uncache_en;
                    uncache_wen_buffer <= uncache_wen;
                    uncache_addr_buffer <= uncache_addr;
                    uncache_wdata_buffer <= uncache_wdata;

                    if (dcache_wen|(uncache_en&((|uncache_wen)))) begin
                        stage <= stage << 1;    
                    end
                    else if (icache_ren|dcache_ren|(uncache_en&~(|uncache_wen))) begin
                        stage <= stage << 2;
                    end
                end
                stage[1]:begin
                    icache_wdata_buffer <= icache_cacheline_old;
                    dcache_wdata_buffer <= dcache_cacheline_old;
                    // uncache_wdata_buffer <= uncache_wdata;
                    if (icache_ren_buffer|dcache_ren_buffer|(uncache_en_buffer&~(|uncache_wen_buffer))) begin
                        stage <= stage << 1;
                    end
                    else begin
                        stage <= {1'b0,1'b1,10'b0};
                    end
                end
                stage[2]:begin
                    if (icache_ren_buffer) begin
                        arid <= 4'b0;
                        araddr <= icache_raddr_buffer;
                        arlen <= 4'hf;
                        arsize <= 3'b010;
                        arvalid <= 1'b1;

                        stage <= stage << 1;
                    end
                    else begin
                        stage <= stage << 3;
                    end
                end
                stage[3]:begin
                    if (arready) begin
                        arvalid <= 1'b0;
                        araddr <= 32'b0;
                        rready <= 1'b1;
                        icache_offset <= 4'd0;
                        stage <= stage << 1;
                    end
                end
                stage[4]:begin
                    if (!rlast&rvalid) begin
                        icache_rdata_buffer[icache_offset*32+:32] <= rdata;
                        icache_offset <= icache_offset + 1'b1;
                    end
                    else if(rlast&rvalid) begin
                        icache_rdata_buffer[icache_offset*32+:32] <= rdata;
                        rready <= 1'b0;
                        stage <= stage << 1;
                    end
                end
                stage[5]:begin
                    if (dcache_ren_buffer) begin
                        arid <= 4'b1;
                        araddr <= dcache_raddr_buffer;
                        arlen <= 4'hf;
                        arsize <= 3'b010;
                        arvalid <= 1'b1;

                        stage <= stage << 1;
                    end
                    else if (uncache_en_buffer&~(|uncache_wen_buffer)) begin
                        arid <= 4'b1;
                        araddr <= uncache_addr_buffer;
                        arlen <= 4'b0;
                        arsize <= 3'b010;
                        arvalid <= 1'b1;
                        stage <= stage << 3;
                    end
                    else begin
                        stage <= {1'b0,1'b1,10'b0};
                    end
                end
                stage[6]:begin
                    if (arready) begin
                        arvalid <= 1'b0;
                        araddr <= 32'b0;
                        rready <= 1'b1;
                        dcache_offset <= 4'd0;
                        stage <= stage << 1;
                    end
                end
                stage[7]:begin
                    if (!rlast&rvalid) begin
                        dcache_rdata_buffer[dcache_offset*32+:32] <= rdata;
                        dcache_offset <= dcache_offset + 1'b1;
                    end
                    else if (rlast&rvalid) begin
                        dcache_rdata_buffer[dcache_offset*32+:32] <= rdata;
                        rready <= 1'b0;
                        stage <= {1'b0,1'b1,10'b0};
                    end
                end
                stage[8]:begin
                    if (arready) begin
                        arvalid <= 1'b0;
                        araddr <= 32'b0;
                        rready <= 1'b1;
                        stage <= stage << 1;
                    end
                end
                stage[9]:begin
                    if (rvalid) begin
                        uncache_rdata_buffer <= rdata;
                        rready <= 1'b0;
                        stage <= {1'b0,1'b1,10'b0};
                    end
                end
                stage[10]:begin
                    if (stage_w[10]|stage_w[0]) begin
                        stage <= stage << 1;
                    end
                end
                stage[11]:begin
                    if (icache_ren_buffer) begin
                        icache_refresh <= 1'b1;
                        icache_cacheline_new <= icache_rdata_buffer;
                    end
                    // if (dcache_ren_buffer|dcache_wen_buffer) begin
                    if (dcache_ren_buffer) begin
                        dcache_refresh <= 1'b1;
                        dcache_cacheline_new <= dcache_rdata_buffer;
                    end
                    if (uncache_en_buffer) begin
                        uncache_refresh <= 1'b1;   
                        uncache_rdata <= uncache_rdata_buffer;
                    end
                    stage <= `STAGE_WIDTH'b0;
                end
                default:begin
                    stage <= `STAGE_WIDTH'b1;
                    icache_refresh <= 1'b0;
                    dcache_refresh <= 1'b0;
                    uncache_refresh <= 1'b0;
                end
            endcase
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            awid <= 4'b0001;
            awaddr <= 32'b0;
            awlen <= 4'b0000;
            awsize <= 3'b010;
            awburst <= 2'b01;
            awlock <= 2'b00;
            awcache <= 4'b0000;
            awprot <= 3'b000;
            awvalid <= 1'b0;

            wid <= 4'b0001;
            wdata <= 32'b0;
            wstrb <= 4'b0000;
            wlast <= 1'b0;
            wvalid <= 1'b0;

            bready <= 1'b0;
            
            stage_w <= `STAGE_WIDTH'b1;
        end
        else begin
            case (1'b1)
                stage_w[0]:begin
                    if (stage[1]) begin
                        if (dcache_wen_buffer) begin
                            awid <= 4'b1;
                            awaddr <= dcache_waddr_buffer;
                            awlen <= 4'hf;
                            awsize <= 3'b010;
                            awvalid <= 1'b1;
                            wstrb <= 4'b1111;
                            wlast <= 1'b0;
                            bready <= 1'b1;
                            dcache_offset_w <= 4'b0;
                            stage_w <= stage_w << 1;
                        end
                        else if (|uncache_wen_buffer) begin // write
                            awid <= 4'b1;
                            awaddr <= uncache_addr_buffer;
                            awlen <= 4'b0;
                            case (uncache_wen_buffer)
                                4'b0001,4'b0010,4'b0100,4'b1000:begin
                                    awsize <= 3'b000; 
                                    wstrb <= uncache_wen_buffer;       
                                end
                                4'b0011,4'b1100:begin
                                    awsize <= 3'b001;
                                    wstrb <= uncache_wen_buffer;
                                end
                                4'b1111:begin
                                    awsize <= 3'b010;
                                    wstrb <= uncache_wen_buffer;
                                end
                                default:begin
                                    awsize <= 3'b010;
                                    wstrb <= uncache_wen_buffer;
                                end
                            endcase
                            awvalid <= 1'b1;
                            wlast <= 1'b0;
                            bready <= 1'b1;
                            stage_w <= stage_w << 4;
                        end
                    end
                end
                stage_w[1]:begin
                    if (awready) begin
                        awvalid <= 1'b0;
                        awaddr <= 32'b0;
                        wdata <= dcache_wdata_buffer[dcache_offset_w*32+:32];
                        wvalid <= 1'b1;
                        wlast <= dcache_offset_w == 4'b1111 ? 1'b1 : 1'b0;
                        dcache_offset_w <= dcache_offset_w + 1'b1;
                        if (dcache_offset_w == 4'b1111) begin
                            stage_w <= stage_w << 1;
                        end
                    end
                end
                stage_w[2]:begin
                    if (wready) begin
                        wdata <= 32'b0;
                        wvalid <= 1'b0;    
                        wlast <= 1'b0;
                        stage_w <= stage_w << 1;
                    end
                end
                stage_w[3]:begin
                    if (bvalid) begin
                        bready <= 1'b0;
                        stage_w <= {1'b0,1'b1,{10{1'b0}}};
                    end
                end
                stage_w[4]:begin
                    if (awready) begin
                        awvalid <= 1'b0;
                        awaddr <= 32'b0;
                        wdata <= uncache_wdata_buffer;
                        wvalid <= 1'b1;
                        wlast <= 1'b1;
                        stage_w <= stage_w << 1;
                    end
                end
                stage_w[5]:begin
                    if (wready) begin
                        wdata <= 32'b0;
                        wvalid <= 1'b0;
                        wlast <= 1'b0;
                        stage_w <= stage_w << 1;
                    end
                end
                stage_w[6]:begin
                    if (bvalid) begin
                        bready <= 1'b0;
                        stage_w <= {1'b0,1'b1,{10{1'b0}}};
                    end
                end
                stage_w[10]:begin
                    if (stage[11]) begin
                        stage_w <= `STAGE_WIDTH'b1;        
                    end
                end
                default:begin
                    stage_w <= `STAGE_WIDTH'b1;
                end
            endcase
        end
    end
endmodule
