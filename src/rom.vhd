library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- ROM VALIDACAO DO UPROCESSADOR - CRIVO DE ERATOSTENES
-- =============================================================
-- Gera os numeros primos de 2 a 32 na RAM (Crivo de Eratostenes)
-- e os exibe, um a um, na saida da ULA (out_ula) durante o loop
-- final de leitura. Posicoes nao-primas aparecem como 0 (zero).
--
-- Convencao de registradores (uso ao longo do programa):
--   R1 = endereco / contador de loop (uso geral, reaproveitado)
--   R2 = passo do loop / primo atual  (uso geral, reaproveitado)
--   R3 = constante 32  (limite superior, fixado uma unica vez)
--   R4 = constante 0   (usado para zerar celulas da RAM)
--   R5 = ponteiro de leitura final (2..32)
--   R6 = dado lido da RAM (exposto via MOV em out_ula)
-- =============================================================
-- End | Assembly             | Binario (17 bits)      | Hex (5 dig) | Descricao
-- ----|----------------------|------------------------|-------------|-----------------------------------------------
--   0 | CLR R3               | 0111 0011 0011 0000 0  |    0E660    | Zera R3 (R3 <- R3 - R3)
--   1 | ADDC R3, 32          | 0101 0011 00100000 0   |    0A640    | R3 = R3 + 32 -> R3 fixo = 32 (limite, nunca mais alterado)
--   2 | CLR R4               | 0111 0100 0100 0000 0  |    0E880    | Zera R4 -> R4 fixo = 0 (constante zero, nunca mais alterado)
--     |                      |                        |             |
--   3 | CLR R1               | 0111 0001 0001 0000 0  |    0E220    | Zera R1 (contador de endereco)
--   4 | ADDC R1, 1           | 0101 0001 00000001 0   |    0A202    | R1 = R1 + 1 -> R1 = 1 (endereco inicial)
--   5 | SW R1, R1            | 1001 0001 0001 0000 0  |    12220    | RAM[R1] = R1   (grava o proprio endereco como valor)
--   6 | ADDC R1, 1           | 0101 0001 00000001 0   |    0A202    | R1 = R1 + 1 -> avanca para o proximo endereco
--   7 | CMPR R1, R3          | 0110 0001 0011 0000 0  |    0C260    | flags <= R1 - R3 (compara R1 com 32)
--   8 | BLE INIT_LOOP        | 1110 000000 1111101    |    1C07D    | Se R1 <= 32 (Z=1 ou N<>V), volta para INIT_LOOP (addr 5)
--     |                      |                        |             |
--   9 | CLR R1               | 0111 0001 0001 0000 0  |    0E220    | Zera R1
--  10 | ADDC R1, 4           | 0101 0001 00000100 0   |    0A208    | R1 = R1 + 4 -> R1 = 4 (2*2, primeiro multiplo de 2 a eliminar)
--  11 | CLR R2               | 0111 0010 0010 0000 0  |    0E440    | Zera R2
--  12 | ADDC R2, 2           | 0101 0010 00000010 0   |    0A404    | R2 = R2 + 2 -> R2 = 2 (passo = primo 2)
--  13 | SW R4, R1            | 1001 0100 0001 0000 0  |    12820    | RAM[R1] = R4 (=0)  -> elimina multiplo de 2
--  14 | ADD R1, R2           | 0001 0001 0010 0000 0  |    02240    | R1 = R1 + R2 -> proximo multiplo de 2
--  15 | CMPR R1, R3          | 0110 0001 0011 0000 0  |    0C260    | flags <= R1 - R3 (compara com 32)
--  16 | BLE ELIM_2_LOOP      | 1110 000000 1111101    |    1C07D    | Se R1 <= 32, volta para ELIM_2_LOOP (addr 13)
--     |                      |                        |             |
--  17 | CLR R1               | 0111 0001 0001 0000 0  |    0E220    | Zera R1
--  18 | ADDC R1, 6           | 0101 0001 00000110 0   |    0A20C    | R1 = R1 + 6 -> R1 = 6 (2*3, primeiro multiplo de 3 a eliminar)
--  19 | CLR R2               | 0111 0010 0010 0000 0  |    0E440    | Zera R2
--  20 | ADDC R2, 3           | 0101 0010 00000011 0   |    0A406    | R2 = R2 + 3 -> R2 = 3 (passo = primo 3)
--  21 | SW R4, R1            | 1001 0100 0001 0000 0  |    12820    | RAM[R1] = R4 (=0)  -> elimina multiplo de 3
--  22 | ADD R1, R2           | 0001 0001 0010 0000 0  |    02240    | R1 = R1 + R2 -> proximo multiplo de 3
--  23 | CMPR R1, R3          | 0110 0001 0011 0000 0  |    0C260    | flags <= R1 - R3 (compara com 32)
--  24 | BLE ELIM_3_LOOP      | 1110 000000 1111101    |    1C07D    | Se R1 <= 32, volta para ELIM_3_LOOP (addr 21)
--     |                      |                        |             |
--  25 | CLR R1               | 0111 0001 0001 0000 0  |    0E220    | Zera R1
--  26 | ADDC R1, 10          | 0101 0001 00001010 0   |    0A214    | R1 = R1 + 10 -> R1 = 10 (2*5, primeiro multiplo de 5 a eliminar)
--  27 | CLR R2               | 0111 0010 0010 0000 0  |    0E440    | Zera R2
--  28 | ADDC R2, 5           | 0101 0010 00000101 0   |    0A40A    | R2 = R2 + 5 -> R2 = 5 (passo = primo 5)
--  29 | SW R4, R1            | 1001 0100 0001 0000 0  |    12820    | RAM[R1] = R4 (=0)  -> elimina multiplo de 5
--  30 | ADD R1, R2           | 0001 0001 0010 0000 0  |    02240    | R1 = R1 + R2 -> proximo multiplo de 5
--  31 | CMPR R1, R3          | 0110 0001 0011 0000 0  |    0C260    | flags <= R1 - R3 (compara com 32)
--  32 | BLE ELIM_5_LOOP      | 1110 000000 1111101    |    1C07D    | Se R1 <= 32, volta para ELIM_5_LOOP (addr 29)
--     |                      |                        |             |
--  33 | CLR R5               | 0111 0101 0101 0000 0  |    0EAA0    | Zera R5
--  34 | ADDC R5, 2           | 0101 0101 00000010 0   |    0AA04    | R5 = R5 + 2 -> R5 = 2 (ponteiro de leitura inicial)
--  35 | LW R6, R5            | 1000 0110 0101 0000 0  |    10CA0    | R6 = RAM[R5]  (le a RAM no endereco apontado por R5)
--  36 | ADDC R5, 1           | 0101 0101 00000001 0   |    0AA02    | R5 = R5 + 1 -> avanca para o proximo endereco
--  37 | CMPR R5, R3          | 0110 0101 0011 0000 0  |    0CA60    | flags <= R5 - R3 (compara com 32)
--  38 | BLE READ_LOOP        | 1110 000000 1111101    |    1C07C    | Se R5 <= 32, volta para READ_LOOP (addr 59)
--     |                      |                        |             |
--  39 | JMP HALT             | 1111 000000 1000000    |    1E040    | Loop infinito (fim do programa, PC trava em 64)
-- =============================================================

