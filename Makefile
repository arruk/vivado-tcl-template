.DEFAULT_GOAL := all
.NOTPARALLEL:
.PHONY: all project synth impl bitstream program program-only gui clean help

VIVADO ?= vivado
JOBS ?= 4
ROOT := $(CURDIR)

all: bitstream

project synth impl bitstream:
	mkdir -p build/logs
	cd build && "$(VIVADO)" -mode batch \
		-log "logs/$@.log" -journal "logs/$@.jou" \
		-source "$(ROOT)/scripts/build.tcl" -tclargs "$@" "$(JOBS)"

#Compila primeiro; somente um bitstream de uma compilacao bem-sucedida e gravado.
program: bitstream
	$(MAKE) program-only

# Grava o arquivo existente, sem verificar se o RTL mudou.
program-only:
	mkdir -p build/logs
	cd build && "$(VIVADO)" -mode batch \
		-log logs/program.log -journal logs/program.jou \
		-source "$(ROOT)/scripts/program.tcl"

gui:
	mkdir -p build/logs
	cd build && "$(VIVADO)" -mode gui \
		-log logs/gui.log -journal logs/gui.jou \
		-source "$(ROOT)/scripts/build.tcl" -tclargs gui "$(JOBS)"

clean:
	$(RM) -r -- build

help:
	@echo 'make / make bitstream: sintese, implementacao e geracao do .bit'
	@echo 'make project: cria/atualiza o projeto; make synth: ate sintese'
	@echo 'make impl: ate roteamento; make gui: abre o projeto na GUI'
	@echo 'make program: compila e grava via JTAG'
	@echo 'make program-only: grava o .bit existente sem recompilar'
	@echo 'make clean: remove build/; make -n program: mostra os comandos'
	@echo 'Opcoes: VIVADO=/caminho/bin/vivado JOBS=4'
	@echo 'JTAG: HW_SERVER=localhost:3121 HW_TARGET=padrao HW_DEVICE=xc7z035_1'
