`timescale 1ns / 1ps
//------------------------------------------------------------------
// ioInterface : memory-mapped peripherals
//   - 2-flop synchronisers for the (asynchronous) switches / button
//   - 16-bit LED output register written by the processor
//------------------------------------------------------------------
module ioInterface (
    input             clk,
    input      [15:0] sw_in,
    input             btn_in,
    input             ledWrite,
    input      [15:0] ledData,
    output reg [15:0] sw_sync,
    output reg        btn_sync,
    output reg [15:0] led_out
);
    reg [15:0] sw_meta  = 16'd0;
    reg        btn_meta = 1'b0;

    initial begin
        sw_sync  = 16'd0;
        btn_sync = 1'b0;
        led_out  = 16'd0;
    end

    always @(posedge clk) begin
        sw_meta  <= sw_in;
        sw_sync  <= sw_meta;
        btn_meta <= btn_in;
        btn_sync <= btn_meta;
        if (ledWrite) led_out <= ledData;
    end
endmodule
