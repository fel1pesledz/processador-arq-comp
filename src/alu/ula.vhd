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
        flag_Z    : out std_logic;
        flag_N    : out std_logic;
        flag_V    : out std_logic
    );
end entity;

architecture arq_ula of ula is
    -- Sinal interno para guardar o resultado temporariamente
    -- Precisamos dele para poder calcular as flags depois
    signal res_interno : unsigned(15 downto 0);
begin
    
    -- 1. MULTIPLEXADOR DE OPERAÇÕES (Totalmente concorrente)
    res_interno <= (entrada_A + entrada_B)   when selec_op = "00" else
                   (entrada_A - entrada_B)   when selec_op = "01" else
                   (entrada_A and entrada_B) when selec_op = "10" else
                   (entrada_A or entrada_B)  when selec_op = "11" else
                   (others => '0'); -- Prevenção contra latches indesejados

    -- Conectando o sinal interno à porta de saída
    resultado <= res_interno;


    -- 2. LÓGICA DAS FLAGS (Totalmente concorrente)
    
    -- Flag Zero (Z): Fica em '1' se todos os bits do resultado forem zero
    flag_Z <= '1' when res_interno = x"0000" else '0';
    
    -- Flag Negativo (N): É simplesmente a cópia do Bit Mais Significativo (MSB)
    flag_N <= res_interno(15);
    
    -- Flag Overflow (V): Avalia o estouro de limite para números sinalizados.
    -- Só faz sentido avaliar overflow matemático em soma e subtração.
    flag_V <= 
        -- Regra da Soma: Estoura se os sinais de A e B são iguais, mas o resultado tem sinal diferente.
        ((entrada_A(15) and entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and not entrada_B(15) and res_interno(15))) when selec_op = "00" else
        
        -- Regra da Subtração (A - B): Estoura se os sinais de A e B são diferentes, 
        -- e o sinal do resultado fica diferente do sinal de A.
        ((entrada_A(15) and not entrada_B(15) and not res_interno(15)) or 
        (not entrada_A(15) and entrada_B(15) and res_interno(15))) when selec_op = "01" else
        
        -- Para operações lógicas (AND, OR), não existe overflow matemático.
        '0';

end architecture;