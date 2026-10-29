`timescale 1ns / 1ps
//==================================================================
// riscv_core : single-cycle RV32I processor (1 instruction / clock)
//   Supports : add sub and or xor slt sltu sll srl sra
//              addi andi ori xori slti sltiu slli srli srai
//              lw sw  beq bne blt bge bltu bgeu  jal jalr lui auipc
//   Harvard style : separate instruction port and data port.
//==================================================================
module riscv_core (
    input         clk,
    input         rst,
    // instruction port
    output [31:0] instAddress,
    input  [31:0] instruction,
    // data port
    output        memWrite,
    output        memRead,
    output [31:0] dataAddress,
    output [31:0] dataWriteData,
    input  [31:0] dataReadData
);
    //---------------- program counter ----------------
    reg  [31:0] pc = 32'd0;
    wire [31:0] pcPlus4 = pc + 32'd4;
    reg  [31:0] nextPc;
    assign instAddress = pc;

    //---------------- instruction fields -------------
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd     = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    //---------------- immediate generation -----------
    wire [31:0] immI = {{20{instruction[31]}}, instruction[31:20]};
    wire [31:0] immS = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
    wire [31:0] immB = {{19{instruction[31]}}, instruction[31], instruction[7],
                        instruction[30:25], instruction[11:8], 1'b0};
    wire [31:0] immU = {instruction[31:12], 12'b0};
    wire [31:0] immJ = {{11{instruction[31]}}, instruction[31], instruction[19:12],
                        instruction[20], instruction[30:21], 1'b0};

    //---------------- control decode -----------------
    wire isOp     = (opcode == 7'b0110011);
    wire isOpImm  = (opcode == 7'b0010011);
    wire isLoad   = (opcode == 7'b0000011);
    wire isStore  = (opcode == 7'b0100011);
    wire isBranch = (opcode == 7'b1100011);
    wire isJal    = (opcode == 7'b1101111);
    wire isJalr   = (opcode == 7'b1100111);
    wire isLui    = (opcode == 7'b0110111);
    wire isAuipc  = (opcode == 7'b0010111);

    wire regWrite = isOp | isOpImm | isLoad | isJal | isJalr | isLui | isAuipc;
    wire useImm   = isOpImm | isLoad | isStore | isJalr | isLui | isAuipc;

    assign memWrite      = isStore;
    assign memRead       = isLoad;

    //---------------- register file ------------------
    reg [31:0] regs [0:31];
    integer k;
    initial begin
        for (k = 0; k < 32; k = k + 1) regs[k] = 32'd0;
    end

    wire [31:0] rs1Data = (rs1 == 5'd0) ? 32'd0 : regs[rs1];
    wire [31:0] rs2Data = (rs2 == 5'd0) ? 32'd0 : regs[rs2];

    //---------------- ALU ----------------------------
    wire [31:0] imm = isStore ? immS : ((isLui | isAuipc) ? immU : immI);
    wire [31:0] opA = isAuipc ? pc : (isLui ? 32'd0 : rs1Data);
    wire [31:0] opB = useImm ? imm : rs2Data;
    wire [4:0]  shamt = opB[4:0];

    reg [31:0] aluOut;
    always @(*) begin
        aluOut = opA + opB;                       // default : add (addr calc, lui, auipc ...)
        if (isOp | isOpImm) begin
            case (funct3)
                3'b000: aluOut = (isOp & funct7[5]) ? (opA - opB) : (opA + opB);
                3'b001: aluOut = opA << shamt;
                3'b010: aluOut = ($signed(opA) < $signed(opB)) ? 32'd1 : 32'd0;
                3'b011: aluOut = (opA < opB) ? 32'd1 : 32'd0;
                3'b100: aluOut = opA ^ opB;
                3'b101: begin
                    if (funct7[5]) aluOut = $signed(opA) >>> shamt;
                    else           aluOut = opA >> shamt;
                end
                3'b110: aluOut = opA | opB;
                3'b111: aluOut = opA & opB;
            endcase
        end
    end

    assign dataAddress   = aluOut;
    assign dataWriteData = rs2Data;

    //---------------- branch unit --------------------
    reg takeBranch;
    always @(*) begin
        case (funct3)
            3'b000:  takeBranch = (rs1Data == rs2Data);
            3'b001:  takeBranch = (rs1Data != rs2Data);
            3'b100:  takeBranch = ($signed(rs1Data) <  $signed(rs2Data));
            3'b101:  takeBranch = ($signed(rs1Data) >= $signed(rs2Data));
            3'b110:  takeBranch = (rs1Data <  rs2Data);
            3'b111:  takeBranch = (rs1Data >= rs2Data);
            default: takeBranch = 1'b0;
        endcase
    end

    //---------------- next PC ------------------------
    always @(*) begin
        if (isJal)                        nextPc = pc + immJ;
        else if (isJalr)                  nextPc = (rs1Data + immI) & 32'hFFFF_FFFE;
        else if (isBranch && takeBranch)  nextPc = pc + immB;
        else                              nextPc = pcPlus4;
    end

    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else     pc <= nextPc;
    end

    //---------------- write back ---------------------
    wire [31:0] wbData = (isJal | isJalr) ? pcPlus4 :
                         (isLoad)         ? dataReadData : aluOut;

    always @(posedge clk) begin
        if (regWrite && (rd != 5'd0) && !rst) regs[rd] <= wbData;
    end
endmodule
