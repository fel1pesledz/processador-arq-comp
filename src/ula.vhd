library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ula is
    port(
        entrada_A : in unsigned(15 downto 0);
        entrada_B : in unsigned(15 downto 0);
        selec_op  : in unsigned(2 downto 0);  -- 3 bits: ADD,SUB,SUBB,AND,OR,MOV
        borrow_in : in std_logic;             -- borrow para SUBB

        resultado  : out unsigned(15 downto 0);

        flag_zero  : out std_logic;
        flag_neg   : out std_logic;
        flag_overf : out std_logic;
        flag_carry : out std_logic
    );
end entity;

architecture arq_ula of ula is
    signal res_interno  : unsigned(15 downto 0);
    signal res_ext      : unsigned(16 downto 0);
begin

    -- selec_op:
    --   000 = ADD   A + B
    --   001 = SUB   A - B  (sem borrow)
    --   010 = SUBB  A - B - borrow_in
    --   011 = AND   A and B
    --   100 = OR    A or B
    --   101 = MOV   passa A (usado por MOV e CLR: B=0 externo)
    --   outros = zero

    res_ext <=
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

    res_interno <= res_ext(15 downto 0);
    resultado   <= res_interno;

    flag_zero  <= '1' when res_interno = x"0000" else '0';
    flag_neg   <= res_interno(15);
    flag_carry <= res_ext(16);

    flag_overf <=
        ((    entrada_A(15) and     entrada_B(15) and not res_interno(15)) or
         (not entrada_A(15) and not entrada_B(15) and     res_interno(15)))
            when selec_op = "000" else
        ((    entrada_A(15) and not entrada_B(15) and not res_interno(15)) or
         (not entrada_A(15) and     entrada_B(15) and     res_interno(15)))
            when (selec_op = "001" or selec_op = "010") else
        '0';

end architecture;
