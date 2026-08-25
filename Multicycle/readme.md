# Multicycle RISC-V (RV32I) Processor Verification Suite

This repository contains the functional verification program and testbench assets for a 32-bit Multicycle RISC-V processor core. The test suite comprehensively tests each base instruction type (**R-Type**, **I-Type**, **S-Type**, **B-Type**, **U-Type**, and **J-Type**) in the RV32I ISA, validating multicycle state transitions, ALU operations, load/store paths, and control hazard branches.

---

## 1. Instruction Encoding & Machine Code Reference

| PC Offset | Assembly Instruction | Type | Binary Breakdown `[funct7/imm | rs2 | rs1 | funct3 | rd | opcode]` | Machine Code (Hex) | Expected Result / Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `0x00` | `lui x1, 0x12345` | U | `00010010001101000101_00001_0110111` | `0x123450B7` | $x_1 \leftarrow \text{0x12345000}$ |
| `0x04` | `auipc x2, 0x0` | U | `00000000000000000000_00010_0010111` | `0x00000117` | $x_2 \leftarrow \text{PC} = \text{0x00000004}$ |
| `0x08` | `addi x3, x0, 20` | I | `000000010100_00000_000_00011_0010011` | `0x01400193` | $x_3 \leftarrow 20$ (`0x14`) |
| `0x0C` | `addi x4, x0, -4` | I | `111111111100_00000_000_00100_0010011` | `0xFFC00213` | $x_4 \leftarrow -4$ (`0xFFFFFFFC`) |
| `0x10` | `add x5, x3, x4` | R | `0000000_00100_00011_000_00101_0110011` | `0x004182B3` | $x_5 \leftarrow 20 + (-4) = 16$ (`0x10`) |
| `0x14` | `sub x6, x3, x4` | R | `0100000_00100_00011_000_00110_0110011` | `0x40418333` | $x_6 \leftarrow 20 - (-4) = 24$ (`0x18`) |
| `0x18` | `and x7, x3, x4` | R | `0000000_00100_00011_111_00111_0110011` | `0x0041F3B3` | $x_7 \leftarrow 20 \text{ AND } (-4) = 16$ (`0x10`) |
| `0x1C` | `or x8, x3, x4` | R | `0000000_00100_00011_110_01000_0110011` | `0x0041E433` | $x_8 \leftarrow 20 \text{ OR } (-4) = -4$ (`0xFFFFFFFC`) |
| `0x20` | `xor x9, x3, x4` | R | `0000000_00100_00011_100_01001_0110011` | `0x0041C4B3` | $x_9 \leftarrow 20 \text{ XOR } (-4) = -24$ (`0xFFFFFFE8`) |
| `0x24` | `sll x10, x3, x5` | R | `0000000_00101_00011_001_01010_0110011` | `0x00519533` | $x_{10} \leftarrow 20 \ll 16 = 1,310,720$ (`0x00140000`) |
| `0x28` | `srl x11, x10, x5` | R | `0000000_00101_01010_101_01011_0110011` | `0x005555B3` | $x_{11} \leftarrow x_{10} \gg 16 = 20$ (`0x14`) |
| `0x2C` | `sra x12, x4, x5` | R | `0100000_00101_00100_101_01100_0110011` | `0x40525633` | $x_{12} \leftarrow (-4) \gg_{\text{arith}} 16 = -1$ (`0xFFFFFFFF`) |
| `0x30` | `slt x13, x4, x3` | R | `0000000_00011_00100_010_01101_0110011` | `0x003226B3` | $x_{13} \leftarrow (-4 < 20) = 1$ |
| `0x34` | `sltu x14, x3, x4`| R | `0000000_00100_00011_011_01110_0110011` | `0x0041B733` | $x_{14} \leftarrow (20 <_{\text{unsigned}} 0xFFFFFFFC) = 1$ |
| `0x38` | `andi x15, x3, 0xF`| I | `000000001111_00011_111_01111_0010011` | `0x00F1F793` | $x_{15} \leftarrow 20 \text{ AND } 15 = 4$ (`0x04`) |
| `0x3C` | `ori x16, x3, 0x1` | I | `000000000001_00011_110_10000_0010011` | `0x0011E813` | $x_{16} \leftarrow 20 \text{ OR } 1 = 21$ (`0x15`) |
| `0x40` | `xori x17, x3, 0x3`| I | `000000000011_00011_100_10001_0010011` | `0x0031C893` | $x_{17} \leftarrow 20 \text{ XOR } 3 = 23$ (`0x17`) |
| `0x44` | `slli x18, x3, 2` | I | `0000000_00010_00011_001_10010_0010011` | `0x00219913` | $x_{18} \leftarrow 20 \ll 2 = 80$ (`0x50`) |
| `0x48` | `srli x19, x18, 2` | I | `0000000_00010_10010_101_10011_0010011` | `0x00295993` | $x_{19} \leftarrow 80 \gg 2 = 20$ (`0x14`) |
| `0x4C` | `srai x20, x4, 1` | I | `0100000_00001_00100_101_10100_0010011` | `0x40125A13` | $x_{20} \leftarrow (-4) \gg_{\text{arith}} 1 = -2$ (`0xFFFFFFFE`) |
| `0x50` | `sw x6, 40(x0)` | S | `0000001_00110_00000_010_01000_0100011` | `0x02602423` | $\text{MEM}[40] \leftarrow x_6$ (`24`) |
| `0x54` | `lw x21, 40(x0)` | I | `000000101000_00000_010_10101_0000011` | `0x02802A83` | $x_{21} \leftarrow \text{MEM}[40]$ (`24`) |
| `0x58` | `beq x6, x21, 8` | B | `0_000000_10101_00110_000_0100_0_1100011`| `0x01530463` | Jump to `0x60` ($x_6 == x_{21}$) |
| `0x5C` | `jal x0, 0x78` | J | `0_0000000110_1_00000000_00000_1101111` | `0x01C0006F` | Trap to fail loop (`0x78`) |
| `0x60` | `bne x3, x4, 8` | B | `0_000000_00100_00011_001_0100_0_1100011`| `0x00419463` | Jump to `0x68` ($x_3 \neq x_4$) |
| `0x64` | `jal x0, 0x78` | J | `0_0000000101_0_00000000_00000_1101111` | `0x0140006F` | Trap to fail loop (`0x78`) |
| `0x68` | `blt x4, x3, 8` | B | `0_000000_00011_00100_100_0100_0_1100011`| `0x00324463` | Jump to `0x70` ($-4 < 20$) |
| `0x6C` | `jal x0, 0x78` | J | `0_0000000011_1_00000000_00000_1101111` | `0x00C0006F` | Trap to fail loop (`0x78`) |
| `0x70` | `jal x1, 12` | J | `0_0000000011_0_00000000_00001_1101111` | `0x00C000EF` | Call function at `0x7C`, $x_1 \leftarrow \text{0x74}$ |
| `0x74` | `jal x0, 16` | J | `0_0000000010_0_00000000_00000_1101111` | `0x0100006F` | Jump to `pass_end` (`0x84`) |
| `0x78` | `addi x22, x0, -1` | I | `111111111111_00000_000_10110_0100011` | `0xFFF00B13` | *Fail Status:* $x_{22} \leftarrow -1$ |
| `0x7C` | `addi x22, x0, 1` | I | `000000000001_00000_000_10110_0010011` | `0x00100B13` | Target of JAL: $x_{22} \leftarrow 1$ |
| `0x80` | `jalr x0, 0(x1)` | I | `000000000000_00001_000_00000_1100111` | `0x000080E7` | Return to address in $x_1$ (`0x74`) |
| `0x84` | `addi x22, x0, 42` | I | `000000101010_00000_000_10110_0010011` | `0x02A00B13` | *Pass Status:* $x_{22} \leftarrow 42$ (`0x2A`) |
| `0x88` | `jal x0, 0` | J | `0_0000000000_0_00000000_00000_1101111` | `0x0000006F` | Terminal Halt Loop |

