library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uc_tb is
end entity;

architecture a_uc_tb of uc_tb is

    component uc is
        port(
            clk : in std_logic;
            rst : in std_logic;
            out_pc    : out unsigned(6 downto 0);
            out_instr : out unsigned(16 downto 0);
            out_state : out std_logic
        );
    end component;

    constant period_time : time := 100 ns;
    signal finished      : std_logic := '0';
    
    signal clk, rst  : std_logic := '0';
    signal out_pc    : unsigned(6 downto 0);
    signal out_instr : unsigned(16 downto 0);
    signal out_state : std_logic;

begin

    uut: uc port map(
        clk => clk,
        rst => rst,
        out_pc => out_pc,
        out_instr => out_instr,
        out_state => out_state
    );

    reset_global: process
    begin
        rst <= '1';
        wait for period_time * 2;
        rst <= '0';
        wait;
    end process;

    sim_time_proc: process
    begin
        -- 1 microssegundo dá 10 ciclos de clock (suficiente para ver o loop acontecer)
        wait for 1 us; 
        finished <= '1';
        wait;
    end process;

    clk_proc: process
    begin
        while finished /= '1' loop
            clk <= '0';
            wait for period_time / 2;
            clk <= '1';
            wait for period_time / 2;
        end loop;
        wait;
    end process;

end architecture;