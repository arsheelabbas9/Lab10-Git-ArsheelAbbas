`timescale 1ns / 1ps
//------------------------------------------------------------------
// dataMemory : 256 x 32-bit word RAM (1 KB), word accesses only
//   asynchronous read, synchronous write.  Used for the stack.
//------------------------------------------------------------------
module dataMemory (
    input         clk,
    input         memWrite,
    input  [31:0] address,
    input  [31:0] writeData,
    output [31:0] readData
);
    reg [31:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 32'd0;
    end

    wire [7:0] index = address[9:2];
    assign readData  = mem[index];

    always @(posedge clk) begin
        if (memWrite) mem[index] <= writeData;
    end
endmodule
