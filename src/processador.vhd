library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processador is
    port(
        clk        : in  std_logic;
        rst        : in  std_logic;
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

    component ram is
        port(
            clk      : in  std_logic;
            endereco : in  unsigned(6 downto 0);
            wr_en    : in  std_logic;
            dado_in  : in  unsigned(15 downto 0);
            dado_out : out unsigned(15 downto 0)
        );
    end component;

    -- controle
    signal estado            : std_logic;
    signal reg_ir            : unsigned(16 downto 0);
    signal instrucao_rom     : unsigned(16 downto 0);
    signal prox_ir           : unsigned(16 downto 0);
    signal pc_atual          : unsigned(6 downto 0);
    signal prox_pc           : unsigned(6 downto 0);
    signal pc_wr_en          : std_logic;
    signal eh_jump           : std_logic;
    signal eh_branch         : std_logic;
    signal condicao_atendida : std_logic;

    -- decodificacao do IR: [16:13]=opcode [12:9]=dest/f1 [8:5]=f2 [8:1]=imm [6:0]=offset
    signal opcode       : unsigned(3 downto 0);
    signal reg_dest     : unsigned(3 downto 0);
    signal reg_fonte1   : unsigned(3 downto 0);
    signal reg_fonte2   : unsigned(3 downto 0);
    signal imediato     : unsigned(15 downto 0);
    signal offset_salto : unsigned(6 downto 0);

    -- flags
    signal flag_zero  : std_logic;
    signal flag_neg   : std_logic;
    signal flag_overf : std_logic;
    signal flag_carry : std_logic;
    signal flag_z_reg : std_logic;
    signal flag_n_reg : std_logic;
    signal flag_c_reg : std_logic;
    signal flag_v_reg : std_logic;
    signal we_flags   : std_logic;

    -- datapath
    signal banco_wr_en         : std_logic;
    signal dado_lido_r1        : unsigned(15 downto 0);
    signal dado_lido_r2        : unsigned(15 downto 0);
    signal dado_escrever_banco : unsigned(15 downto 0);
    signal ula_entrada_a       : unsigned(15 downto 0);
    signal ula_entrada_b       : unsigned(15 downto 0);
    signal ula_op              : unsigned(2 downto 0);
    signal ula_resultado       : unsigned(15 downto 0);
    signal dado_lido_ram       : unsigned(15 downto 0);
    signal ram_wr_en           : std_logic;

begin

    -- ROM
    mem_rom : rom port map(
        endereco => pc_atual,
        dado     => instrucao_rom
    );

    -- PC
    eh_jump   <= '1' when opcode = "1111" else '0';
    eh_branch <= '1' when opcode = "1110" else '0';

    condicao_atendida <= flag_c_reg when opcode = "1110" else '0';

    prox_pc <=
        offset_salto                                          when eh_jump = '1'                          else
        unsigned(signed(pc_atual) + signed(offset_salto))    when eh_branch = '1' and condicao_atendida = '1' else
        pc_atual + 1;

    pc_wr_en <= '1' when estado = '1' else '0';

    reg_pc_inst : pc port map(
        clk      => clk,
        rst      => rst,
        wr_en    => pc_wr_en,
        data_in  => prox_pc,
        data_out => pc_atual
    );

    -- MAQUINA DE ESTADOS + FLAGS
    process(clk, rst)
    begin
        if rst = '1' then
            estado    <= '1';
            flag_z_reg <= '0';
            flag_n_reg <= '0';
            flag_c_reg <= '0';
            flag_v_reg <= '0';
        elsif rising_edge(clk) then
            estado <= not estado;
            if we_flags = '1' then
                flag_z_reg <= flag_zero;
                flag_n_reg <= flag_neg;
                flag_c_reg <= flag_carry;
                flag_v_reg <= flag_overf;
            end if;
        end if;
    end process;

    -- REGISTRADOR DE INSTRUCAO (falling_edge)
    prox_ir <= instrucao_rom when estado = '0' else reg_ir;

    process(clk, rst)
    begin
        if rst = '1' then
            reg_ir <= (others => '0');
        elsif falling_edge(clk) then
            reg_ir <= prox_ir;
        end if;
    end process;

    -- DECODIFICACAO
    opcode       <= reg_ir(16 downto 13);
    reg_dest     <= reg_ir(12 downto  9);
    reg_fonte1   <= reg_ir(12 downto  9);
    reg_fonte2   <= reg_ir( 8 downto  5);
    offset_salto <= reg_ir( 6 downto  0);
    imediato     <= "00000000" & reg_ir(8 downto 1);

    banco_wr_en <= '1' when (estado = '1' and (
        opcode = "0001" or  -- ADD
        opcode = "0010" or  -- SUB
        opcode = "0011" or  -- SUBB
        opcode = "0100" or  -- MOV
        opcode = "0101" or  -- LI
        opcode = "1000"     -- LW
    )) else '0';

    we_flags <= '1' when (estado = '1' and (
        opcode = "0001" or  -- ADD
        opcode = "0010" or  -- SUB
        opcode = "0011" or  -- SUBB
        opcode = "0110"     -- CMPR
    )) else '0';

    ram_wr_en <= '1' when (estado = '1' and opcode = "1001") else '0';  -- SW

    -- RAM
    ram_inst : ram port map(
        clk      => clk,
        endereco => dado_lido_r2(6 downto 0),
        wr_en    => ram_wr_en,
        dado_in  => dado_lido_r1,
        dado_out => dado_lido_ram
    );

    -- DATAPATH
    dado_escrever_banco <= dado_lido_ram when opcode = "1000" else ula_resultado;

    ula_entrada_a <= dado_lido_r2 when opcode = "0100" else dado_lido_r1;
    ula_entrada_b <= imediato     when opcode = "0101" else dado_lido_r2;

    ula_op <=
        "001" when opcode = "0010" else  -- SUB
        "010" when opcode = "0011" else  -- SUBB
        "101" when opcode = "0100" else  -- MOV (passa A; entrada_A ja foi trocada para Rs)
        "001" when opcode = "0110" else  -- CMPR
        "000";                           -- ADD, LI

    -- BANCO DE REGISTRADORES
    banco : banco_regs port map(
        clk     => clk,
        rst     => rst,
        wr_en   => banco_wr_en,
        reg_r1  => reg_fonte1,
        reg_r2  => reg_fonte2,
        reg_wr  => reg_dest,
        data_wr => dado_escrever_banco,
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

    -- ULA
    alu : ula port map(
        entrada_A  => ula_entrada_a,
        entrada_B  => ula_entrada_b,
        selec_op   => ula_op,
        borrow_in  => flag_c_reg,
        resultado  => ula_resultado,
        flag_zero  => flag_zero,
        flag_neg   => flag_neg,
        flag_overf => flag_overf,
        flag_carry => flag_carry
    );

    -- SAIDAS
    out_estado <= estado;
    out_pc     <= pc_atual;
    out_ir     <= reg_ir;
    out_ula    <= ula_resultado;

end architecture;