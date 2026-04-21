library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
    port(
        entrada_A : in unsigned(15 downto 0);
        entrada_B : in unsigned(15 downto 0);
        selec_op  : in unsigned(1 downto 0);
        
        resultado : out unsigned(15 downto 0);
        
        -- Flags do sorteio (BLE e BPL)
        flag_zero    : out std_logic;
        flag_neg    : out std_logic;
        flag_overf    : out std_logic
    );
end entity;

architecture arq_ula of ula is
    -- Sinal interno para guardar o resultado temporariamente e para as flags
    signal res_interno : unsigned(15 downto 0);
begin
    
    -- MULTIPLEXADOR DE OPERAÇÕES
    res_interno <= (entrada_A + entrada_B)   when selec_op = "00" else
                   (entrada_A - entrada_B)   when selec_op = "01" else
                   (entrada_A and entrada_B) when selec_op = "10" else
                   (entrada_A or entrada_B)  when selec_op = "11" else
                   (others => '0'); -- Prevenção contra latches indesejados

    resultado <= res_interno;


    -- Flag Zero: '1' se todos os bits do resultado forem zero
    flag_zero <= '1' when res_interno = x"0000" else '0';
    
    -- Flag Negativo: copia do MSB
    flag_neg <= res_interno(15);
    
    -- Flag Overflow: estouro de limite para signed
    flag_overf <= 
        -- Soma: estoura se os sinais de A e B sao iguais e o sinal do resultado diferente
        ((entrada_A(15) and entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and not entrada_B(15) and res_interno(15))) when selec_op = "00" else
        
        -- Subtracao: estoura se os sinais de A e B sao diferentes e o sinal do resultado diferente do sinal A
        ((entrada_A(15) and not entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and entrada_B(15) and res_interno(15))) when selec_op = "01" else
        
        '0';

end architecture;