library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- ROM - 128 posicoes x 17 bits (assincrona)
--
-- ASSEMBLY DO PROGRAMA TESTE:
--   Endereco | Instrucao Assembly    | Descricao
--   ---------|-----------------------|-----------------------------
--    0 (0x00)| LI   R3, 5           | R3 <= 5          (Passo A)
--    1 (0x01)| LI   R4, 8           | R4 <= 8          (Passo B)
--    2 (0x02)| ADD  R5, R3, R4      | R5 <= R3+R4      (Passo C) <label C>
--    3 (0x03)| LI   R6, 1           | R6 <= 1          (constante aux para Passo D)
--    4 (0x04)| SUB  R5, R5, R6      | R5 <= R5-1       (Passo D)
--    5 (0x05)| JMP  20              | PC <= 20         (Passo E)
--    6 (0x06)| LI   R5, 0           | R5 <= 0          (Passo F - NUNCA EXECUTADA)
--    7..19   | NOP                  | preenchimento
--   20 (0x14)| MOV  R3, R5          | R3 <= R5         (Passo G)
--   21 (0x15)| JMP  2               | PC <= 2          (Passo H - volta label C)
--   22 (0x16)| LI   R3, 0           | R3 <= 0          (Passo I - NUNCA EXECUTADA)
--
-- VERIFICACAO: R5 assume sequencialmente 12, 19, 26, 33, 40, 47, ...
--
-- CODIFICACAO (17 bits, bit16=MSB):
--   bit 16..13 = opcode (4 bits)
--   bit 12.. 9 = ddd    registrador destino
--   bit  8.. 5 = sss    registrador fonte 1
--   bit  4.. 1 = ttt    registrador fonte 2 OU imm4
--   bit      0 = x      irrelevante
--
-- OPCODES:
--   0000 = NOP
--   0001 = ADD   Rd <= Rs + Rt
--   0010 = SUB   Rd <= Rs - Rt   (sem borrow)
--   0011 = SUBB  Rd <= Rs - Rt - borrow
--   0100 = MOV   Rd <= Rs
--   0101 = LI    Rd <= imm4      (bits 4..1 = imediato 0..15)
--   0110 = CMPR  flags <= Rs-Rt  (sem escrita em registrador)
--   1111 = JMP   PC  <= addr7    (bits 6..0 = endereco absoluto)
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
        --  Addr | Assembly           | opcode_ddd_sss_ttt_x
        --  -----|--------------------|----------------------
        0  => B"01010011000001010",  -- LI R3,5
        1  => B"01010100000010000",  -- LI R4,8
        2  => B"00010101001101000",  -- ADD R5,R3,R4
        3  => B"01010110000000010",  -- LI R6,1
        4  => B"00100101010101100",  -- SUB R5,R5,R6
        5  => B"11110000000010100",  -- JMP 20
        6  => B"01010101000000000",  -- LI R5,0
        7  => (others => '0'),
        8  => (others => '0'),
        9  => (others => '0'),
        10 => (others => '0'),
        11 => (others => '0'),
        12 => (others => '0'),
        13 => (others => '0'),
        14 => (others => '0'),
        15 => (others => '0'),
        16 => (others => '0'),
        17 => (others => '0'),
        18 => (others => '0'),
        19 => (others => '0'),
        20 => B"01000011010100000",  -- MOV R3,R5
        21 => B"11110000000000010",  -- JMP 2
        22 => B"01010011000000000",  -- LI R3,0
        others => (others => '0')         -- NOP
    );
begin
    dado <= conteudo_rom(to_integer(endereco));
end architecture;
