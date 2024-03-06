`include "defines.vh"
`define STAGE_WD 4
`define WAIT 4'b1000
`define IDLE 4'b0001
`define BUFFER 4'b0010
// `define VIRTUAL_UART_ADDR 32'h1faf_fff0
module uncache(
    input wire clk,
    input wire rst,
    output wire stallreq,

    input wire conf_en,
    input wire [3:0] conf_wen,
    input wire [31:0] conf_addr,
    input wire [31:0] conf_wdata,
    output reg [31:0] conf_rdata,

    output reg axi_en, // en
    output reg [3:0] axi_wsel, // wen
    output reg [31:0] axi_addr, // addr
    output reg [31:0] axi_wdata,

    input wire reload,
    input wire [31:0] axi_rdata
);
    reg valid;
    reg finish;
    reg buffer_valid;
    reg [`STAGE_WD-1:0] stage;

    wire conf_rd_req;
    wire conf_wr_req;
    assign conf_rd_req = conf_en & ~valid & ~(|conf_wen);
    assign conf_wr_req = conf_en & ~valid & (|conf_wen);

    assign stallreq = conf_rd_req & ~valid | conf_wr_req & buffer_valid & ~valid | stage[3];
    always @ (posedge clk) begin
        if (rst) begin
            valid <= 1'b0;
        end
        else if (finish) begin
            valid <= 1'b1;
        end
        else begin
            valid <= 1'b0;
        end
    end

    // assign rd_req = conf_en & ~valid & ~(|conf_wen);
    // assign rd_addr = conf_addr;
    // assign wr_req = conf_en & ~valid & (|conf_wen);
    // assign wr_wstrb = conf_wen;
    // assign wr_addr = conf_addr;
    // assign wr_data = conf_wdata;

    always @ (posedge clk) begin
        if (rst) begin
            conf_rdata <= 32'b0;
        end
        else if (reload) begin
            conf_rdata <= axi_rdata; 
        end
    end

    always @ (posedge clk) begin
        if (rst) begin
            buffer_valid <= 1'b0;

            stage <= `STAGE_WD'b1;
            finish <= 1'b0;

            axi_en <= 1'b0;
            axi_wsel <= 4'b0;
            axi_addr <= 32'b0;
            axi_wdata <= 32'b0;
        end
        else begin
            case(1'b1)
                stage[0]:begin
                    if (conf_rd_req & ~buffer_valid) begin
                        axi_en <= 1'b1;
                        axi_wsel <= conf_wen;
                        axi_addr <= conf_addr;
                        axi_wdata <= conf_wdata;
                        stage <= `WAIT;
                    end
                    else if (conf_wr_req & ~buffer_valid) begin
                        axi_en <= 1'b1;
                        axi_wsel <= conf_wen;
                        axi_addr <= conf_addr;
                        axi_wdata <= conf_wdata;
                        buffer_valid <= 1'b1;
                        // finish <= 1'b1;
                        stage <= `BUFFER;
                    end
                end
                stage[1]:begin //BUFFER 
                    // finish <= 1'b0;
                    if (reload) begin
                        buffer_valid <= 1'b0;
                        axi_en <= 1'b0;
                        axi_wsel <= 4'b0;
                        axi_addr <= 32'b0;
                        axi_wdata <= 32'b0;
                        stage <= `IDLE;
                    end
                end
                stage[3]:begin
                    if (reload) begin
                        axi_en <= 1'b0;
                        axi_wsel <= 4'b0;
                        axi_addr <= 32'b0;
                        axi_wdata <= 32'b0;
                        finish <= 1'b1;
                    end
                    else if (finish) begin
                        finish <= 1'b0;
                        stage <= `STAGE_WD'b1;
                    end
                end
                default:begin
                    stage <= `STAGE_WD'b1;
                end
            endcase
        end
    end
endmodule