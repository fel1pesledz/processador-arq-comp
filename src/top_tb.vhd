library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath_tb is
end entity;

architecture ateste_tb of datapath_tb is

    -- 1. DECLARAÇÃO DO COMPONENTE TOP LEVEL 
    component datapath is
        port(
            clk          : in std_logic;
            rst          : in std_logic;
            wr_en        : in std_logic;
            reg_r1       : in unsigned(3 downto 0);
            reg_r2       : in unsigned(3 downto 0);
            reg_wr       : in unsigned(3 downto 0);
            selec_op     : in unsigned(1 downto 0);
            sel_cte      : in std_logic;
            cte_externa  : in unsigned(15 downto 0);
            flag_zero    : out std_logic;
            flag_neg     : out std_logic;
            flag_overf   : out std_logic
        );
    end component;

    -- 2. CONFIGURAÇÕES DE TEMPO 
    constant period_time : time := 100 ns;
    signal finished      : std_logic := '0';
    
    -- 3. SINAIS PARA ESTIMULAR O CIRCUITO
    signal clk, rst      : std_logic := '0';
    signal wr_en         : std_logic := '0';
    signal reg_r1        : unsigned(3 downto 0) := "0000";
    signal reg_r2        : unsigned(3 downto 0) := "0000";
    signal reg_wr        : unsigned(3 downto 0) := "0000";
    signal selec_op      : unsigned(1 downto 0) := "00";
    signal sel_cte       : std_logic := '0';
    signal cte_externa   : unsigned(15 downto 0) := x"0000";
    
    -- Sinais para capturar as saídas
    signal flag_zero, flag_neg, flag_overf : std_logic;

begin

    -- 4. INSTANCIANDO O DATAPATH 
    uut: datapath port map(
        clk => clk, rst => rst, wr_en => wr_en,
        reg_r1 => reg_r1, reg_r2 => reg_r2, reg_wr => reg_wr,
        selec_op => selec_op, sel_cte => sel_cte, cte_externa => cte_externa,
        flag_zero => flag_zero, flag_neg => flag_neg, flag_overf => flag_overf
    );


    reset_global: process
    begin
        rst <= '1';
        wait for period_time * 2;
        rst <= '0';
        wait;
    end process;

    sim_time_proc: process
    begin
        wait for 2 us;
        finished <= '1';
        wait;
    end process sim_time_proc;

    clk_proc: process
    begin
        while finished /= '1' loop
            clk <= '0';
            wait for period_time / 2;
            clk <= '1';
            wait for period_time / 2;
        end loop;
        wait;
    end process clk_proc;

    estimulos: process
    begin
        wait for 200 ns; -- Espera o reset global terminar

        -- TESTE 1: CARGA DE CONSTANTE NO R5 
        -- Regra: "Soma a constante com um Rn zerado"
        -- O R0 está zerado (pelo reset). Vamos somar R0 + x"00AA" e salvar no R5.
        wr_en       <= '1';         -- Habilita escrita
        reg_r1      <= "0000";      -- Lê R0 (vale 0)
        reg_wr      <= "0101";      -- Escreve no R5
        sel_cte     <= '1';         -- MUX escolhe a constante externa
        cte_externa <= x"00AA";     -- Constante = AA
        selec_op    <= "00";        -- ULA em modo ADD
        wait for period_time;       -- Espera um ciclo de clock

        -- TESTE 2: CARGA DE CONSTANTE NO R6
        -- Vamos colocar o valor x"0005" no R6 usando a mesma lógica
        wr_en       <= '1';
        reg_r1      <= "0000";      -- Lê R0 (vale 0)
        reg_wr      <= "0110";      -- Escreve no R6
        sel_cte     <= '1';         -- MUX escolhe a constante
        cte_externa <= x"0005";     -- Constante = 5
        selec_op    <= "00";        -- ULA em modo ADD
        wait for period_time;

        -- TESTE 3: SOMA ENTRE REGISTRADORES (ADD R5, R6) -> Salva no R7
        -- ULA fará R5 (x00AA) + R6 (x0005) e vai salvar x00AF no R7
        wr_en       <= '1';         -- Habilita escrita
        reg_r1      <= "0101";      -- Lê R5
        reg_r2      <= "0110";      -- Lê R6
        reg_wr      <= "0111";      -- Escreve no R7
        sel_cte     <= '0';         -- MUX escolhe o Reg2 (Desliga constante)
        selec_op    <= "00";        -- ULA em modo ADD
        wait for period_time;

        -- TESTE 4: SUBTRAÇÃO (SUB R5, R6) -> Salva no R8
        -- ULA fará R5 (x00AA) - R6 (x0005) e vai salvar x00A5 no R8
        wr_en       <= '1';
        reg_r1      <= "0101";      -- Lê R5
        reg_r2      <= "0110";      -- Lê R6
        reg_wr      <= "1000";      -- Escreve no R8
        sel_cte     <= '0';         -- MUX escolhe o Reg2
        selec_op    <= "01";        -- ULA em modo SUB
        wait for period_time;

        -- TESTE 5: COMPARAÇÃO (CMPR R5, R5)
        -- A Unidade de Controle comanda a ULA para SUB, mas desliga o wr_en!
        -- O resultado não é salvo no banco, mas a flag_zero deve acender ('1') pois AA - AA = 0.
        wr_en       <= '0';         -- DESLIGA ESCRITA! [cite: 198]
        reg_r1      <= "0101";      -- Lê R5
        reg_r2      <= "0101";      -- Lê R5
        sel_cte     <= '0';         -- MUX escolhe o Reg2
        selec_op    <= "01";        -- ULA em modo SUB
        wait for period_time;

        -- Fim obrigatório da simulação [cite: 147-150]
        wait;
    end process;

end architecture;
