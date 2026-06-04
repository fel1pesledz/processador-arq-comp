=============================================================
ESPECIFICAÇÃO DA CODIFICAÇÃO DE INSTRUÇÕES (ISA)
=============================================================
Tamanho da Instrução: 17 bits (Conforme Sorteio)
Formato Arquitetural: 2 Operandos (O Registrador Destino e a Fonte 1 compartilham o mesmo endereço físico de bits no decodificador).

1. FORMATO GERAL DA INSTRUÇÃO (17 bits)
-------------------------------------------------------------
| Bits 16..13 | Bits 12..9 | Bits 8..5  | Bits 4..1   | Bit 0 |
|-------------|------------|------------|-------------|-------|
| OPCODE      | REG 1      | REG 2      | IMEDIATO    | FIXO  |
-------------------------------------------------------------
* OPCODE (4 bits): Define a operação a ser executada.
* REG 1 (4 bits): Registrador Destino (Rn) e Primeira Fonte na ULA. Funciona também como ponteiro (endereço) ou fonte nas instruções de memória.
* REG 2 (4 bits): Registrador da Segunda Fonte (Rm).
* IMEDIATO (8 bits): Valor constante (ocupa das posições 8 a 1).
* OFFSET SALTO (7 bits): Constante usada em saltos (posições 6 a 0).
* Bit 0: Bit não significativo/padding fixo em '0'.

2. TABELA DE OPCODES E MNEMÔNICOS ATUALIZADA
-------------------------------------------------------------
| Mnemônico  | Opcode | Categoria | Reg1 (Dest/F1) | Reg2 (Fonte 2) | Imediato / Constante        | Descrição Funcional                                |
|------------|--------|-----------|----------------|----------------|-----------------------------|----------------------------------------------------|
| ADD Rn, Rm | 0001   | ULA       | Rn             | Rm             | 0000                        | Rn <- Rn + Rm                                      |
| SUB Rn, Rm | 0010   | ULA       | Rn             | Rm             | 0000                        | Rn <- Rn - Rm (Também usado para zerar registrador)|
| SUBB Rn,Rm | 0011   | ULA       | Rn             | Rm             | 0000                        | Rn <- Rn - Rm - Borrow                             |
| MOV Rn, Rm | 0100   | Transf.   | Rn             | Rm             | 0000                        | Rn <- Rm (Cópia de registradores)                  |
| LI Rn, imm | 0101   | Carga Cte | Rn             | <------ imm (8 bits) ------> | Rn <- Rn + imm (Requer zerar Rn antes com SUB)     |
| CMPR Rn, Rm| 0110   | Compar.   | Rn             | Rm             | 0000                        | ULA faz Rn - Rm (Sem Writeback, apenas atualiza flags)|
| LW Rn, Rptr| 1000   | Memória   | Rn (Destino)   | Rptr (Ponteiro)| 0000                        | Rn <- RAM[Rptr] (Leitura Assíncrona)               |
| SW Rsrc,Rptr| 1001  | Memória   | Rsrc (Dado)    | Rptr (Ponteiro)| 0000                        | RAM[Rptr] <- Rsrc (Escrita Síncrona)               |
| JC offset  | 1110   | Desvio    | <- ignora ->   | <- offset relativo (7 bits)->| Se Flag_C=1, PC <- PC + offset (Complemento de 2)  |
| JMP addr   | 1111   | Desvio    | <- ignora ->   | <- endereço absoluto (7 bits)->| Pulo incondicional, PC <- addr                     |