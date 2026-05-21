# µProcessador — VHDL

Implementação de um processador simples de 16 bits em VHDL, com máquina de estados de 2 fases (FETCH / EXECUTE) e banco de 10 registradores de uso geral.

## Estrutura dos arquivos

| Arquivo | Descrição |
|---|---|
| `processador.vhd` | Top-level — conecta todos os componentes |
| `ula.vhd` | Unidade Lógica e Aritmética (ADD, SUB, SUBB, AND, OR, MOV) |
| `rom.vhd` | Memória de programa (128 × 17 bits) com programa de teste embutido |
| `banco_regs.vhd` | Banco de registradores (R0–R9, 16 bits cada) |
| `reg16bits.vhd` | Registrador genérico de 16 bits com reset síncrono |
| `processador_tb.vhd` | Testbench — gera clock, reset e roda a simulação por 12 µs |

## Conjunto de instruções (ISA)

Palavras de 17 bits — `opcode(4) | Rd(4) | Rs(4) | Rt/imm4(4) | x(1)`

| Opcode | Mnemônico | Operação |
|---|---|---|
| `0000` | NOP | Nenhuma operação |
| `0001` | ADD Rd, Rs, Rt | Rd ← Rs + Rt |
| `0010` | SUB Rd, Rs, Rt | Rd ← Rs − Rt |
| `0011` | SUBB Rd, Rs, Rt | Rd ← Rs − Rt − borrow |
| `0100` | MOV Rd, Rs | Rd ← Rs |
| `0101` | LI Rd, imm4 | Rd ← imm4 (0–15) |
| `0110` | CMPR Rs, Rt | flags ← Rs − Rt (sem escrita) |
| `1111` | JMP addr7 | PC ← addr7 |

## Programa de teste (ROM)

O programa embutido na ROM executa um loop infinito que acumula valores em **R5**:

```
LI   R3, 5          ; R3 = 5
LI   R4, 8          ; R4 = 8
ADD  R5, R3, R4     ; R5 = R3 + R4   <-- label C
LI   R6, 1
SUB  R5, R5, R6     ; R5 = R5 - 1
JMP  20
...
MOV  R3, R5         ; R3 = R5        (addr 20)
JMP  2              ; volta a C
```

A cada iteração R5 cresce: **12 → 19 → 26 → 33 → 40 → ...**

---

## Como simular

### Pré-requisitos

Instale o **GHDL** e o **GTKWave** de acordo com a sua distribuição Linux:

**Debian/Ubuntu e derivados (apt):**
```bash
sudo apt update
sudo apt install ghdl gtkwave
```

### Passo a passo

```bash
# 1. Compilar todos os arquivos (ordem importa)
ghdl -a reg16bits.vhd
ghdl -a banco_regs.vhd
ghdl -a ula.vhd
ghdl -a rom.vhd
ghdl -a processador.vhd
ghdl -a processador_tb.vhd

# 2. Elaborar o testbench
ghdl -e processador_tb

# 3. Simular e gerar arquivo de ondas
ghdl -r processador_tb --vcd=sim.vcd

# 4. Visualizar no GTKWave
gtkwave sim.vcd
```

> **Dica:** no GTKWave, adicione os sinais `clk`, `rst`, `out_r3`, `out_r4`, `out_r5`, `out_pc`, `out_ir`, `out_ula` e `out_estado` para acompanhar a execução do programa.
