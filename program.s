# =====================================================================
#  Lab 10 : State-Based Control Flow Using RISC-V Assembly
#  FSM : INPUT_WAIT  <-->  COUNTDOWN   (same behaviour as Lab 5)
#
#  Data-space memory map (address decoding)
#     0x0000_0000 - 0x0000_03FF : RAM (1 KB, stack lives here)
#     0x2000_0000 : LED     (R/W, 16 bit)
#     0x2000_0004 : SWITCH  (R  , 16 bit)
#     0x2000_0008 : RESET   (R  , bit 0 = 1 while button pressed)
#
#  Register use
#     sp (x2)  : stack pointer, initialised to 0x400 (top of RAM)
#     s0 (x8)  : base address of the memory-mapped I/O (global, never modified)
#     s1 (x9)  : counter value inside COUNTDOWN (callee-saved -> pushed on stack)
#     a0 (x10) : argument / return value
#     t0,t1    : temporaries
#  Clock = 10 MHz  ->  DELAY loop = 4 instr/iteration * 2,500,000 = 10,000,000 cycles = 1 s
# =====================================================================
        .text
_start:
        addi  sp, zero, 1024        # sp = 0x400 (stack grows downward)
        lui   s0, 0x20000           # s0 = 0x2000_0000 (I/O base)

# ---------------- STATE 0 : INPUT_WAIT ----------------
WAIT_STATE:
        sw    zero, 0(s0)           # LEDs = 0, counter cleared
WAIT_LOOP:
        lw    t0, 8(s0)             # read reset button
        bne   t0, zero, WAIT_STATE  # reset pressed -> clear LEDs, stay in INPUT_WAIT
        lw    a0, 4(s0)             # read switches
        beq   a0, zero, WAIT_LOOP   # switches == 0 -> keep waiting
        sw    a0, 0(s0)             # capture value and show it on the LEDs
        jal   ra, COUNTDOWN         # STATE 1 : COUNTDOWN(a0)
        jal   zero, WAIT_STATE      # finished or aborted by reset -> INPUT_WAIT

# ---------------- STATE 1 : COUNTDOWN subroutine ----------------
# in : a0 = initial count     out : a0 = 0 (finished) / 1 (aborted by reset)
COUNTDOWN:
        addi  sp, sp, -16           # push frame
        sw    ra, 12(sp)            # save return address (needed: we call DELAY)
        sw    s1, 8(sp)             # save callee-saved register
        addi  s1, a0, 0             # s1 = counter
CD_LOOP:
        sw    s1, 0(s0)             # LEDs = current counter value
        beq   s1, zero, CD_DONE     # counter reached zero -> done
        jal   ra, DELAY             # wait 1 s (returns a0 = 1 if reset pressed)
        bne   a0, zero, CD_EXIT     # reset detected -> leave immediately (a0 = 1)
        addi  s1, s1, -1            # counter--
        jal   zero, CD_LOOP
CD_DONE:
        addi  a0, zero, 0           # return 0 : normal completion
CD_EXIT:
        lw    s1, 8(sp)             # restore s1
        lw    ra, 12(sp)            # restore return address
        addi  sp, sp, 16            # pop frame
        jalr  zero, 0(ra)           # return

# ---------------- DELAY subroutine (1 s @ 10 MHz) ----------------
# out : a0 = 0 (delay finished) / 1 (reset button seen)
DELAY:
        lui   t0, 0x262             # t0 = 0x262000
        addi  t0, t0, 0x5A0         # t0 = 0x2625A0 = 2,500,000 iterations
DLY_LOOP:
        lw    t1, 8(s0)             # poll reset button every iteration
        bne   t1, zero, DLY_RST
        addi  t0, t0, -1
        bne   t0, zero, DLY_LOOP
        addi  a0, zero, 0
        jalr  zero, 0(ra)
DLY_RST:
        addi  a0, zero, 1
        jalr  zero, 0(ra)
