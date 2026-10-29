# Template Vivado Tcl — ALINX AX7350B

Fluxo **Project Mode via Tcl**, baseado no exemplo RTL das páginas 72–73 do
[UG892](https://docs.amd.com/r/en-US/ug892-vivado-design-flows-overview).
O projeto usa `xc7z035ffg676-2` e pode ser aberto na interface gráfica.

```text
create_project / open_project
  -> add_files + constraints XDC + top + update_compile_order
  -> launch_runs synth_1 + wait_on_run
  -> launch_runs impl_1 -to_step route_design + wait_on_run
  -> launch_runs impl_1 -to_step write_bitstream + wait_on_run
  -> Hardware Manager -> program_hw_devices
```

`write_bitstream` **gera** o `.bit`. `program_hw_devices` **grava** esse arquivo
na memória de configuração da PL via JTAG; essa configuração é volátil.
O template cobre RTL na PL, sem configurar o PS, iniciar aplicações ARM ou
criar uma imagem persistente `BOOT.BIN` para SD/QSPI/eMMC.

## Uso

Carregue o ambiente da sua instalação (substitua o caminho):

```bash
source /caminho/para/Vivado/2023.1/settings64.sh
make
make program
```

Também pode apontar diretamente para o executável:

```bash
make VIVADO=/caminho/para/Vivado/2023.1/bin/vivado JOBS=4
```

A instalação precisa ter suporte ao Zynq-7000 e licença válida para o
`xc7z035`, quando exigida pela edição instalada. 

| Comando | Operação |
| --- | --- |
| `make` ou `make bitstream` | Executa até gerar `build/bitstream/top.bit` |
| `make project` | Cria ou atualiza o projeto, sem compilar |
| `make synth` | Executa até a síntese |
| `make impl` | Executa até posicionamento e roteamento |
| `make program` | Atualiza o bitstream e grava a FPGA via JTAG |
| `make program-only` | Grava o `.bit` existente, sem verificar mudanças no RTL |
| `make gui` | Cria/atualiza e abre o projeto na interface gráfica |
| `make -n program` | Mostra os comandos sem executar |
| `make clean` | Remove os arquivos gerados em `build/` |

O exemplo em `rtl/top.v` alterna os quatro LEDs PL a cada segundo usando o
oscilador PL de 50 MHz. Os pinos e padrões elétricos em
`constraints/ax7350b.xdc` seguem o
[tutorial de LED do fabricante](https://ax7350b-20231-v101.readthedocs.io/zh-cn/latest/7350B_S1_RSTdocument_CN/04_PL%E7%9A%84LED%E5%AE%9E%E9%AA%8C_CN.html):
clock J14/LVCMOS18; LEDs F5, E5, G5, G6/LVCMOS15.

## Organização

```text
project.tcl              nome, part, top, lista de fontes, XDC e seleção JTAG
scripts/build.tcl        criação, síntese, implementação, bitstream e relatórios
scripts/program.tcl      conexão com hw_server e programação JTAG
rtl/top.v                exemplo mínimo com quatro LEDs
constraints/ax7350b.xdc  pinos, padrões elétricos e clock do exemplo
Makefile                 comandos de terminal
build/                   projeto, runs, bitstream, relatórios e logs gerados
```

Edite `project.tcl` para mudar `top`, `rtl_files`, `xdc_files`, `include_dirs`
ou `verilog_defines`. As listas são explícitas: novos arquivos devem ser
adicionados à configuração. Podem incluir Verilog, SystemVerilog e VHDL;
bibliotecas VHDL e opções de linguagem específicas precisam ser configuradas
no Tcl conforme o projeto. IPs e Block Designs também exigem suas etapas de
geração e wrappers, que este exemplo RTL não implementa.

Os caminhos partem da localização de `project.tcl`. As fontes são adicionadas
por referência com `add_files`, permanecendo nos diretórios originais.
Não é necessário usar `import_files`, que copia fontes para dentro do projeto.
Se mudar o `part`, execute `make clean` para recriar o projeto.

O projeto gerado fica em `build/vivado/ax7350b.xpr`; os relatórios explícitos
em `build/reports/` e os logs em `build/logs/` e
`build/vivado/ax7350b.runs/`. Os relatórios de timing e DRC devem ser revisados
antes de usar um projeto modificado; sucesso na geração não substitui essa
análise. O script não impõe um critério adicional de aprovação de timing.

## Reutilização das etapas

Cada comando inicia o Vivado e abre o projeto persistente. O script consulta
`NEEDS_REFRESH`, `PROGRESS` e `STATUS` para reaproveitar runs concluídas e
atuais. 

Quando a síntese precisa ser refeita, a implementação também é invalidada.
Uma implementação já roteada pode continuar até `write_bitstream`.
O script verifica o resultado depois de `wait_on_run` e retorna erro ao Make
em caso de falha. Uma falha na compilação impede a etapa JTAG de `make program`.
Para forçar uma compilação completa, use `make clean` seguido de `make`.
Execute uma chamada por vez sobre este diretório de build.

## Execução direta em Tcl

O Makefile é opcional. Na raiz do template:

```bash
vivado -mode batch -source scripts/build.tcl -tclargs project
vivado -mode batch -source scripts/build.tcl -tclargs synth 4
vivado -mode batch -source scripts/build.tcl -tclargs impl 4
vivado -mode batch -source scripts/build.tcl -tclargs bitstream 4
vivado -mode batch -source scripts/program.tcl
```

Para o batch, o `start_gui` do exemplo do manual foi omitido. `open_run`
continua sendo usado para gerar os relatórios, inclusive em batch.
Use `make gui` quando quiser inspecionar o projeto visualmente.

## Referências

- [UG892](https://docs.amd.com/r/en-US/ug892-vivado-design-flows-overview), figura 5 e páginas 71–73: fluxo e exemplo em Project Mode.
- [Repositório ALINX AX7350B_2023.1](https://github.com/alinxalinx/AX7350B_2023.1).
- [AMD UG835: comandos Tcl](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands).
- [AMD: wait_on_run e verificação de sucesso](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/wait_on_runs).
- [AMD: program_hw_devices](https://docs.amd.com/r/en-US/ug835-vivado-tcl-commands/program_hw_devices).
