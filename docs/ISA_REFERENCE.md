# ISA Reference — 16-bit RISC Processor

## Instruction Encoding

All instructions are **16 bits wide**.

```
 15  14  13  12 | 11  10   9 |  8   7   6 |  5   4   3 |  2   1   0
  ──── opcode ──── │ ── rs1 ── │ ─── rs2 ── │ ─── rd ─── │ ── func ──
                   │           │            │            │
                   └── or destination/immediate fields depending on type
```

### R-Type  `[15:12]=opcode  [11:9]=rs1  [8:6]=rs2  [5:3]=rd  [2:0]=func`

| Instruction | func  | Operation              |
|-------------|-------|------------------------|
| AND         | `000` | `rd ← rs1 & rs2`       |
| ADD         | `001` | `rd ← rs1 + rs2`       |
| SUB         | `010` | `rd ← rs1 - rs2`       |
| SLL         | `011` | `rd ← rs1 << rs2`      |
| SRL         | `100` | `rd ← rs1 >> rs2`      |

### I-Type  `[15:12]=opcode  [11:9]=rs1  [8:6]=rd  [5:0]=imm6`

| Instruction | Opcode | Operation                   |
|-------------|--------|-----------------------------|
| ADDI        | `0011` | `rd ← rs1 + sign_ext(imm6)` |
| ANDI        | `0010` | `rd ← rs1 & zero_ext(imm6)` |

### Memory  `[15:12]=opcode  [11:9]=rs1  [8:6]=rd  [5:0]=imm6`

| Instruction | Opcode | Operation                        |
|-------------|--------|----------------------------------|
| LW          | `0100` | `rd ← Mem[rs1 + sign_ext(imm6)]` |
| SW          | `0101` | `Mem[rs1 + sign_ext(imm6)] ← rs2`|

### Branch  `[15:12]=opcode  [11:9]=rs1  [8:6]=rs2  [5:0]=imm6`

| Instruction | Opcode | Taken when          |
|-------------|--------|---------------------|
| BEQ         | `0110` | `rs1 == rs2`        |
| BNE         | `0111` | `rs1 != rs2`        |

Branch target = `PC + sign_ext(imm6)`

### Jump / Call / Return  `[15:12]=0001  [2:0]=func  [11:3]=target9`

| Instruction | func  | Operation                          |
|-------------|-------|------------------------------------|
| JMP         | `000` | `PC ← {PC[15:9], target9}`         |
| CALL        | `001` | `RR ← PC+1; PC ← {PC[15:9], target9}` |
| RET         | `010` | `PC ← RR`                          |

### FOR Loop  `[15:12]=1000  [11:9]=counter_reg  [8:3]=loop_body_offset`

Hardware-assisted counted loop. Decrements counter register; branches back while counter ≠ 0.

---

## Register File

| Register | Alias | Notes                        |
|----------|-------|------------------------------|
| R0       | zero  | Hardwired to 0 (read-only)   |
| R1–R7    | —     | General purpose, 16-bit each |

---

## Memory Map

| Region | Address Range | Size  |
|--------|---------------|-------|
| Instruction Memory | `0x0000 – 0xFFFF` | 64K × 16-bit words |
| Data Memory        | `0x0000 – 0xFFFF` | 64K × 16-bit words |

*(Harvard architecture — instruction and data address spaces are separate.)*

---

## Example Program (`sim/program.dat`)

```
4200   ; ADDI R1, R0, #2    → R1 = 2
4400   ; ADDI R2, R0, #4    → R2 = 4
0613   ; ADD  R3, R1, R2    → R3 = 6  (forwarding: EX→EX)
0814   ; ADD  R4, R3, R1    → R4 = 8  (forwarding: MEM→EX)
```
