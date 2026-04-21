library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula_tb is
end entity;

architecture a_ula_tb of ula_tb is

    -- DECLARACAO DO COMPONENTE: mesma interface do ula.vhd
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

    -- SINAIS INTERNOS DO TESTBENCH: pinagem do componente
    signal s_entrada_A : unsigned(15 downto 0) := (others => '0');
    signal s_entrada_B : unsigned(15 downto 0) := (others => '0');
    signal s_selec_op  : unsigned(1 downto 0)  := "00";
    
    signal s_resultado : unsigned(15 downto 0);
    signal s_flag_zero    : std_logic;
    signal s_flag_neg    : std_logic;
    signal s_flag_overf    : std_logic;

begin
    -- INSTANCIACAO DA UNIT UNDER TEST
    uut: ula port map(
        entrada_A => s_entrada_A,
        entrada_B => s_entrada_B,
        selec_op  => s_selec_op,
        resultado => s_resultado,
        flag_zero    => s_flag_zero,
        flag_neg    => s_flag_neg,
        flag_overf    => s_flag_overf
    );

    -- SIMULACAO
    process
    begin
        -- TESTES SOMA (selec_op = "00")
        s_selec_op <= "00";
        
        -- 100 + 50 = 150
        s_entrada_A <= to_unsigned(100, 16);
        s_entrada_B <= to_unsigned(50, 16);
        wait for 50 ns;

        -- 0 + 0 = 0 (flag zero)
        s_entrada_A <= to_unsigned(0, 16);
        s_entrada_B <= to_unsigned(0, 16);
        wait for 50 ns;

        -- soma com positivos estourando MSB para 1 (flag overf)
        s_entrada_A <= x"7FFF"; 
        s_entrada_B <= x"0001";
        wait for 50 ns;

        -- TESTES SUBTRACAO (selec_op = "01")
        s_selec_op <= "01";
        
        -- 10 - 20 = -10 (flag neg)
        s_entrada_A <= to_unsigned(10, 16);
        s_entrada_B <= to_unsigned(20, 16);
        wait for 50 ns;

        -- 5 - (-3) = 8
        s_entrada_A <= to_unsigned(5, 16);
        s_entrada_B <= x"FFFD"; 
        wait for 50 ns;

        -- subtracao com negativos estourando MSB para 0 (flag overf)
        s_entrada_A <= x"8000"; 
        s_entrada_B <= x"0001";
        wait for 50 ns;

        -- TESTES OPERACOES LOGICAS (selec_op = "10" e "11")

        -- AND
        s_selec_op <= "10";
        s_entrada_A <= x"FF00";
        s_entrada_B <= x"0F0F";
        wait for 50 ns;

        -- OR
        s_selec_op <= "11";
        s_entrada_A <= x"AA00";
        s_entrada_B <= x"00BB";

        wait;
    end process;

end architecture;