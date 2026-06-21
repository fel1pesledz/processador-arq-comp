# µProcessador — VHDL

Implementação de um processador de 16 bits em VHDL ("Calculadora Programável"), com máquina de estados de 2 fases (FETCH / EXECUTE), banco de 10 registradores de uso geral, ULA com 6 operações, RAM de dados e ROM de programa de 128 posições. Leitura da ROM é assíncrona; PC e IR são sensíveis a `falling_edge`.

Como prova de conceito, a ROM traz embutido um programa que executa o **Crivo de Eratóstenes** (até 32) e em seguida usa os primos encontrados para testar a primalidade de 923 por divisão sucessiva.

## Estrutura dos arquivos

| Arquivo | Descrição |
|---|---|
| `processador.vhd` | Top-level — conecta todos os componentes, decodifica o IR e gera os sinais de controle |
| `ula.vhd` | Unidade Lógica e Aritmética (ADD, SUB, SUBB, AND, OR, MOV) |
| `rom.vhd` | Memória de programa (128 × 17 bits), com o programa do crivo/primalidade embutido |
| `ram.vhd` | Memória de dados (128 × 16 bits), leitura/escrita síncrona |
| `pc.vhd` | Registrador do Program Counter (7 bits), sensível a `falling_edge`, com `wr_en` |
| `banco_regs.vhd` | Banco de registradores (R0–R9, 16 bits cada), 2 portas de leitura simultâneas |
| `reg16bits.vhd` | Registrador genérico de 16 bits com reset síncrono |
| `processador_tb.vhd` | Testbench — gera clock (período 100 ns), reset e roda a simulação por 1200 µs |
| `codificacao.txt` | Especificação completa da ISA: formato de instrução, opcodes, decodificação de campos e mapeamento para a ULA |
| `assembly_crivo_final.txt` | Listagem comentada do programa (assembly, binário de 17 bits e hex) endereço por endereço |
| `teste.txt` | Sequência de comandos para compilar e simular no GHDL/GTKWave |

## Conjunto de instruções (ISA)

Palavras de **17 bits** — `opcode(4) | ddd(4) | sss(4) | ttt(4) | x(1)`, MSB = bit 16.

```
 bit 16 | bit 15 | bit 14 | bit 13 | bit 12..9 | bit 8..5 | bit 4..1 | bit 0
 -------+--------+--------+--------+-----------+----------+----------+------
    op3 |   op2  |   op1  |   op0  |    ddd    |   sss    |   ttt    |  x
```

- `ddd` = registrador destino / fonte 1
- `sss` = registrador fonte 2
- Para `ADDC`: bits `[8:1]` = imediato de 8 bits (0–255), sem sinal
- Para `BLE`/`BPL`: bits `[6:0]` = offset relativo, complemento de 2 (−64..+63)
- Para `JMP`: bits `[6:0]` = endereço absoluto (0–127)
- bit 0 sempre irrelevante (`x`)

| Opcode | Mnemônico | Operação | Flags | Escreve reg |
|---|---|---|---|---|
| `0000` | NOP | sem operação | não | não |
| `0001` | ADD Rd, Rs | Rd ← Rd + Rs | sim | sim |
| `0010` | SUB Rd, Rs | Rd ← Rd − Rs (sem borrow) | sim | sim |
| `0011` | SUBB Rd, Rs | Rd ← Rd − Rs − C (com borrow) | sim | sim |
| `0100` | MOV Rd, Rs | Rd ← Rs | não | sim |
| `0101` | ADDC Rd, imm8 | Rd ← Rd + imm8 | não | sim |
| `0110` | CMPR Rs1, Rs2 | flags ← Rs1 − Rs2 (sem escrita) | sim | não |
| `0111` | CLR Rd | Rd ← 0 (internamente Rd − Rd) | sim | sim |
| `1000` | LW Rd, Rend | Rd ← RAM[Rend] | não | sim |
| `1001` | SW Rsrc, Rend | RAM[Rend] ← Rsrc | não | não |
| `1010` | INC Rd | Rd ← Rd + 1 | não | sim |
| `1101` | BPL offset7 | se N=0: PC ← PC + offset | não | não |
| `1110` | BLE offset7 | se Z=1 ou N≠V: PC ← PC + offset | não | não |
| `1111` | JMP addr7 | PC ← addr7 (incondicional) | não | não |

> Todos os bits em zero (`0x00000`) é `NOP`. ADD, SUB, SUBB e CMPR operam só entre registradores — nunca com constantes. Para carregar um valor: `CLR Rd` seguido de `ADDC Rd, imm8`; valores acima de 255 encadeiam vários `ADDC` (ex.: 923 = três `ADDC R7,255` + um `ADDC R7,158`).

### Decodificação no top-level

```
opcode       <= reg_ir(16 downto 13)
reg_dest     <= reg_ir(12 downto  9)
reg_fonte1   <= reg_ir(12 downto  9)
reg_fonte2   <= reg_ir( 8 downto  5)
offset_salto <= reg_ir( 6 downto  0)
imediato     <= "00000000" & reg_ir(8 downto 1)
```

