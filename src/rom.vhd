library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 

entity rom is
    port(
        endereco : in  unsigned(6 downto 0);
        dado     : out unsigned(16 downto 0)
    );
end entity;

architecture a_rom of rom is
    type mem is array (0 to 127) of unsigned(16 downto 0);
    constant conteudo_rom : mem := (

        -- 1: Inicializa RAM[1..32] com indices
        0  => B"0111_0011_0011_0000_0",  -- CLR R3
        1  => B"0101_0011_0010_0000_0",  -- ADDC R3, 32       ; R3=32 (limite, fixo)
        2  => B"0111_0100_0100_0000_0",  -- CLR R4            ; R4=0  (zero, fixo)
        3  => B"0111_0001_0001_0000_0",  -- CLR R1
        4  => B"1010_0001_0000_0000_0",  -- INC R1            ; R1=1 (primeiro endereco)
        -- INIT_LOOP:
        5  => B"1001_0001_0001_0000_0",  -- SW R1, R1         ; RAM[R1]=R1
        6  => B"1010_0001_0000_0000_0",  -- INC R1            ; R1++ (INC contador loop)
        7  => B"0110_0001_0011_0000_0",  -- CMPR R1, R3       ; R1-32
        8  => B"1110_0000_0011_1110_1",  -- BLE INIT_LOOP     ; offset=-3 -> addr 5

        -- 2a: Elimina multiplos de 2
        9  => B"0111_0001_0001_0000_0",  -- CLR R1
        10 => B"0101_0001_0000_0100_0",  -- ADDC R1, 4        ; R1=4 (2x2)
        11 => B"0111_0010_0010_0000_0",  -- CLR R2
        12 => B"0101_0010_0000_0010_0",  -- ADDC R2, 2        ; R2=2 (passo)
        -- ELIM_2_LOOP:
        13 => B"1001_0100_0001_0000_0",  -- SW R4, R1         ; RAM[R1]=0
        14 => B"0001_0001_0010_0000_0",  -- ADD R1, R2        ; R1+=2
        15 => B"0110_0001_0011_0000_0",  -- CMPR R1, R3       ; R1-32
        16 => B"1110_0000_0011_1110_1",  -- BLE ELIM_2_LOOP   ; offset=-3 -> addr 13

        -- 2b: Elimina multiplos de 3
        17 => B"0111_0001_0001_0000_0",  -- CLR R1
        18 => B"0101_0001_0000_0110_0",  -- ADDC R1, 6        ; R1=6 (2x3)
        19 => B"0111_0010_0010_0000_0",  -- CLR R2
        20 => B"0101_0010_0000_0011_0",  -- ADDC R2, 3        ; R2=3 (passo)
        -- ELIM_3_LOOP:
        21 => B"1001_0100_0001_0000_0",  -- SW R4, R1         ; RAM[R1]=0
        22 => B"0001_0001_0010_0000_0",  -- ADD R1, R2        ; R1+=3
        23 => B"0110_0001_0011_0000_0",  -- CMPR R1, R3       ; R1-32
        24 => B"1110_0000_0011_1110_1",  -- BLE ELIM_3_LOOP   ; offset=-3 -> addr 21

        -- 2c: Elimina multiplos de 5
        25 => B"0111_0001_0001_0000_0",  -- CLR R1
        26 => B"0101_0001_0000_1010_0",  -- ADDC R1, 10       ; R1=10 (2x5)
        27 => B"0111_0010_0010_0000_0",  -- CLR R2
        28 => B"0101_0010_0000_0101_0",  -- ADDC R2, 5        ; R2=5 (passo)
        -- ELIM_5_LOOP:
        29 => B"1001_0100_0001_0000_0",  -- SW R4, R1         ; RAM[R1]=0
        30 => B"0001_0001_0010_0000_0",  -- ADD R1, R2        ; R1+=5
        31 => B"0110_0001_0011_0000_0",  -- CMPR R1, R3       ; R1-32
        32 => B"1110_0000_0011_1110_1",  -- BLE ELIM_5_LOOP   ; offset=-3 -> addr 29

        -- 3: Exibe primos em R6
        33 => B"0111_0101_0101_0000_0",  -- CLR R5
        34 => B"0101_0101_0000_0010_0",  -- ADDC R5, 2        ; R5=2
        -- READ_LOOP:
        35 => B"1000_0110_0101_0000_0",  -- LW R6, R5         ; R6=RAM[R5]
        36 => B"1010_0101_0000_0000_0",  -- INC R5            ; R5++ (INC contador loop)
        37 => B"0110_0101_0011_0000_0",  -- CMPR R5, R3       ; R5-32
        38 => B"1110_0000_0011_1110_1",  -- BLE READ_LOOP     ; offset=-3 -> addr 35

        -- 4: Teste de primalidade de 923 usando a tabela
        --   Percorre RAM[2..32]: se RAM[i]!=0 (primo), divide 923 por ele
        --   Se resto=0: achou divisor -> R9=0 (composto)
        39 => B"0111_0111_0111_0000_0",  -- CLR R7
        40 => B"0101_0111_1111_1111_0",  -- ADDC R7, 255      ; R7=255
        41 => B"0101_0111_1111_1111_0",  -- ADDC R7, 255      ; R7=510
        42 => B"0101_0111_1111_1111_0",  -- ADDC R7, 255      ; R7=765
        43 => B"0101_0111_1001_1110_0",  -- ADDC R7, 158      ; R7=923 (N)
        44 => B"0111_1001_1001_0000_0",  -- CLR R9
        45 => B"0101_1001_0000_0001_0",  -- ADDC R9, 1        ; R9=1 (assume primo)
        46 => B"0111_0101_0101_0000_0",  -- CLR R5
        47 => B"0101_0101_0000_0010_0",  -- ADDC R5, 2        ; R5=2 (inicio tabela)

        -- PRIME_LOOP:
        48 => B"1000_0110_0101_0000_0",  -- LW R6, R5         ; R6=RAM[R5] (primo candidato)
        49 => B"0110_0110_0100_0000_0",  -- CMPR R6, R4       ; R6-0 (e primo?)
        50 => B"1110_0000_0000_0100_1",  -- BLE SKIP_DIV      ; offset=+9->59 (R6=0: nao e primo, pula divisao)
        51 => B"0100_1000_0111_0000_0",  -- MOV R8, R7        ; R8=REM=923

        -- DIV_LOOP:
        52 => B"0110_1000_0110_0000_0",  -- CMPR R8, R6       ; REM-D
        53 => B"1101_0000_0000_0001_0",  -- BPL DO_SUB        ; offset=+2->55 (REM>=D)
        54 => B"1111_0000_0001_1100_1",  -- JMP DIV_END       ; abs=57 (REM<D: fim div)

        -- DO_SUB:
        55 => B"0010_1000_0110_0000_0",  -- SUB R8, R6        ; REM=REM-D
        56 => B"1111_0000_0001_1010_0",  -- JMP DIV_LOOP      ; abs=52

        -- DIV_END:
        57 => B"0110_1000_0100_0000_0",  -- CMPR R8, R4       ; REM-0
        58 => B"1110_0000_0000_0001_0",  -- BLE FOUND_DIV     ; offset=+2->60 (REM=0: divisivel)

        -- SKIP_DIV (R6=0 nao e primo, ou nao achou divisor):
        59 => B"1111_0000_0001_1111_0",  -- JMP NEXT_PRIME    ; abs=62

        -- FOUND_DIV:
        60 => B"0111_1001_1001_0000_0",  -- CLR R9            ; R9=0 (composto)
        61 => B"1111_0000_0010_0000_1",  -- JMP HALT          ; abs=65 (sai imediatamente!)

        -- NEXT_PRIME:
        62 => B"1010_0101_0000_0000_0",  -- INC R5            ; R5++ (INC contador loop)
        63 => B"0110_0101_0011_0000_0",  -- CMPR R5, R3       ; R5-32
        64 => B"1110_0000_0011_1000_0",  -- BLE PRIME_LOOP    ; offset=-16->48

        -- HALT:
        65 => B"1111_0000_0010_0000_1",  -- JMP HALT          ; trava PC=65

        others => (others => '0')
    );
begin
    dado <= conteudo_rom(to_integer(endereco));
end architecture;