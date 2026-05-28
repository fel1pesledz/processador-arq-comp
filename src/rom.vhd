library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- ROM DO LAB 6 - CONDICIONAIS E DESVIOS
-- =============================================================
-- ASSEMBLY DO PROGRAMA TESTE (Somatório de 0 a 29):
-- End | Assembly         | Binario (17 bits)     | Descricao do PDF
-- ----|------------------|-----------------------|-----------------------------------
--  0  | LI   R3, 0       | 0101 0011 00000000 0  | A. Carrega R3 com 0
--  1  | LI   R4, 0       | 0101 0100 00000000 0  | B. Carrega R4 com 0
--  2  | LI   R6, 1       | 0101 0110 00000001 0  | (Constante Auxiliar: 1)
--  3  | LI   R7, 30      | 0101 0111 00011110 0  | (Constante Auxiliar: 30)
--     |                  |                       |
--     | --- LABEL C ---  |                       |
--  4  | ADD  R4, R4, R3  | 0001 0100 0100 0011 0 | C. Soma R3 com R4 e guarda em R4
--  5  | ADD  R3, R3, R6  | 0001 0011 0011 0110 0 | D. Soma 1 em R3
--  6  | CMPR R3, R7      | 0110 0000 0011 0111 0 | (Prepara flags: faz R3 - 30)
--  7  | JC  -3           | 1110 000000 1111101   | E. Se R3 < 30 salta p/ C (PC=7-3=4)
--     |                  |                       |
--     | --- LABEL F ---  |                       |
--  8  | MOV  R5, R4      | 0100 0101 0100 0000 0 | F. Copia valor de R4 para R5
--  9  | JMP  9           | 1111 000000 0001001   | (Loop infinito para finalizar)
--
-- NOTA: O salto JC (Jump if Carry) usa a flag de Carry como Borrow para 
--       verificar se ocorreu underflow na subtração (unsigned A < B).
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
        0  => B"01010011000000000", -- A. LI R3, 0
        1  => B"01010100000000000", -- B. LI R4, 0
        2  => B"01010110000000010", -- LI R6, 1
        3  => B"01010111000111100", -- LI R7, 30
        
        4  => B"00010100010000110", -- C. ADD R4, R4, R3
        5  => B"00010011001101100", -- D. ADD R3, R3, R6
        6  => B"01100000001101110", -- CMPR R3, R7
        7  => B"11100000001111101", -- E. JC -3 (Desvio condicional relativo)
        
        8  => B"01000101010000000", -- F. MOV R5, R4
        9  => B"11110000000001001", -- Fim do programa
        others => (others => '0')
    );
begin
    dado <= conteudo_rom(to_integer(endereco));
end architecture;