Mapeamento para a ULA:
```
ula_entrada_a <= dado_lido_r2   quando MOV
              <= dado_lido_r1   demais casos
ula_entrada_b <= imediato       quando ADDC
              <= x"0001"        quando INC
              <= dado_lido_r1   quando CLR   (A - A)
              <= dado_lido_r2   demais casos
```

### ULA (3 bits de seleção)

| selec_op | Operação |
|---|---|
| `000` | ADD (A + B) |
| `001` | SUB (A − B) |
| `010` | SUBB (A − B − borrow_in) |
| `011` | AND |
| `100` | OR |
| `101` | MOV (passa A) |

Flags combinacionais (`flag_zero`, `flag_neg`, `flag_carry`, `flag_overf`) registradas no `falling_edge` ao final do EXECUTE, só quando a instrução habilita `we_flags` (ADD, SUB, SUBB, CMPR, CLR). `borrow_in` do SUBB vem do `flag_c_reg` do ciclo anterior.

### Memória

- **ROM**: 128 × 17 bits, leitura assíncrona, endereçada por `pc_atual`.
- **RAM**: 128 × 16 bits, escrita síncrona; endereço vem de `dado_lido_r2(6 downto 0)`; `SW` escreve `dado_lido_r1`, `LW` carrega no registrador `ddd`.

### Máquina de estados (2 fases, falling_edge)

```
estado = 0  ->  FETCH:    reg_ir <= instrucao_rom
estado = 1  ->  EXECUTE:  ULA opera, flags/PC atualizados,
                           banco de registradores e RAM escritos se habilitado
```

### Saídas do processador (top-level)

`out_estado`, `out_pc` (7 bits), `out_ir` (17 bits), `out_ula` (16 bits), `out_r0`…`out_r9` (16 bits cada) e `bit_debug` — `'1'` se R9 ≠ 0, `'0'` se R9 = 0.

## Programa de teste (ROM)

A ROM embutida implementa um **Crivo de Eratóstenes parcial** (primos até 32) seguido de um **teste de primalidade de 923** usando os primos encontrados, com divisão por subtração repetida.

| Bloco | Endereços | Descrição |
|---|---|---|
| 1 — Inicialização | 0–8 | `RAM[1..32] <= índice`, via `INIT_LOOP` controlado com `INC R1` |
| 2a — Elimina múltiplos de 2 | 9–16 | `RAM[i] <= 0` para i = 4, 6, 8, … 32 |
| 2b — Elimina múltiplos de 3 | 17–24 | `RAM[i] <= 0` para i = 6, 9, 12, … 30 |
| 2c — Elimina múltiplos de 5 | 25–32 | `RAM[i] <= 0` para i = 10, 15, 20, … 30 |
| 3 — Leitura da tabela | 33–38 | Percorre `RAM[2..32]` em `READ_LOOP`, expondo cada primo em R6 |
| 4 — Teste de 923 | 39–65 | Carrega R7=923 (via 4× `ADDC`); para cada primo da tabela, divide 923 por subtração sucessiva; se achar resto 0, R9←0 (composto) e salta para `HALT` |
| HALT | 65 | `JMP 65` (loop infinito) |

Registradores usados pelo programa:

| Reg | Papel |
|---|---|
| R1 | endereço / contador geral |
| R2 | passo dos loops de eliminação |
| R3 | limite do crivo (32, constante) |
| R4 | zero (constante) |
| R5 | ponteiro de leitura da tabela |
| R6 | valor lido da RAM (primo candidato a divisor) |
| R7 | 923 — número a testar (constante) |
| R8 | resto da divisão por subtração |
| R9 | resultado: 1 = primo, 0 = composto → `bit_debug` |

**Resultado esperado:** 923 = 13 × 71 → **composto** → R9 = 0 → `bit_debug = '0'`.

A listagem completa (assembly, binário de 17 bits e hex, endereço por endereço) está em [`assembly_crivo_final.txt`](./assembly_crivo_final.txt); a especificação da ISA está em [`codificacao.txt`](./codificacao.txt).

---

## Como simular

### Pré-requisitos

**Fedora (dnf):**
```bash
sudo dnf install ghdl gtkwave
```

**Debian/Ubuntu (apt):**
```bash
sudo apt update
sudo apt install ghdl gtkwave
```

### Passo a passo

```bash
# 1. Compilar todos os arquivos (ordem importa)
ghdl -a reg16bits.vhd pc.vhd banco_regs.vhd ula.vhd ram.vhd rom.vhd processador.vhd processador_tb.vhd

# 2. Elaborar o testbench
ghdl -e processador_tb

# 3. Simular e gerar arquivo de ondas
ghdl -r processador_tb --wave=simulacao.ghw

# 4. Visualizar no GTKWave
gtkwave simulacao.ghw
```

> **Dica:** no GTKWave, adicione os sinais `clk`, `rst`, `out_estado`, `out_pc`, `out_ir`, `out_ula`, `out_r1`…`out_r9` e `bit_debug` para acompanhar a execução do crivo e o resultado final do teste de primalidade.
