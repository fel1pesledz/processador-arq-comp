library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

---------------------------------------------------------------
-- CODIFICACAO BINARIA (17 bits)

-- Formato: opcode(4) ddd(4) sss(4) ttt/imm(4) x(1)

-- End. | Assembly         | Binario (17 bits)     | Hex (aprox.)
--------|------------------|-----------------------|-------------
--   0  | LI R3,5          | 0101 0011 0000 0101 0 | 0xA60A
--   1  | LI R4,8          | 0101 0100 0000 1000 0 | 0xA810
--   2  | ADD R5,R3,R4     | 0001 0101 0011 0100 0 | 0x2A68
--   3  | LI R6,1          | 0101 0110 0000 0001 0 | 0xAC02
--   4  | SUB R5,R5,R6     | 0010 0101 0101 0110 0 | 0x4AAC
--   5  | JMP 20           | 1111 0000 0000 1010 0 | 0xE014
--   6  | LI R5,0          | 0101 0101 0000 0000 0 | 0xAA00
-- 7-19 | NOP              | 0000 0000 0000 0000 0 | 0x0000
--  20  | MOV R3,R5        | 0100 0011 0101 0000 0 | 0x86A0
--  21  | JMP 2            | 1111 0000 0000 0001 0 | 0xE002
--  22  | LI R3,0          | 0101 0011 0000 0000 0 | 0xA600

---------------------------------------------------------------

entity rom is
    port(
        endereco : in  unsigned(6 downto 0);
        dado     : out unsigned(16 downto 0)
    );
end entity;

architecture a_rom of rom is
    type mem is array (0 to 127) of unsigned(16 downto 0);

    constant conteudo_rom : mem := (
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
        others => (others => '0')
    );
begin
    dado <= conteudo_rom(to_integer(endereco));
end architecture;
