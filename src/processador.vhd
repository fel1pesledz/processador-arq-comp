library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- PROCESSADOR - Top-Level do uProcessador 5
--
-- Maquina de 2 estados: 0=FETCH, 1=EXECUTE
-- IR    : falling_edge, clock-enable via MUX externo
-- PC    : falling_edge, clock-enable via MUX externo
-- Banco : rising_edge (dentro do reg16bits)
--
-- REGRA: process/if SOMENTE para registrador simples (rst + clk).
--        Toda logica combinacional fora do process, com when-else.
-- =============================================================

entity processador is
    port(
        clk : in std_logic;
        rst : in std_logic;

        out_estado : out std_logic;
        out_pc     : out unsigned(6 downto 0);
        out_ir     : out unsigned(16 downto 0);
        out_ula    : out unsigned(15 downto 0);
        out_r0     : out unsigned(15 downto 0);
        out_r1     : out unsigned(15 downto 0);
        out_r2     : out unsigned(15 downto 0);
        out_r3     : out unsigned(15 downto 0);
        out_r4     : out unsigned(15 downto 0);
        out_r5     : out unsigned(15 downto 0);
        out_r6     : out unsigned(15 downto 0);
        out_r7     : out unsigned(15 downto 0);
        out_r8     : out unsigned(15 downto 0);
        out_r9     : out unsigned(15 downto 0)
    );
end entity;

architecture a_processador of processador is

    -- ---------------------------------------------------------
    -- Declaracao dos componentes
    -- ---------------------------------------------------------

    component rom is
        port(
            endereco : in  unsigned(6 downto 0);
            dado     : out unsigned(16 downto 0)
        );
    end component;

    component pc is
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            wr_en    : in  std_logic;
            data_in  : in  unsigned(6 downto 0);
            data_out : out unsigned(6 downto 0)
        );
    end component;

    component banco_regs is
        port(
            clk     : in  std_logic;
            rst     : in  std_logic;
            wr_en   : in  std_logic;
            reg_r1  : in  unsigned(3 downto 0);
            reg_r2  : in  unsigned(3 downto 0);
            reg_wr  : in  unsigned(3 downto 0);
            data_wr : in  unsigned(15 downto 0);
            data_r1 : out unsigned(15 downto 0);
            data_r2 : out unsigned(15 downto 0);
            out_r0  : out unsigned(15 downto 0);
            out_r1  : out unsigned(15 downto 0);
            out_r2  : out unsigned(15 downto 0);
            out_r3  : out unsigned(15 downto 0);
            out_r4  : out unsigned(15 downto 0);
            out_r5  : out unsigned(15 downto 0);
            out_r6  : out unsigned(15 downto 0);
            out_r7  : out unsigned(15 downto 0);
            out_r8  : out unsigned(15 downto 0);
            out_r9  : out unsigned(15 downto 0)
        );
    end component;

    component ula is
        port(
            entrada_A  : in  unsigned(15 downto 0);
            entrada_B  : in  unsigned(15 downto 0);
            selec_op   : in  unsigned(2 downto 0);
            borrow_in  : in  std_logic;
            resultado  : out unsigned(15 downto 0);
            flag_zero  : out std_logic;
            flag_neg   : out std_logic;
            flag_overf : out std_logic;
            flag_carry : out std_logic
        );
    end component;

    -- =========================================================
    -- REGISTRADORES (usados dentro de process)
    -- =========================================================
    signal estado  : std_logic;
    signal reg_ir  : unsigned(16 downto 0);
    signal borrow  : std_logic;

    -- =========================================================
    -- SINAIS COMBINACIONAIS (usados fora de process)
    -- =========================================================

    -- ROM
    signal instrucao_rom   : unsigned(16 downto 0);

    -- IR (MUX de entrada)
    signal prox_ir         : unsigned(16 downto 0);

    -- PC (componente pc)
    signal pc_atual        : unsigned(6 downto 0);
    signal prox_pc         : unsigned(6 downto 0);
    signal pc_wr_en        : std_logic;

    -- Campos decodificados do IR
    signal opcode          : unsigned(3 downto 0);
    signal reg_dest        : unsigned(3 downto 0);  -- ddd: registrador destino
    signal reg_fonte1      : unsigned(3 downto 0);  -- sss: registrador fonte 1
    signal reg_fonte2      : unsigned(3 downto 0);  -- ttt: registrador fonte 2
    signal imediato        : unsigned(15 downto 0); -- imm4 estendido para 16 bits
    signal endereco_salto  : unsigned(6 downto 0);  -- addr7 para JMP

    -- Banco de registradores
    signal banco_wr_en     : std_logic;
    signal dado_lido_r1    : unsigned(15 downto 0);
    signal dado_lido_r2    : unsigned(15 downto 0);

    -- ULA
    signal ula_entrada_a   : unsigned(15 downto 0);
    signal ula_entrada_b   : unsigned(15 downto 0);
    signal ula_op          : unsigned(2 downto 0);
    signal ula_resultado   : unsigned(15 downto 0);
    signal flag_zero       : std_logic;
    signal flag_neg        : std_logic;
    signal flag_overf      : std_logic;
    signal flag_carry      : std_logic;

    -- Borrow (MUX de entrada)
    signal prox_borrow     : std_logic;

    -- Desvio
    signal eh_jump         : std_logic;

