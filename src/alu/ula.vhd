library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
    port(
        entrada_A : in unsigned(15 downto 0);
        entrada_B : in unsigned(15 downto 0);
        selec_op  : in unsigned(1 downto 0);
        
        resultado : out unsigned(15 downto 0);
        
        -- Flags baseadas no sorteio (BLE e BPL)
        flag_zero    : out std_logic;
        flag_neg    : out std_logic;
        flag_overf    : out std_logic
    );
end entity;

architecture arq_ula of ula is
    -- Sinal interno para guardar o resultado temporariamente e para as flags
    signal res_interno : unsigned(15 downto 0);
begin
    
    -- 1. MULTIPLEXADOR DE OPERAÇÕES
    res_interno <= (entrada_A + entrada_B)   when selec_op = "00" else
                   (entrada_A - entrada_B)   when selec_op = "01" else
                   (entrada_A and entrada_B) when selec_op = "10" else
                   (entrada_A or entrada_B)  when selec_op = "11" else
                   (others => '0'); -- Prevenção contra latches indesejados

    resultado <= res_interno;


    -- Flag Zero: Fica em '1' se todos os bits do resultado forem zero
    flag_zero <= '1' when res_interno = x"0000" else '0';
    
    -- Flag Negativo: É simplesmente a cópia do Bit Mais Significativo (MSB)
    flag_neg <= res_interno(15);
    
    -- Flag Overflow: Avalia o estouro de limite para números sinalizados.
    flag_overf <= 
        -- Soma: Estoura se os sinais de A e B são iguais e o sinal do resultado diferente.
        ((entrada_A(15) and entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and not entrada_B(15) and res_interno(15))) when selec_op = "00" else
        
        -- Subtração: Estoura se os sinais de A e B são diferentes e o sinal do resultado fica diferente do sinal A.
        ((entrada_A(15) and not entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and entrada_B(15) and res_interno(15))) when selec_op = "01" else
        
        '0';

end architecture;