entity rom is
    port(
        endereco : in  unsigned(6 downto 0);
        dado     : out unsigned(16 downto 0)
    );
end entity;

architecture a_rom of rom is
    type mem is array (0 to 127) of unsigned(16 downto 0);
    constant conteudo_rom : mem := (
        0  => B"0111_0011_0011_0000_0",
        1  => B"0101_0011_00100000_0",
        2  => B"0111_0100_0100_0000_0",
        
        3  => B"0111_0001_0001_0000_0",
        4  => B"0101_0001_00000001_0",
        5  => B"1001_0001_0001_0000_0",
        6  => B"0101_0001_00000001_0",
        7  => B"0110_0001_0011_0000_0",
        8  => B"1110_000000_1111101",
        
        9  => B"0111_0001_0001_0000_0",
        10 => B"0101_0001_00000100_0",
        11 => B"0111_0010_0010_0000_0",
        12 => B"0101_0010_00000010_0",
        13 => B"1001_0100_0001_0000_0",
        14 => B"0001_0001_0010_0000_0",
        15 => B"0110_0001_0011_0000_0",
        16 => B"1110_000000_1111101",
        
        17 => B"0111_0001_0001_0000_0",
        18 => B"0101_0001_00000110_0",
        19 => B"0111_0010_0010_0000_0",
        20 => B"0101_0010_00000011_0",
        21 => B"1001_0100_0001_0000_0",
        22 => B"0001_0001_0010_0000_0",
        23 => B"0110_0001_0011_0000_0",
        24 => B"1110_000000_1111101",
        
        25 => B"0111_0001_0001_0000_0",
        26 => B"0101_0001_00001010_0",
        27 => B"0111_0010_0010_0000_0",
        28 => B"0101_0010_00000101_0",
        29 => B"1001_0100_0001_0000_0",
        30 => B"0001_0001_0010_0000_0",
        31 => B"0110_0001_0011_0000_0",
        32 => B"1110_000000_1111101",
        
        33 => B"0111_0101_0101_0000_0",
        34 => B"0101_0101_00000010_0",
        35 => B"1000_0110_0101_0000_0",
        36 => B"0101_0101_00000001_0",
        37 => B"0110_0101_0011_0000_0",
        38 => B"1110_000000_1111101",
        
        39 => B"1111_000000_0100111",
        others => (others => '0')
    );
begin
    dado <= conteudo_rom(to_integer(endereco));
end architecture;