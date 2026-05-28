library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_regs is
    port(
        clk     : in  std_logic;
        rst     : in  std_logic;
        wr_en   : in  std_logic;

        reg_r1  : in  unsigned(3 downto 0); -- selecao leitura 1
        reg_r2  : in  unsigned(3 downto 0); -- selecao leitura 2
        reg_wr  : in  unsigned(3 downto 0); -- selecao escrita
        data_wr : in  unsigned(15 downto 0);

        data_r1 : out unsigned(15 downto 0);
        data_r2 : out unsigned(15 downto 0);

        -- saidas diretas de cada registrador (para visualizacao no top-level)
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
end entity;

architecture a_banco of banco_regs is

    component reg16bits is
        port(
            clk      : in  std_logic;
            rst      : in  std_logic;
            wr_en    : in  std_logic;
            data_in  : in  unsigned(15 downto 0);
            data_out : out unsigned(15 downto 0)
        );
    end component;

    signal q0, q1, q2, q3, q4 : unsigned(15 downto 0);
    signal q5, q6, q7, q8, q9 : unsigned(15 downto 0);

    signal we0, we1, we2, we3, we4 : std_logic;
    signal we5, we6, we7, we8, we9 : std_logic;

begin

    -- decodificador de escrita
    we0 <= '1' when (wr_en = '1' and reg_wr = "0000") else '0';
    we1 <= '1' when (wr_en = '1' and reg_wr = "0001") else '0';
    we2 <= '1' when (wr_en = '1' and reg_wr = "0010") else '0';
    we3 <= '1' when (wr_en = '1' and reg_wr = "0011") else '0';
    we4 <= '1' when (wr_en = '1' and reg_wr = "0100") else '0';
    we5 <= '1' when (wr_en = '1' and reg_wr = "0101") else '0';
    we6 <= '1' when (wr_en = '1' and reg_wr = "0110") else '0';
    we7 <= '1' when (wr_en = '1' and reg_wr = "0111") else '0';
    we8 <= '1' when (wr_en = '1' and reg_wr = "1000") else '0';
    we9 <= '1' when (wr_en = '1' and reg_wr = "1001") else '0';

    reg0: reg16bits port map(clk => clk, rst => rst, wr_en => we0, data_in => data_wr, data_out => q0);
    reg1: reg16bits port map(clk => clk, rst => rst, wr_en => we1, data_in => data_wr, data_out => q1);
    reg2: reg16bits port map(clk => clk, rst => rst, wr_en => we2, data_in => data_wr, data_out => q2);
    reg3: reg16bits port map(clk => clk, rst => rst, wr_en => we3, data_in => data_wr, data_out => q3);
    reg4: reg16bits port map(clk => clk, rst => rst, wr_en => we4, data_in => data_wr, data_out => q4);
    reg5: reg16bits port map(clk => clk, rst => rst, wr_en => we5, data_in => data_wr, data_out => q5);
    reg6: reg16bits port map(clk => clk, rst => rst, wr_en => we6, data_in => data_wr, data_out => q6);
    reg7: reg16bits port map(clk => clk, rst => rst, wr_en => we7, data_in => data_wr, data_out => q7);
    reg8: reg16bits port map(clk => clk, rst => rst, wr_en => we8, data_in => data_wr, data_out => q8);
    reg9: reg16bits port map(clk => clk, rst => rst, wr_en => we9, data_in => data_wr, data_out => q9);

    -- mux de leitura porta 1
    data_r1 <= q0 when reg_r1 = "0000" else
               q1 when reg_r1 = "0001" else
               q2 when reg_r1 = "0010" else
               q3 when reg_r1 = "0011" else
               q4 when reg_r1 = "0100" else
               q5 when reg_r1 = "0101" else
               q6 when reg_r1 = "0110" else
               q7 when reg_r1 = "0111" else
               q8 when reg_r1 = "1000" else
               q9 when reg_r1 = "1001" else
               (others => '0');

    -- mux de leitura porta 2
    data_r2 <= q0 when reg_r2 = "0000" else
               q1 when reg_r2 = "0001" else
               q2 when reg_r2 = "0010" else
               q3 when reg_r2 = "0011" else
               q4 when reg_r2 = "0100" else
               q5 when reg_r2 = "0101" else
               q6 when reg_r2 = "0110" else
               q7 when reg_r2 = "0111" else
               q8 when reg_r2 = "1000" else
               q9 when reg_r2 = "1001" else
               (others => '0');

    -- saidas diretas
    out_r0 <= q0;  out_r1 <= q1;  out_r2 <= q2;
    out_r3 <= q3;  out_r4 <= q4;  out_r5 <= q5;
    out_r6 <= q6;  out_r7 <= q7;  out_r8 <= q8;
    out_r9 <= q9;

end architecture;
