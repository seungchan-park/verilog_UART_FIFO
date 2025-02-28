`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/23 10:38:11
// Design Name: 
// Module Name: fifo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fifo #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    output                  full,
    input  [DATA_WIDTH-1:0] wdata,
    input                   rd_en,
    output                  empty,
    output [DATA_WIDTH-1:0] rdata
);
    wire [ADDR_WIDTH-1:0] w_waddr, w_raddr;

    register_file #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) U_RegFile (
        .clk  (clk),
        .reset(reset),
        .wr_en(wr_en & ~full),
        .waddr(w_waddr),
        .wdata(wdata),
        .raddr(w_raddr),
        .rdata(rdata)
    );

    fifo_control_unit #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_FIFO_CU (
        .clk  (clk),
        .reset(reset),
        .wr_en(wr_en),
        .full (full),
        .waddr(w_waddr),
        .rd_en(rd_en),
        .empty(empty),
        .raddr(w_raddr)
    );

endmodule

module register_file #(
    parameter ADDR_WIDTH = 3,
    DATA_WIDTH = 8
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    input  [ADDR_WIDTH-1:0] waddr,
    input  [DATA_WIDTH-1:0] wdata,
    input  [ADDR_WIDTH-1:0] raddr,
    output [DATA_WIDTH-1:0] rdata
);
    reg [DATA_WIDTH-1:0] mem[0:2**ADDR_WIDTH-1];

    always @(posedge clk) begin
        if (wr_en) mem[waddr] <= wdata;
    end

    assign rdata = mem[raddr];
endmodule

module fifo_control_unit #(
    parameter ADDR_WIDTH = 3
) (
    input                   clk,
    input                   reset,
    input                   wr_en,
    output                  full,
    output [ADDR_WIDTH-1:0] waddr,
    input                   rd_en,
    output                  empty,
    output [ADDR_WIDTH-1:0] raddr
);
    reg [ADDR_WIDTH-1:0] wr_ptr_reg, wr_ptr_next;
    reg [ADDR_WIDTH-1:0] rd_ptr_reg, rd_ptr_next;
    reg full_reg, full_next, empty_reg, empty_next;

    assign waddr = wr_ptr_reg;
    assign raddr = rd_ptr_reg;
    assign full  = full_reg;
    assign empty = empty_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            wr_ptr_reg <= 0;
            rd_ptr_reg <= 0;
            full_reg   <= 1'b0;
            empty_reg  <= 1'b1;
        end else begin
            wr_ptr_reg <= wr_ptr_next;
            rd_ptr_reg <= rd_ptr_next;
            full_reg   <= full_next;
            empty_reg  <= empty_next;
        end
    end

    always @(*) begin
        wr_ptr_next = wr_ptr_reg;
        rd_ptr_next = rd_ptr_reg;
        full_next   = full_reg;
        empty_next  = empty_reg;
        case ({
            wr_en, rd_en
        })
            2'b01: begin  // read
                if (!empty_reg) begin
                    full_next   = 1'b0;
                    rd_ptr_next = rd_ptr_reg + 1;
                    if (rd_ptr_next == wr_ptr_reg) begin
                        empty_next = 1'b1;
                    end
                end
            end
            2'b10: begin  // write
                if (!full_reg) begin
                    empty_next  = 1'b0;
                    wr_ptr_next = wr_ptr_reg + 1;
                    if (wr_ptr_next == rd_ptr_reg) begin
                        full_next = 1'b1;
                    end
                end
            end
            2'b11: begin  // write, read
                if (empty_reg) begin // 전부 비어있으므로 쓴것을 바로 읽음
                    wr_ptr_next = wr_ptr_reg;
                    rd_ptr_next = rd_ptr_reg;
                end else begin  // full상태이므로 
                    wr_ptr_next = wr_ptr_reg + 1;
                    rd_ptr_next = rd_ptr_reg + 1;
                end
            end
        endcase
    end
endmodule
