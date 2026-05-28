library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Registrador de 7 bits para o Program Counter
-- Borda de descida
-- Incremento e MUX de selecao (PC+1 vs endereco de salto) ficam no top-level.

entity pc is
    port(
        clk      : in  std_logic;
        rst      : in  std_logic;
        wr_en    : in  std_logic;
        data_in  : in  unsigned(6 downto 0);
        data_out : out unsigned(6 downto 0)
    );
end entity;

architecture a_pc of pc is
    signal valor : unsigned(6 downto 0);
begin
    process(clk, rst, wr_en)
    begin
        if rst = '1' then
            valor <= (others => '0');
        elsif wr_en = '1' then
            if falling_edge(clk) then
                valor <= data_in;
            end if;
        end if;
    end process;

    data_out <= valor;
end architecture;
