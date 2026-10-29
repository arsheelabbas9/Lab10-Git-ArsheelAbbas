`timescale 1ns / 1ps
//==================================================================
// instructionMemory : byte-addressed ROM holding the machine code of
// the Task-2 assembly program (little-endian, 4 bytes / instruction).
// The 32-bit instruction at address A is {mem[A+3],mem[A+2],mem[A+1],mem[A]}.
//
// SIM_FAST = 1 replaces the two instructions that load the 1-second
// delay constant (2,500,000) with a short constant (40), so that the
// testbench finishes quickly.  Keep SIM_FAST = 0 for the FPGA.
//==================================================================
module instructionMemory #(
    parameter OPERAND_LENGTH = 31,
    parameter SIM_FAST       = 0
)(
    input      [OPERAND_LENGTH:0] instAddress,
    output     [31:0]             instruction
);
    reg [7:0] memory [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1) memory[i] = 8'h00;

        // 000: 40000113  addi sp, zero, 1024
        memory[0] = 8'h13; memory[1] = 8'h01; memory[2] = 8'h00; memory[3] = 8'h40;
        // 004: 20000437  lui s0, 0x20000
        memory[4] = 8'h37; memory[5] = 8'h04; memory[6] = 8'h00; memory[7] = 8'h20;
        // 008: 00042023  sw zero, 0(s0)
        memory[8] = 8'h23; memory[9] = 8'h20; memory[10] = 8'h04; memory[11] = 8'h00;
        // 00C: 00842283  lw t0, 8(s0)
        memory[12] = 8'h83; memory[13] = 8'h22; memory[14] = 8'h84; memory[15] = 8'h00;
        // 010: FE029CE3  bne t0, zero, WAIT_STATE
        memory[16] = 8'hE3; memory[17] = 8'h9C; memory[18] = 8'h02; memory[19] = 8'hFE;
        // 014: 00442503  lw a0, 4(s0)
        memory[20] = 8'h03; memory[21] = 8'h25; memory[22] = 8'h44; memory[23] = 8'h00;
        // 018: FE050AE3  beq a0, zero, WAIT_LOOP
        memory[24] = 8'hE3; memory[25] = 8'h0A; memory[26] = 8'h05; memory[27] = 8'hFE;
        // 01C: 00A42023  sw a0, 0(s0)
        memory[28] = 8'h23; memory[29] = 8'h20; memory[30] = 8'hA4; memory[31] = 8'h00;
        // 020: 008000EF  jal ra, COUNTDOWN
        memory[32] = 8'hEF; memory[33] = 8'h00; memory[34] = 8'h80; memory[35] = 8'h00;
        // 024: FE5FF06F  jal zero, WAIT_STATE
        memory[36] = 8'h6F; memory[37] = 8'hF0; memory[38] = 8'h5F; memory[39] = 8'hFE;
        // 028: FF010113  addi sp, sp, -16
        memory[40] = 8'h13; memory[41] = 8'h01; memory[42] = 8'h01; memory[43] = 8'hFF;
        // 02C: 00112623  sw ra, 12(sp)
        memory[44] = 8'h23; memory[45] = 8'h26; memory[46] = 8'h11; memory[47] = 8'h00;
        // 030: 00912423  sw s1, 8(sp)
        memory[48] = 8'h23; memory[49] = 8'h24; memory[50] = 8'h91; memory[51] = 8'h00;
        // 034: 00050493  addi s1, a0, 0
        memory[52] = 8'h93; memory[53] = 8'h04; memory[54] = 8'h05; memory[55] = 8'h00;
        // 038: 00942023  sw s1, 0(s0)
        memory[56] = 8'h23; memory[57] = 8'h20; memory[58] = 8'h94; memory[59] = 8'h00;
        // 03C: 00048A63  beq s1, zero, CD_DONE
        memory[60] = 8'h63; memory[61] = 8'h8A; memory[62] = 8'h04; memory[63] = 8'h00;
        // 040: 024000EF  jal ra, DELAY
        memory[64] = 8'hEF; memory[65] = 8'h00; memory[66] = 8'h40; memory[67] = 8'h02;
        // 044: 00051863  bne a0, zero, CD_EXIT
        memory[68] = 8'h63; memory[69] = 8'h18; memory[70] = 8'h05; memory[71] = 8'h00;
        // 048: FFF48493  addi s1, s1, -1
        memory[72] = 8'h93; memory[73] = 8'h84; memory[74] = 8'hF4; memory[75] = 8'hFF;
        // 04C: FEDFF06F  jal zero, CD_LOOP
        memory[76] = 8'h6F; memory[77] = 8'hF0; memory[78] = 8'hDF; memory[79] = 8'hFE;
        // 050: 00000513  addi a0, zero, 0
        memory[80] = 8'h13; memory[81] = 8'h05; memory[82] = 8'h00; memory[83] = 8'h00;
        // 054: 00812483  lw s1, 8(sp)
        memory[84] = 8'h83; memory[85] = 8'h24; memory[86] = 8'h81; memory[87] = 8'h00;
        // 058: 00C12083  lw ra, 12(sp)
        memory[88] = 8'h83; memory[89] = 8'h20; memory[90] = 8'hC1; memory[91] = 8'h00;
        // 05C: 01010113  addi sp, sp, 16
        memory[92] = 8'h13; memory[93] = 8'h01; memory[94] = 8'h01; memory[95] = 8'h01;
        // 060: 00008067  jalr zero, 0(ra)
        memory[96] = 8'h67; memory[97] = 8'h80; memory[98] = 8'h00; memory[99] = 8'h00;
        // 064: 002622B7  lui t0, 0x262
        memory[100] = 8'hB7; memory[101] = 8'h22; memory[102] = 8'h26; memory[103] = 8'h00;
        // 068: 5A028293  addi t0, t0, 0x5A0
        memory[104] = 8'h93; memory[105] = 8'h82; memory[106] = 8'h02; memory[107] = 8'h5A;
        // 06C: 00842303  lw t1, 8(s0)
        memory[108] = 8'h03; memory[109] = 8'h23; memory[110] = 8'h84; memory[111] = 8'h00;
        // 070: 00031A63  bne t1, zero, DLY_RST
        memory[112] = 8'h63; memory[113] = 8'h1A; memory[114] = 8'h03; memory[115] = 8'h00;
        // 074: FFF28293  addi t0, t0, -1
        memory[116] = 8'h93; memory[117] = 8'h82; memory[118] = 8'hF2; memory[119] = 8'hFF;
        // 078: FE029AE3  bne t0, zero, DLY_LOOP
        memory[120] = 8'hE3; memory[121] = 8'h9A; memory[122] = 8'h02; memory[123] = 8'hFE;
        // 07C: 00000513  addi a0, zero, 0
        memory[124] = 8'h13; memory[125] = 8'h05; memory[126] = 8'h00; memory[127] = 8'h00;
        // 080: 00008067  jalr zero, 0(ra)
        memory[128] = 8'h67; memory[129] = 8'h80; memory[130] = 8'h00; memory[131] = 8'h00;
        // 084: 00100513  addi a0, zero, 1
        memory[132] = 8'h13; memory[133] = 8'h05; memory[134] = 8'h10; memory[135] = 8'h00;
        // 088: 00008067  jalr zero, 0(ra)
        memory[136] = 8'h67; memory[137] = 8'h80; memory[138] = 8'h00; memory[139] = 8'h00;

        if (SIM_FAST) begin
            // lui  t0, 0x0      -> 0x000002B7   (@ 0x064)
            memory[100] = 8'hB7; memory[101] = 8'h02; memory[102] = 8'h00; memory[103] = 8'h00;
            // addi t0, t0, 40   -> 0x02828293   (@ 0x068)
            memory[104] = 8'h93; memory[105] = 8'h82; memory[106] = 8'h82; memory[107] = 8'h02;
        end
    end

    wire [7:0] a = {instAddress[7:2], 2'b00};
    assign instruction = {memory[a + 8'd3], memory[a + 8'd2], memory[a + 8'd1], memory[a]};
endmodule
