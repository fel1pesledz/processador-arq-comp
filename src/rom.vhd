library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rom is
    port(
        endereco : in unsigned(6 downto 0);  -- 7 bits = 128 posições
        dado     : out unsigned(16 downto 0) -- Sorteio: 17 bits
    );
end entity;

architecture a_rom of rom is
    type mem is array (0 to 127) of unsigned(16 downto 0);
    
    -- Opcode "1111" será o nosso JUMP ABSOLUTO
    -- Opcode "0000" será NOP (ou outra instrução futura)
    constant conteudo_rom : mem := (
        -- Endereço => "Opcode(4 bits)" & "Resto da instrução(13 bits, com endereço no final)"
        0 => "0000" & "0000000000000", -- NOP
        1 => "0000" & "0000000000000", -- NOP
        2 => "0000" & "0000000000000", -- NOP
        3 => "1111" & "0000000000001", -- JMP para o endereço 1 (Loop!)
        others => (others => '0')
    );
begin
    -- LEITURA ASSÍNCRONA (Exigência do sorteio)
    -- Sem process, sem clock. A alteração do endereço muda o dado instantaneamente.
    dado <= conteudo_rom(to_integer(endereco));
end architecture;