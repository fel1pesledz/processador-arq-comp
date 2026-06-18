library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity processador_tb is
end entity;

architecture a_tb of processador_tb is

    component processador is
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
    end component;

    constant period_time : time := 100 ns;
    signal finished : std_logic := '0';
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';

    signal estado   : std_logic;
    signal pc       : unsigned(6 downto 0);
    signal ir       : unsigned(16 downto 0);
    signal ula      : unsigned(15 downto 0);
    signal r0, r1, r2, r3, r4, r5, r6, r7, r8, r9 : unsigned(15 downto 0);

begin

    uut : processador port map(
        clk => clk, rst => rst, out_estado => estado, out_pc => pc,
        out_ir => ir, out_ula => ula, out_r0 => r0, out_r1 => r1,
        out_r2 => r2, out_r3 => r3, out_r4 => r4, out_r5 => r5,
        out_r6 => r6, out_r7 => r7, out_r8 => r8, out_r9 => r9
    );

    clk_proc : process
    begin
        while finished /= '1' loop
            clk <= '0';
            wait for period_time / 2;
            clk <= '1';
            wait for period_time / 2;
        end loop;
        wait;
    end process;

    rst_proc : process
    begin
        rst <= '1';
        wait for period_time * 1.25;
        rst <= '0';
        wait;
    end process;

    sim_time_proc : process
    begin
        -- 30 iteracoes de loop demoram aprox 25us. Tempo de sobra.
        wait for 80 us; 
        finished <= '1';
        wait;
    end process;

end architecture;