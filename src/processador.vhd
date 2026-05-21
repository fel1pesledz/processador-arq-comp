library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- =============================================================
-- PROCESSADOR - Top-Level do uProcessador 5
--
-- Maquina de 2 estados: 0=FETCH, 1=EXECUTE
-- IR  : falling_edge, clock-enable via MUX externo
-- PC  : falling_edge, clock-enable via MUX externo
-- Banco: rising_edge (dentro do reg16bits)
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

    component rom is
        port(
            endereco : in  unsigned(6 downto 0);
            dado     : out unsigned(16 downto 0)
        );
    end component;

    component banco_regs is
        port(
            clock   : in  std_logic;
            rst     : in  std_logic;
            wr_en   : in  std_logic;
            reg_r1  : in  unsigned(3 downto 0);
            reg_r2  : in  unsigned(3 downto 0);
            reg_wr  : in  unsigned(3 downto 0);
            data_wr : in  unsigned(15 downto 0);
            data_r1 : out unsigned(15 downto 0);
            data_r2 : out unsigned(15 downto 0)
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
    -- REGISTRADORES (so podem aparecer dentro de process)
    -- =========================================================
    signal estado  : std_logic;
    signal reg_pc  : unsigned(6 downto 0);
    signal reg_ir  : unsigned(16 downto 0);
    signal borrow  : std_logic;

    -- =========================================================
    -- FIOS COMBINACIONAIS (so podem aparecer fora de process)
    -- =========================================================
    signal fio_rom_dado    : unsigned(16 downto 0);

    -- Campos decodificados do IR
    signal fio_opcode      : unsigned(3 downto 0);
    signal fio_ddd         : unsigned(3 downto 0);
    signal fio_sss         : unsigned(3 downto 0);
    signal fio_ttt         : unsigned(3 downto 0);
    signal fio_imm16       : unsigned(15 downto 0);
    signal fio_jmp_addr    : unsigned(6 downto 0);

    -- MUX de entrada dos registradores (o que vai ser gravado)
    signal fio_ir_din      : unsigned(16 downto 0);  -- entrada do IR
    signal fio_pc_din      : unsigned(6 downto 0);   -- entrada do PC
    signal fio_borrow_din  : std_logic;              -- entrada do borrow

    -- Controle banco
    signal fio_wr_en       : std_logic;
    signal fio_data_r1     : unsigned(15 downto 0);
    signal fio_data_r2     : unsigned(15 downto 0);

    -- ULA
    signal fio_ula_a       : unsigned(15 downto 0);
    signal fio_ula_b       : unsigned(15 downto 0);
    signal fio_ula_op      : unsigned(2 downto 0);
    signal fio_ula_res     : unsigned(15 downto 0);
    signal fio_flag_zero   : std_logic;
    signal fio_flag_neg    : std_logic;
    signal fio_flag_overf  : std_logic;
    signal fio_flag_carry  : std_logic;

    -- PC
    signal fio_next_pc     : unsigned(6 downto 0);
    signal fio_is_jump     : std_logic;

    -- Observacao de registradores
    signal obs_r0, obs_r1, obs_r2, obs_r3, obs_r4 : unsigned(15 downto 0);
    signal obs_r5, obs_r6, obs_r7, obs_r8, obs_r9 : unsigned(15 downto 0);

begin

    -- =========================================================
    -- ROM
    -- =========================================================
    mem_rom : rom port map(
        endereco => reg_pc,
        dado     => fio_rom_dado
    );

    -- =========================================================
    -- REGISTRADOR DE ESTADO
    -- Process correto: apenas rst + clk, sem logica interna
    -- =========================================================
    process(clk, rst)
    begin
        if rst = '1' then
            estado <= '0';
        elsif rising_edge(clk) then
            estado <= not estado;
        end if;
    end process;

    -- =========================================================
    -- REGISTRADOR DE INSTRUCOES (IR) - falling_edge
    -- Process correto: apenas rst + clk, sem logica interna
    -- O MUX (clock-enable) fica FORA, no sinal fio_ir_din
    -- =========================================================

    -- MUX externo: durante FETCH (estado=0) carrega da ROM,
    -- senao mantem o valor atual
    fio_ir_din <= fio_rom_dado when estado = '0' else reg_ir;

    process(clk, rst)
    begin
        if rst = '1' then
            reg_ir <= (others => '0');
        elsif falling_edge(clk) then
            reg_ir <= fio_ir_din;
        end if;
    end process;

    -- =========================================================
    -- PROGRAM COUNTER (PC) - falling_edge
    -- Process correto: apenas rst + clk, sem logica interna
    -- O MUX (clock-enable) fica FORA, no sinal fio_pc_din
    -- =========================================================

    -- MUX externo: durante EXECUTE (estado=1) avanca o PC,
    -- senao mantem o valor atual
    fio_pc_din <= fio_next_pc when estado = '1' else reg_pc;

    process(clk, rst)
    begin
        if rst = '1' then
            reg_pc <= (others => '0');
        elsif falling_edge(clk) then
            reg_pc <= fio_pc_din;
        end if;
    end process;

    -- =========================================================
    -- REGISTRADOR DE BORROW - rising_edge
    -- Process correto: apenas rst + clk, sem logica interna
    -- O MUX fica FORA, no sinal fio_borrow_din
    -- =========================================================

    -- Atualiza borrow apenas durante EXECUTE de SUB ou SUBB,
    -- senao mantem o valor atual
    fio_borrow_din <=
        fio_flag_carry when (estado = '1' and
                             (fio_opcode = "0010" or fio_opcode = "0011"))
        else borrow;

    process(clk, rst)
    begin
        if rst = '1' then
            borrow <= '0';
        elsif rising_edge(clk) then
            borrow <= fio_borrow_din;
        end if;
    end process;

    -- =========================================================
    -- DECODIFICADOR (tudo combinacional, fora de process)
    -- =========================================================
    fio_opcode   <= reg_ir(16 downto 13);
    fio_ddd      <= reg_ir(12 downto  9);
    fio_sss      <= reg_ir( 8 downto  5);
    fio_ttt      <= reg_ir( 4 downto  1);
    fio_jmp_addr <= reg_ir( 6 downto  0);
    fio_imm16    <= "000000000000" & reg_ir(4 downto 1);

    -- Write enable: apenas durante EXECUTE de instrucoes que escrevem
    fio_wr_en <=
        '1' when (estado = '1' and
                  (fio_opcode = "0001" or   -- ADD
                   fio_opcode = "0010" or   -- SUB
                   fio_opcode = "0011" or   -- SUBB
                   fio_opcode = "0100" or   -- MOV
                   fio_opcode = "0101"))    -- LI
        else '0';

    -- Entrada A da ULA
    fio_ula_a <=
        x"0000"      when fio_opcode = "0101" else   -- LI: A = 0
        fio_data_r1;                                  -- demais: A = Rs

    -- Entrada B da ULA
    fio_ula_b <=
        fio_imm16    when fio_opcode = "0101" else   -- LI: B = imm
        x"0000"      when fio_opcode = "0100" else   -- MOV: B = 0
        fio_data_r2;                                  -- demais: B = Rt

    -- Operacao da ULA
    fio_ula_op <=
        "001" when fio_opcode = "0010" else   -- SUB
        "010" when fio_opcode = "0011" else   -- SUBB
        "101" when fio_opcode = "0100" else   -- MOV (passa A)
        "001" when fio_opcode = "0110" else   -- CMPR (SUB sem escrita)
        "000";                                 -- ADD, LI, NOP, JMP

    -- Proximo PC
    fio_is_jump <= '1' when fio_opcode = "1111" else '0';
    fio_next_pc <=
        fio_jmp_addr when fio_is_jump = '1' else
        reg_pc + 1;

    -- =========================================================
    -- BANCO DE REGISTRADORES PRINCIPAL
    -- =========================================================
    banco : banco_regs port map(
        clock   => clk,
        rst     => rst,
        wr_en   => fio_wr_en,
        reg_r1  => fio_sss,
        reg_r2  => fio_ttt,
        reg_wr  => fio_ddd,
        data_wr => fio_ula_res,
        data_r1 => fio_data_r1,
        data_r2 => fio_data_r2
    );

    -- =========================================================
    -- ULA
    -- =========================================================
    alu : ula port map(
        entrada_A  => fio_ula_a,
        entrada_B  => fio_ula_b,
        selec_op   => fio_ula_op,
        borrow_in  => borrow,
        resultado  => fio_ula_res,
        flag_zero  => fio_flag_zero,
        flag_neg   => fio_flag_neg,
        flag_overf => fio_flag_overf,
        flag_carry => fio_flag_carry
    );

    -- =========================================================
    -- BANCOS DE OBSERVACAO (para GTKWave - leitura de todos os regs)
    -- =========================================================
    obs_01 : banco_regs port map(
        clock => clk, rst => rst, wr_en => fio_wr_en,
        reg_r1 => "0000", reg_r2 => "0001",
        reg_wr => fio_ddd, data_wr => fio_ula_res,
        data_r1 => obs_r0, data_r2 => obs_r1
    );
    obs_23 : banco_regs port map(
        clock => clk, rst => rst, wr_en => fio_wr_en,
        reg_r1 => "0010", reg_r2 => "0011",
        reg_wr => fio_ddd, data_wr => fio_ula_res,
        data_r1 => obs_r2, data_r2 => obs_r3
    );
    obs_45 : banco_regs port map(
        clock => clk, rst => rst, wr_en => fio_wr_en,
        reg_r1 => "0100", reg_r2 => "0101",
        reg_wr => fio_ddd, data_wr => fio_ula_res,
        data_r1 => obs_r4, data_r2 => obs_r5
    );
    obs_67 : banco_regs port map(
        clock => clk, rst => rst, wr_en => fio_wr_en,
        reg_r1 => "0110", reg_r2 => "0111",
        reg_wr => fio_ddd, data_wr => fio_ula_res,
        data_r1 => obs_r6, data_r2 => obs_r7
    );
    obs_89 : banco_regs port map(
        clock => clk, rst => rst, wr_en => fio_wr_en,
        reg_r1 => "1000", reg_r2 => "1001",
        reg_wr => fio_ddd, data_wr => fio_ula_res,
        data_r1 => obs_r8, data_r2 => obs_r9
    );

    -- =========================================================
    -- SAIDAS
    -- =========================================================
    out_estado <= estado;
    out_pc     <= reg_pc;
    out_ir     <= reg_ir;
    out_ula    <= fio_ula_res;
    out_r0 <= obs_r0;  out_r1 <= obs_r1;
    out_r2 <= obs_r2;  out_r3 <= obs_r3;
    out_r4 <= obs_r4;  out_r5 <= obs_r5;
    out_r6 <= obs_r6;  out_r7 <= obs_r7;
    out_r8 <= obs_r8;  out_r9 <= obs_r9;

end architecture;
