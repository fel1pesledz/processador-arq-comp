library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- A entidade do testbench não possui entradas ou saídas
entity ula_tb is
end entity;

architecture a_ula_tb of ula_tb is
    -- 1. DECLARAÇÃO DO COMPONENTE
    -- A interface deve ser idêntica à definida no ula.vhd
    component ula is
        port(
            entrada_A : in unsigned(15 downto 0);
            entrada_B : in unsigned(15 downto 0);
            selec_op  : in unsigned(1 downto 0);
            
            resultado : out unsigned(15 downto 0);
            
            flag_zero    : out std_logic;
            flag_neg    : out std_logic;
            flag_overf    : out std_logic
        );
    end component;

    -- 2. SINAIS INTERNOS DO TESTBENCH
    -- Servem para conectar aos pinos do componente
    signal s_entrada_A : unsigned(15 downto 0) := (others => '0');
    signal s_entrada_B : unsigned(15 downto 0) := (others => '0');
    signal s_selec_op  : unsigned(1 downto 0)  := "00";
    
    signal s_resultado : unsigned(15 downto 0);
    signal s_flag_zero    : std_logic;
    signal s_flag_neg    : std_logic;
    signal s_flag_overf    : std_logic;

begin
    -- 3. INSTANCIAÇÃO DA UNIT UNDER TEST (UUT)
    uut: ula port map(
        entrada_A => s_entrada_A,
        entrada_B => s_entrada_B,
        selec_op  => s_selec_op,
        resultado => s_resultado,
        flag_zero    => s_flag_zero,
        flag_neg    => s_flag_neg,
        flag_overf    => s_flag_overf
    );

    -- 4. PROCESSO DE ESTÍMULOS DA SIMULAÇÃO
    process
    begin
        -- =========================================================
        -- TESTES DE SOMA (selec_op = "00")
        -- =========================================================
        s_selec_op <= "00";
        
        -- Soma Simples: 100 + 50 = 150
        s_entrada_A <= to_unsigned(100, 16);
        s_entrada_B <= to_unsigned(50, 16);
        wait for 50 ns;

        -- Soma testando Flag Zero (Z): 0 + 0 = 0
        s_entrada_A <= to_unsigned(0, 16);
        s_entrada_B <= to_unsigned(0, 16);
        wait for 50 ns;

        -- Soma testando Overflow (V) com positivos
        -- 32767 (x"7FFF") + 1 = 32768 (x"8000")
        -- Como x"8000" tem o MSB em 1, é visto como negativo em complemento de 2. Estoura a flag V.
        s_entrada_A <= x"7FFF"; 
        s_entrada_B <= x"0001";
        wait for 50 ns;

        -- =========================================================
        -- TESTES DE SUBTRAÇÃO (selec_op = "01")
        -- =========================================================
        s_selec_op <= "01";
        
        -- Subtração gerando negativo testando Flag Negativo (N): 10 - 20 = -10
        -- Resultado esperado é x"FFF6" (MSB = 1, ativando Flag N)
        s_entrada_A <= to_unsigned(10, 16);
        s_entrada_B <= to_unsigned(20, 16);
        wait for 50 ns;

        -- Subtração com entrada negativa (complemento de 2 com unsigned)
        -- 5 - (-3) = 8. O valor -3 em C2 de 16 bits é x"FFFD".
        s_entrada_A <= to_unsigned(5, 16);
        s_entrada_B <= x"FFFD"; 
        wait for 50 ns;

        -- Subtração testando Overflow (V) com negativos
        -- -32768 (x"8000") - 1 = Positivo (Estoura a representação)
        s_entrada_A <= x"8000"; 
        s_entrada_B <= x"0001";
        wait for 50 ns;

        -- =========================================================
        -- TESTES DE OPERAÇÕES LÓGICAS (selec_op = "10" e "11")
        -- =========================================================
        -- AND Lógico
        s_selec_op <= "10";
        s_entrada_A <= x"FF00";
        s_entrada_B <= x"0F0F"; -- Esperado: x"0F00"
        wait for 50 ns;

        -- OR Lógico
        s_selec_op <= "11";
        s_entrada_A <= x"AA00";
        s_entrada_B <= x"00BB"; -- Esperado: x"AABB"
        wait for 50 ns;

        -- Fim da simulação
        wait;
    end process;

end architecture;