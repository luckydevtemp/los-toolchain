#===========================================================================
# Este arquivo pertence ao Projeto do Sistema Operacional LuckyOS (LOS).
# --------------------------------------------------------------------------
# Copyright (C) 2013 - Luciano L. Goncalez
# --------------------------------------------------------------------------
# eMail : dev.lucianogoncalez@gmail.com
# Home  : http://lucky-labs.blogspot.com.br
# ==========================================================================
# Este programa e software livre; voce pode redistribui-lo e/ou modifica-lo
# sob os termos da Licenca Publica Geral GNU, conforme publicada pela Free
# Software Foundation; na versao 2 da Licenca.
#
# Este programa e distribuido na expectativa de ser util, mas SEM QUALQUER
# GARANTIA; sem mesmo a garantia implicita de COMERCIALIZACAO ou de
# ADEQUACAO A QUALQUER PROPOSITO EM PARTICULAR. Consulte a Licenca Publica
# Geral GNU para obter mais detalhes.
#
# Voce deve ter recebido uma copia da Licenca Publica Geral GNU junto com
# este programa; se nao, escreva para a Free Software Foundation, Inc., 59
# Temple Place, Suite 330, Boston, MA 02111-1307, USA. Ou acesse o site do
# GNU e obtenha sua licenca: http://www.gnu.org/
# ==========================================================================
# Makefile (ToolChain)
# --------------------------------------------------------------------------
#   Este é o arquivo de makefile, ele é responsavel pelas construção do
# sistema.
# --------------------------------------------------------------------------
# Criado em: 31/01/2020
# --------------------------------------------------------------------------
# Uso:
# > make
# ------------------------------------------------------------------------
# Executar: Arquivo de configuracao.
#============================================================================


## Configurações gerais ##
MAIN_DIR := $(CURDIR)
AID_DIR := $(MAIN_DIR)/aid
BUILD_DIR := $(MAIN_DIR)/build

COMPILER_NAME := fpc
COMPILER := $(shell which $(COMPILER_NAME))

FPC_244_SRC := 'https://master.dl.sourceforge.net/project/freepascal/Source/2.4.4/fpc-2.4.4.source.tar.gz'
FPC_300_SRC := 'https://master.dl.sourceforge.net/project/freepascal/Source/3.0.0/fpc-3.0.0.source.tar.gz'


## Checagens ##

# Compiler
ifeq ("$(COMPILER)", "")
compiler_error:
	@echo >&2
	@echo >&2 "Não foi possível localizar o compilador FPC, você deve instalá-lo pelo gerenciador de pacotes de sua distro."
	@echo >&2
	@exit 1
endif


# Phony

.PONHY: all clean distclean cleanall cleandownloads download fpc ppc386-3.0.0 ppc386-2.4.4-cross ppc386-2.4.4


# Geral

all: $(MAIN_DIR)/toolchain-build-stamp

clean:
	-rm -rf $(BUILD_DIR)/fpc-2.4.4
	-rm -rf $(BUILD_DIR)/fpc-2.4.4-cross
	-rm -rf $(BUILD_DIR)/fpc-3.0.0
	-rm $(BUILD_DIR)/ppc386-*

distclean: cleanall
	-rm $(MAIN_DIR)/ppc386
	-rm $(MAIN_DIR)/toolchain-build-stamp

cleanall: clean cleandownloads
	-rm -rf $(BUILD_DIR)

cleandownloads:
	-rm $(BUILD_DIR)/fpc-3.0.0.source.tar.gz
	-rm $(BUILD_DIR)/fpc-2.4.4.source.tar.gz

download: $(BUILD_DIR)/fpc-2.4.4.source.tar.gz $(BUILD_DIR)/fpc-3.0.0.source.tar.gz 

$(MAIN_DIR)/toolchain-build-stamp:
	@$(MAKE) download
	@$(MAKE) fpc
	@$(MAKE) cleanall
	@echo "Build" > $(MAIN_DIR)/toolchain-build-stamp
	@echo
	@echo "O Toolchain foi construído com sucesso!."
	@echo


# ToolChain

fpc: $(MAIN_DIR)/ppc386

ppc386-2.4.4: $(BUILD_DIR)/ppc386-2.4.4

ppc386-2.4.4-cross: $(BUILD_DIR)/ppc386-2.4.4-cross

ppc386-3.0.0: $(BUILD_DIR)/ppc386-3.0.0


# Binários

