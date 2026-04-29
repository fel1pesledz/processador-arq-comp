library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_regs is
    port(
        clock   : in std_logic; -- clock geral 
        rst     : in std_logic; -- reset global 
        wr_en   : in std_logic; -- habilita escrita  
        
        -- entradas de selecao 
        reg_r1  : in unsigned(3 downto 0); -- leitura 1 
        reg_r2  : in unsigned(3 downto 0); -- leitura 2 
        reg_wr  : in unsigned(3 downto 0); -- selecao escrita 
        data_wr : in unsigned(15 downto 0); -- dado para escrita         

        -- saidas
        data_r1 : out unsigned(15 downto 0); -- dado 1 
        data_r2 : out unsigned(15 downto 0)  -- dado 2 
    );
end entity;

architecture a_banco of banco_regs is

    -- Declaracao do componente criado 
    component reg16bits is
        port(
            clk      : in std_logic;
            rst      : in std_logic;
            wr_en    : in std_logic;
            data_in  : in unsigned(15 downto 0);
            data_out : out unsigned(15 downto 0)
        );
    end component;

    -- Sinais para as saidas dos registradores 
    signal out_r0, out_r1, out_r2, out_r3, out_r4 : unsigned(15 downto 0);
    signal out_r5, out_r6, out_r7, out_r8, out_r9 : unsigned(15 downto 0);
    
    -- Sinais de controle do write_enable
    signal we_0, we_1, we_2, we_3, we_4 : std_logic;
    signal we_5, we_6, we_7, we_8, we_9 : std_logic;

begin

    -- DECODIFICADOR DE ESCRITA 
    we_0 <= '1' when (wr_en = '1' and reg_wr = "0000") else '0';
    we_1 <= '1' when (wr_en = '1' and reg_wr = "0001") else '0';
    we_2 <= '1' when (wr_en = '1' and reg_wr = "0010") else '0';
    we_3 <= '1' when (wr_en = '1' and reg_wr = "0011") else '0';
    we_4 <= '1' when (wr_en = '1' and reg_wr = "0100") else '0';
    we_5 <= '1' when (wr_en = '1' and reg_wr = "0101") else '0';
    we_6 <= '1' when (wr_en = '1' and reg_wr = "0110") else '0';
    we_7 <= '1' when (wr_en = '1' and reg_wr = "0111") else '0';
    we_8 <= '1' when (wr_en = '1' and reg_wr = "1000") else '0';
    we_9 <= '1' when (wr_en = '1' and reg_wr = "1001") else '0';

    -- INSTANCIACAO DOS 10 REGISTRADORES 
    reg0: reg16bits port map(clk => clock, rst => rst, wr_en => we_0, data_in => data_wr, data_out => out_r0);
    reg1: reg16bits port map(clk => clock, rst => rst, wr_en => we_1, data_in => data_wr, data_out => out_r1);
    reg2: reg16bits port map(clk => clock, rst => rst, wr_en => we_2, data_in => data_wr, data_out => out_r2);
    reg3: reg16bits port map(clk => clock, rst => rst, wr_en => we_3, data_in => data_wr, data_out => out_r3);
    reg4: reg16bits port map(clk => clock, rst => rst, wr_en => we_4, data_in => data_wr, data_out => out_r4);
    reg5: reg16bits port map(clk => clock, rst => rst, wr_en => we_5, data_in => data_wr, data_out => out_r5);
    reg6: reg16bits port map(clk => clock, rst => rst, wr_en => we_6, data_in => data_wr, data_out => out_r6);
    reg7: reg16bits port map(clk => clock, rst => rst, wr_en => we_7, data_in => data_wr, data_out => out_r7);
    reg8: reg16bits port map(clk => clock, rst => rst, wr_en => we_8, data_in => data_wr, data_out => out_r8);
    reg9: reg16bits port map(clk => clock, rst => rst, wr_en => we_9, data_in => data_wr, data_out => out_r9);

    data_r1 <= out_r0 when reg_r1 = "0000" else
               out_r1 when reg_r1 = "0001" else
               out_r2 when reg_r1 = "0010" else
               out_r3 when reg_r1 = "0011" else
               out_r4 when reg_r1 = "0100" else
               out_r5 when reg_r1 = "0101" else
               out_r6 when reg_r1 = "0110" else
               out_r7 when reg_r1 = "0111" else
               out_r8 when reg_r1 = "1000" else
               out_r9 when reg_r1 = "1001" else
               "0000000000000000";

    data_r2 <= out_r0 when reg_r2 = "0000" else
               out_r1 when reg_r2 = "0001" else
               out_r2 when reg_r2 = "0010" else
               out_r3 when reg_r2 = "0011" else
               out_r4 when reg_r2 = "0100" else
               out_r5 when reg_r2 = "0101" else
               out_r6 when reg_r2 = "0110" else
               out_r7 when reg_r2 = "0111" else
               out_r8 when reg_r2 = "1000" else
               out_r9 when reg_r2 = "1001" else
               "0000000000000000";

end architecture;