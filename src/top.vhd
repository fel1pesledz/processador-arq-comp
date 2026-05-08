library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port(
        clk          : in std_logic;
        rst          : in std_logic;
        
        -- Sinais de Controle
        wr_en        : in std_logic;            -- habilita escrita 
        reg_r1       : in unsigned(3 downto 0); -- leitura 1
        reg_r2       : in unsigned(3 downto 0); -- leitura 2
        reg_wr       : in unsigned(3 downto 0); -- selecao escrita
        selec_op     : in unsigned(1 downto 0); -- operação da ULA 
        sel_cte      : in std_logic;            -- MUX: '0' para Reg, '1' para Constante
        
        -- Dados externos
        cte_externa  : in unsigned(15 downto 0);
        
        -- Saídas de Status (Flags vindas da sua ULA)
        flag_zero    : out std_logic;
        flag_neg     : out std_logic;
        flag_overf   : out std_logic
    );
end entity;

architecture a_top of top is

    -- 1. DECLARACAO DOS COMPONENTES 
    component banco_regs is
        port(
            clock   : in std_logic;
            rst     : in std_logic;
            wr_en   : in std_logic;
            reg_r1  : in unsigned(3 downto 0);
            reg_r2  : in unsigned(3 downto 0);
            reg_wr  : in unsigned(3 downto 0);
            data_wr : in unsigned(15 downto 0);
            data_r1 : out unsigned(15 downto 0);
            data_r2 : out unsigned(15 downto 0)
        );
    end component;

    component ula is
        port(
            entrada_A : in unsigned(15 downto 0);
            entrada_B : in unsigned(15 downto 0);
            selec_op  : in unsigned(1 downto 0);
            resultado : out unsigned(15 downto 0);
            flag_zero : out std_logic;
            flag_neg  : out std_logic;
            flag_overf: out std_logic
        );
    end component;

    -- 2. SINAIS INTERNOS 
    signal fio_r1      : unsigned(15 downto 0);
    signal fio_r2      : unsigned(15 downto 0);
    signal fio_mux_alu : unsigned(15 downto 0);
    signal fio_res_alu : unsigned(15 downto 0);

begin

    -- 3. LÓGICA DO MULTIPLEXADOR 
    fio_mux_alu <= cte_externa when sel_cte = '1' else fio_r2;

    -- 4. INSTANCIAÇÃO E MAPEAMENTO 
    banco: banco_regs port map(
        clock   => clk,
        rst     => rst,
        wr_en   => wr_en,
        reg_r1  => reg_r1,
        reg_r2  => reg_r2,
        reg_wr  => reg_wr,
        data_wr => fio_res_alu, 
        data_r1 => fio_r1,
        data_r2 => fio_r2
    );

    
    alu: ula port map(
        entrada_A  => fio_r1,
        entrada_B  => fio_mux_alu, 
        selec_op   => selec_op,
        resultado  => fio_res_alu,
        flag_zero  => flag_zero,
        flag_neg   => flag_neg,
        flag_overf => flag_overf
    );

end architecture;