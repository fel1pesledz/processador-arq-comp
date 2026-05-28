library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- selec_op:
--   000 = ADD    resultado = A + B
--   001 = SUB    resultado = A - B
--   010 = SUBB   resultado = A - B - borrow_in
--   011 = AND    resultado = A and B
--   100 = OR     resultado = A or B
--   101 = MOV    resultado = A
--   outros       resultado = 0

entity ula is
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
end entity;

architecture a_ula of ula is
    signal resultado_s : unsigned(15 downto 0);
    signal soma_ext    : unsigned(16 downto 0); -- bit extra para capturar carry
begin

    soma_ext <=
        ('0' & entrada_A) + ('0' & entrada_B)
            when selec_op = "000" else
        ('0' & entrada_A) - ('0' & entrada_B)
            when selec_op = "001" else
        ('0' & entrada_A) - ('0' & entrada_B) - (to_unsigned(0,16) & borrow_in)
            when selec_op = "010" else
        ('0' & (entrada_A and entrada_B))
            when selec_op = "011" else
        ('0' & (entrada_A or  entrada_B))
            when selec_op = "100" else
        ('0' & entrada_A)
            when selec_op = "101" else
        (others => '0');

    resultado_s <= soma_ext(15 downto 0);
    resultado   <= resultado_s;

    flag_zero  <= '1' when resultado_s = x"0000" else '0';
    flag_neg   <= resultado_s(15);
    flag_carry <= soma_ext(16);

    flag_overf <=
        ((    entrada_A(15) and     entrada_B(15) and not resultado_s(15)) or
         (not entrada_A(15) and not entrada_B(15) and     resultado_s(15)))
            when selec_op = "000" else
        ((    entrada_A(15) and not entrada_B(15) and not resultado_s(15)) or
         (not entrada_A(15) and     entrada_B(15) and     resultado_s(15)))
            when (selec_op = "001" or selec_op = "010") else
        '0';

end architecture;
