`timescale 1ns / 1ps
//==================================================================
// lab10_top : Lab 10 - FSM in RISC-V assembly on a 10 MHz processor
//
//   clk  (100 MHz) --> clockDivider --> cpu_clk (10 MHz)
//   riscv_core <--> instructionMemory (program)
//   riscv_core <--> addressDecoder --> dataMemory (stack)
//                                  --> ioInterface (LED / SWITCH / RESET)
//
//   btnC : memory-mapped RESET button of the FSM
//   btnU : hardware reset of the processor (PC = 0), optional
//   SIM_FAST = 1 : shortens the 1 s delay (simulation only)
//==================================================================
module lab10_top #(
    parameter SIM_FAST = 0
)(
    input         clk,
    input         btnC,
    input         btnU,
    input  [15:0] sw,
    output [15:0] led
);
    //---------------- 10 MHz processor clock ---------
    wire cpu_clk;
    clockDivider #(.DIV(10), .USE_BUFG(SIM_FAST ? 0 : 1)) u_clkdiv (
        .clk_in (clk),
        .clk_out(cpu_clk)
    );

    //---------------- processor hardware reset -------
    reg rst_m = 1'b0, rst_s = 1'b0;
    always @(posedge cpu_clk) begin
        rst_m <= btnU;
        rst_s <= rst_m;
    end

    //---------------- core ---------------------------
    wire [31:0] instAddress, instruction;
    wire        memWrite, memRead;
    wire [31:0] dataAddress, dataWriteData, dataReadData;

    riscv_core u_core (
        .clk          (cpu_clk),
        .rst          (rst_s),
        .instAddress  (instAddress),
        .instruction  (instruction),
        .memWrite     (memWrite),
        .memRead      (memRead),
        .dataAddress  (dataAddress),
        .dataWriteData(dataWriteData),
        .dataReadData (dataReadData)
    );

    //---------------- instruction memory -------------
    instructionMemory #(.OPERAND_LENGTH(31), .SIM_FAST(SIM_FAST)) u_imem (
        .instAddress(instAddress),
        .instruction(instruction)
    );

    //---------------- address decoding ---------------
    wire sel_ram, sel_led, sel_sw, sel_rst;
    addressDecoder u_dec (
        .addr   (dataAddress),
        .sel_ram(sel_ram),
        .sel_led(sel_led),
        .sel_sw (sel_sw),
        .sel_rst(sel_rst)
    );

    //---------------- data memory (stack) ------------
    wire [31:0] ramData;
    dataMemory u_dmem (
        .clk      (cpu_clk),
        .memWrite (memWrite & sel_ram),
        .address  (dataAddress),
        .writeData(dataWriteData),
        .readData (ramData)
    );

    //---------------- memory-mapped I/O --------------
    wire [15:0] sw_sync, led_out;
    wire        btn_sync;
    ioInterface u_io (
        .clk     (cpu_clk),
        .sw_in   (sw),
        .btn_in  (btnC),
        .ledWrite(memWrite & sel_led),
        .ledData (dataWriteData[15:0]),
        .sw_sync (sw_sync),
        .btn_sync(btn_sync),
        .led_out (led_out)
    );
    assign led = led_out;

    //---------------- read-data multiplexer ----------
    assign dataReadData = sel_ram ? ramData :
                          sel_sw  ? {16'd0, sw_sync} :
                          sel_rst ? {31'd0, btn_sync} :
                          sel_led ? {16'd0, led_out} : 32'd0;
endmodule