begin

    -- =========================================================
    -- ROM
    -- =========================================================
    mem_rom : rom port map(
        endereco => pc_atual,
        dado     => instrucao_rom
    );

    -- =========================================================
    -- PROGRAM COUNTER (componente pc - falling_edge)
    -- MUX externo: seleciona PC+1 ou endereco de salto.
    -- Escrita habilitada apenas durante EXECUTE (estado=1).
    -- =========================================================
    eh_jump   <= '1' when opcode = "1111" else '0';

    prox_pc   <= endereco_salto when eh_jump = '1' else
                 pc_atual + 1;

    pc_wr_en  <= '1' when estado = '1' else '0';

    reg_pc_inst : pc port map(
        clk      => clk,
        rst      => rst,
        wr_en    => pc_wr_en,
        data_in  => prox_pc,
        data_out => pc_atual
    );

    -- =========================================================
    -- REGISTRADOR DE ESTADO (flip-flop T)
    -- =========================================================
    process(clk, rst)
    begin
        if rst = '1' then
            estado <= '1';
        elsif rising_edge(clk) then
            estado <= not estado;
        end if;
    end process;

    -- =========================================================
    -- REGISTRADOR DE INSTRUCOES (IR) - falling_edge
    -- MUX externo: carrega da ROM no FETCH, mantem no EXECUTE.
    -- =========================================================
    prox_ir <= instrucao_rom when estado = '0' else reg_ir;

    process(clk, rst)
    begin
        if rst = '1' then
            reg_ir <= (others => '0');
        elsif falling_edge(clk) then
            reg_ir <= prox_ir;
        end if;
    end process;

    -- =========================================================
    -- REGISTRADOR DE BORROW - rising_edge
    -- MUX externo: atualiza apenas apos SUB ou SUBB no EXECUTE.
    -- =========================================================
    prox_borrow <=
        flag_carry when (estado = '1' and
                         (opcode = "0010" or opcode = "0011"))
        else borrow;

    process(clk, rst)
    begin
        if rst = '1' then
            borrow <= '0';
        elsif rising_edge(clk) then
            borrow <= prox_borrow;
        end if;
    end process;

    -- =========================================================
    -- DECODIFICADOR (combinacional, fora de process)
    -- =========================================================
    opcode         <= reg_ir(16 downto 13);
    reg_dest       <= reg_ir(12 downto  9);
    reg_fonte1     <= reg_ir( 8 downto  5);
    reg_fonte2     <= reg_ir( 4 downto  1);
    endereco_salto <= reg_ir( 6 downto  0);
    imediato       <= "000000000000" & reg_ir(4 downto 1);

    -- Write enable do banco: so durante EXECUTE de instrucoes que escrevem
    banco_wr_en <=
        '1' when (estado = '1' and
                  (opcode = "0001" or   -- ADD
                   opcode = "0010" or   -- SUB
                   opcode = "0011" or   -- SUBB
                   opcode = "0100" or   -- MOV
                   opcode = "0101"))    -- LI
        else '0';

    -- Entrada A da ULA
    ula_entrada_a <=
        x"0000"       when opcode = "0101" else   -- LI:   A = 0
        dado_lido_r1;                              -- demais: A = Rs

    -- Entrada B da ULA
    ula_entrada_b <=
        imediato      when opcode = "0101" else   -- LI:   B = imediato
        x"0000"       when opcode = "0100" else   -- MOV:  B = 0
        dado_lido_r2;                              -- demais: B = Rt

    -- Selecao de operacao da ULA
    ula_op <=
        "001" when opcode = "0010" else   -- SUB
        "010" when opcode = "0011" else   -- SUBB
        "101" when opcode = "0100" else   -- MOV  (passa A)
        "001" when opcode = "0110" else   -- CMPR (SUB sem escrita)
        "000";                             -- ADD, LI, NOP, JMP

    -- =========================================================
    -- BANCO DE REGISTRADORES
    -- =========================================================
    banco : banco_regs port map(
        clk     => clk,
        rst     => rst,
        wr_en   => banco_wr_en,
        reg_r1  => reg_fonte1,
        reg_r2  => reg_fonte2,
        reg_wr  => reg_dest,
        data_wr => ula_resultado,
        data_r1 => dado_lido_r1,
        data_r2 => dado_lido_r2,
        out_r0  => out_r0,
        out_r1  => out_r1,
        out_r2  => out_r2,
        out_r3  => out_r3,
        out_r4  => out_r4,
        out_r5  => out_r5,
        out_r6  => out_r6,
        out_r7  => out_r7,
        out_r8  => out_r8,
        out_r9  => out_r9
    );

    -- =========================================================
    -- ULA
    -- =========================================================
    alu : ula port map(
        entrada_A  => ula_entrada_a,
        entrada_B  => ula_entrada_b,
        selec_op   => ula_op,
        borrow_in  => borrow,
        resultado  => ula_resultado,
        flag_zero  => flag_zero,
        flag_neg   => flag_neg,
        flag_overf => flag_overf,
        flag_carry => flag_carry
    );

    -- =========================================================
    -- SAIDAS
    -- =========================================================
    out_estado <= estado;
    out_pc     <= pc_atual;
    out_ir     <= reg_ir;
    out_ula    <= ula_resultado;

end architecture;
