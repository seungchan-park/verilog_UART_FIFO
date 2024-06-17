`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/24 09:58:14
// Design Name: 
// Module Name: uart_fifo
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


module uart_fifo (
    input        clk,
    input        reset,

    output       tx,
    input        tx_en,
    input  [7:0] tx_data,
    output       tx_full,

    input        rx,
    input        rx_en,
    output [7:0] rx_data,
    output       rx_empty
);
    wire w_tx_fifo_empty, w_tx_done, w_rx_done;
    wire [7:0] w_tx_fifo_rdata, w_rx_data;

    fifo #(
        .ADDR_WIDTH(3),
        .DATA_WIDTH(8)
    ) U_RX_FIFO (
        .clk  (clk),
        .reset(reset),

        .wr_en(w_rx_done),
        .full (),
        .wdata(w_rx_data),
        .rd_en(rx_en),
        .empty(rx_empty),
        .rdata(rx_data)
    );

    fifo #(
        .ADDR_WIDTH(3),
        .DATA_WIDTH(8)
    ) U_TX_FIFO (
        .clk  (clk),
        .reset(reset),
        
        .wr_en(tx_en),
        .full (tx_full),
        .wdata(tx_data),
        .rd_en(w_tx_done),
        .empty(w_tx_fifo_empty),
        .rdata(w_tx_fifo_rdata)
    );

    uart U_UART (
        .clk    (clk),
        .reset  (reset),
        // Transmitter
        .tx     (tx),
        .start  (~w_tx_fifo_empty),
        .tx_data(w_tx_fifo_rdata),
        .tx_done(w_tx_done),
        // Receiver
        .rx     (rx),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );
endmodule
