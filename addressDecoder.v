`timescale 1ns / 1ps
//------------------------------------------------------------------
// addressDecoder : data-space address decoding (memory-mapped I/O)
//
//   0x0000_0000 - 0x0000_03FF : RAM  (1 KB, holds the stack)
//   0x2000_0000               : LED     register  (R/W)
//   0x2000_0004               : SWITCH  register  (R)
//   0x2000_0008               : RESET   button    (R)
//------------------------------------------------------------------
module addressDecoder (
    input  [31:0] addr,
    output        sel_ram,
    output        sel_led,
    output        sel_sw,
    output        sel_rst
);
    assign sel_ram = (addr[31:10] == 22'd0);
    assign sel_led = (addr == 32'h2000_0000);
    assign sel_sw  = (addr == 32'h2000_0004);
    assign sel_rst = (addr == 32'h2000_0008);
endmodule