$(MAIN_DIR)/ppc386: | $(BUILD_DIR)/ppc386-2.4.4
	cp $(BUILD_DIR)/ppc386-2.4.4 $(MAIN_DIR)/ppc386

$(BUILD_DIR)/ppc386-2.4.4: | $(BUILD_DIR)/ppc386-2.4.4-cross $(BUILD_DIR)/fpc-2.4.4
	$(MAKE) -C $(BUILD_DIR)/fpc-2.4.4 buildbase CPU_TARGET=i386 FPC=$(BUILD_DIR)/ppc386-2.4.4-cross
	cp $(BUILD_DIR)/fpc-2.4.4/compiler/ppc386 $(BUILD_DIR)/ppc386-2.4.4

$(BUILD_DIR)/ppc386-2.4.4-cross: | $(BUILD_DIR)/ppc386-3.0.0 $(BUILD_DIR)/fpc-2.4.4-cross
	$(MAKE) -C $(BUILD_DIR)/fpc-2.4.4-cross rtl compiler CPU_TARGET=i386 FPC=$(BUILD_DIR)/ppc386-3.0.0
	cp $(BUILD_DIR)/fpc-2.4.4-cross/compiler/ppc386 $(BUILD_DIR)/ppc386-2.4.4-cross

$(BUILD_DIR)/ppc386-3.0.0: | $(BUILD_DIR)/fpc-3.0.0
	$(MAKE) -C $(BUILD_DIR)/fpc-3.0.0 buildbase CPU_TARGET=i386 PATH='$(PATH):$(AID_DIR)'
	cp $(BUILD_DIR)/fpc-3.0.0/compiler/ppc386 $(BUILD_DIR)/ppc386-3.0.0


# Diretórios

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/fpc-2.4.4: | $(BUILD_DIR)/fpc-2.4.4.source.tar.gz
	tar -C $(BUILD_DIR) -zxf $(BUILD_DIR)/fpc-2.4.4.source.tar.gz

$(BUILD_DIR)/fpc-2.4.4-cross: | $(BUILD_DIR)/fpc-2.4.4 $(BUILD_DIR)/fpc-3.0.0
	mkdir -p $(BUILD_DIR)/fpc-2.4.4-cross
	cp -r $(BUILD_DIR)/fpc-2.4.4/compiler $(BUILD_DIR)/fpc-2.4.4-cross
	cp -r $(BUILD_DIR)/fpc-3.0.0/rtl $(BUILD_DIR)/fpc-2.4.4-cross
	cp $(BUILD_DIR)/fpc-2.4.4/Makefile $(BUILD_DIR)/fpc-2.4.4-cross
	
	rm $(BUILD_DIR)/fpc-2.4.4-cross/compiler/cp*
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/htypechk.pas -i $(AID_DIR)/htypechk.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/ncal.pas -i $(AID_DIR)/ncal.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/ncgcal.pas -i $(AID_DIR)/ncgcal.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/ninl.pas -i $(AID_DIR)/ninl.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/nutils.pas -i $(AID_DIR)/nutils.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/ogbase.pas -i $(AID_DIR)/ogbase.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/options.pas -i $(AID_DIR)/options.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/optloop.pas -i $(AID_DIR)/optloop.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/pstatmnt.pas -i $(AID_DIR)/pstatmnt.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/psub.pas -i $(AID_DIR)/psub.pas.patch
	patch $(BUILD_DIR)/fpc-2.4.4-cross/compiler/utils/ppumove.pp -i $(AID_DIR)/ppumove.pp.patch

$(BUILD_DIR)/fpc-3.0.0: | $(BUILD_DIR)/fpc-3.0.0.source.tar.gz
	tar -C $(BUILD_DIR) -zxf $(BUILD_DIR)/fpc-3.0.0.source.tar.gz


# Sources

$(BUILD_DIR)/fpc-2.4.4.source.tar.gz: | $(BUILD_DIR)
	@echo
	@echo -n "Será feito o download de um arquivo fonte de 25 MiB. Deseja continuar? [s/N] " && read ans && [ $${ans:-N} = s ]
	@echo
	wget $(FPC_244_SRC) -P $(BUILD_DIR)

$(BUILD_DIR)/fpc-3.0.0.source.tar.gz: | $(BUILD_DIR)
	@echo
	@echo -n "Será feito o download de um arquivo fonte de 37 MiB. Deseja continuar? [s/N] " && read ans && [ $${ans:-N} = s ]
	@echo
	wget $(FPC_300_SRC) -P $(BUILD_DIR)