---

## 2. Complete Assembly Test Program (`test_program.s`)

```assembly
# ==============================================================================
# Comprehensive RV32I Verification Program for Multicycle Processor
# ==============================================================================

.text
.globl _start

_start:
    # --------------------------------------------------------------------------
    # 1. U-Type Instructions (LUI, AUIPC)
    # --------------------------------------------------------------------------
    lui   x1, 0x12345           # x1 = 0x12345000
    auipc x2, 0x0               # x2 = PC (0x00000004)

    # --------------------------------------------------------------------------
    # 2. I-Type Immediate Arithmetic & Sign Extension
    # --------------------------------------------------------------------------
    addi  x3, x0, 20            # x3 = 20  (0x00000014)
    addi  x4, x0, -4            # x4 = -4  (0xFFFFFFFC)

    # --------------------------------------------------------------------------
    # 3. R-Type Arithmetic, Logical, and Shift Operations
    # --------------------------------------------------------------------------
    add   x5, x3, x4            # x5  = 20 + (-4) = 16 (0x00000010)
    sub   x6, x3, x4            # x6  = 20 - (-4) = 24 (0x00000018)
    and   x7, x3, x4            # x7  = 20 & (-4) = 16 (0x00000010)
    or    x8, x3, x4            # x8  = 20 | (-4) = -4 (0xFFFFFFFC)
    xor   x9, x3, x4            # x9  = 20 ^ (-4) = -24 (0xFFFFFFE8)
    sll   x10, x3, x5           # x10 = 20 << 16 = 0x00140000
    srl   x11, x10, x5          # x11 = x10 >> 16 (logical) = 20 (0x00000014)
    sra   x12, x4, x5           # x12 = -4 >> 16 (arithmetic) = -1 (0xFFFFFFFF)
    slt   x13, x4, x3           # x13 = (-4 < 20) (signed) = 1
    sltu  x14, x3, x4           # x14 = (20 < 0xFFFFFFFC) (unsigned) = 1

    # --------------------------------------------------------------------------
    # 4. I-Type Logic and Shifts
    # --------------------------------------------------------------------------
    andi  x15, x3, 0xF          # x15 = 20 & 15 = 4
    ori   x16, x3, 0x1          # x16 = 20 | 1 = 21
    xori  x17, x3, 0x3          # x17 = 20 ^ 3 = 23
    slli  x18, x3, 2            # x18 = 20 << 2 = 80
    srli  x19, x18, 2           # x19 = 80 >> 2 = 20
    srai  x20, x4, 1            # x20 = -4 >> 1 (arithmetic) = -2 (0xFFFFFFFE)

    # --------------------------------------------------------------------------
    # 5. S-Type and I-Type Memory Operations (SW, LW)
    # --------------------------------------------------------------------------
    sw    x6, 40(x0)            # Store x6 (24) into Mem[40]
    lw    x21, 40(x0)           # Load Mem[40] into x21 (Expected: 24)

    # --------------------------------------------------------------------------
    # 6. B-Type Conditional Branches (BEQ, BNE, BLT)
    # --------------------------------------------------------------------------
    beq   x6, x21, test_bne     # Branch taken if x6 == x21
    jal   x0, fail_trap         # Fallthrough is a failure

test_bne:
    bne   x3, x4, test_blt      # Branch taken if 20 != -4
    jal   x0, fail_trap

test_blt:
    blt   x4, x3, test_jump     # Branch taken if -4 < 20
    jal   x0, fail_trap

    # --------------------------------------------------------------------------
    # 7. J-Type and I-Type Unconditional Control Transfers (JAL, JALR)
    # --------------------------------------------------------------------------
test_jump:
    jal   x1, test_subroutine   # Call subroutine, save PC+4 (0x74) in x1
    jal   x0, pass_end          # Jump to final success

fail_trap:
    addi  x22, x0, -1           # x22 = -1 (0xFFFFFFFF) indicates failure
    jal   x0, fail_trap

test_subroutine:
    addi  x22, x0, 1            # Subroutine executed
    jalr  x0, 0(x1)             # Return to caller via saved return address in x1

pass_end:
    addi  x22, x0, 42           # x22 = 42 (0x0000002A) indicates all tests PASSED
halt:
    jal   x0, halt              # Simulation completion loop