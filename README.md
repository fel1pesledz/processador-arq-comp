# Processador em VHDL - Arquitetura de Computadores

Projeto desenvolvido para a disciplina de Arquitetura de Computadores.

## Estrutura
- src/: código do processador
- tb/: testbenches
- sim/: arquivos de simulação

## Como rodar
ghdl -a src/*.vhd
ghdl -a tb/*.vhd
ghdl -e tb_top
ghdl -r tb_top --wave=sim/wave.ghw