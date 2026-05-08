library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uc is
    port(
        clk : in std_logic;
        rst : in std_logic;
        
        -- Saídas para debug no testbench
        out_pc    : out unsigned(6 downto 0);
        out_instr : out unsigned(16 downto 0);
        out_state : out std_logic
    );
end entity;

architecture a_uc of uc is

    -- Componente da ROM
    component rom is
        port(
            endereco : in unsigned(6 downto 0);
            dado     : out unsigned(16 downto 0)
        );
    end component;

    -- Sinais internos (Registradores)
    signal reg_pc : unsigned(6 downto 0);
    signal reg_ir : unsigned(16 downto 0);
    signal estado : std_logic; -- '0' = Fetch, '1' = Execute

    -- Sinais de fio (Lógica Combinacional)
    signal fio_rom_dado  : unsigned(16 downto 0);
    signal fio_pc_mais_1 : unsigned(6 downto 0);
    signal fio_next_pc   : unsigned(6 downto 0);
    signal fio_opcode    : unsigned(3 downto 0);
    signal fio_jump_addr : unsigned(6 downto 0);
    signal fio_is_jump   : std_logic;

begin

    -- 1. INSTANCIAÇÃO DA ROM
    memoria_rom: rom port map(
        endereco => reg_pc,
        dado     => fio_rom_dado
    );

    -- 2. MÁQUINA DE ESTADOS (Flip-Flop T)
    -- Vamos deixar o estado atualizando na borda de SUBIDA, para que quando a 
    -- borda de descida chegar (onde PC e IR agem), o estado já esteja estável.
    process(clk, rst)
    begin
        if rst = '1' then
            estado <= '0';
        elsif rising_edge(clk) then
            estado <= not estado; -- Fica alternando 0, 1, 0, 1...
        end if;
    end process;


    -- 3. REGISTRADOR DE INSTRUÇÕES (IR)
    -- Sorteio: "sensível a clock de descida"
    process(clk, rst)
    begin
        if rst = '1' then
            reg_ir <= (others => '0');
        elsif falling_edge(clk) then
            if estado = '0' then 
                -- Estado 0 é FETCH: guarda a instrução vinda da ROM
                reg_ir <= fio_rom_dado;
            end if;
        end if;
    end process;


    -- 4. PROGRAM COUNTER (PC)
    -- Sorteio: "PC sensível a clock de descida"
    process(clk, rst)
    begin
        if rst = '1' then
            reg_pc <= (others => '0');
        elsif falling_edge(clk) then
            if estado = '1' then 
                -- Estado 1 é EXECUTE: atualiza o PC com a próxima instrução ou pulo
                reg_pc <= fio_next_pc;
            end if;
        end if;
    end process;


    -- 5. LÓGICA COMBINACIONAL DE SALTO (Sem IFs!)
    
    -- O Opcode são os 4 bits mais significativos da nossa instrução de 17 bits (16, 15, 14, 13)
    fio_opcode <= reg_ir(16 downto 13);
    
    -- O endereço absoluto do JUMP são os 7 bits menos significativos (6 até 0)
    fio_jump_addr <= reg_ir(6 downto 0);
    
    -- Detecta se a instrução atual é um JUMP ABSOLUTO ("1111")
    fio_is_jump <= '1' when fio_opcode = "1111" else '0';
    
    -- Somador simples (+1)
    fio_pc_mais_1 <= reg_pc + 1;
    
    -- Multiplexador do próximo PC
    fio_next_pc <= fio_jump_addr when fio_is_jump = '1' else fio_pc_mais_1;


    -- Conexão para os pinos de saída (para podermos ver no GTKWave)
    out_pc    <= reg_pc;
    out_instr <= reg_ir;
    out_state <= estado;

end architecture;