##
## This file is part of the libopencm3 project.
##
## Copyright (C) 2009 Uwe Hermann <uwe@hermann-uwe.de>
##
## This library is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.
##

PREFIX		?= arm-none-eabi
#PREFIX		?= arm-elf

STYLECHECK      := scripts/checkpatch.pl
STYLECHECKFLAGS := --no-tree -f --terse --mailback

ifeq ($(DETECT_TOOLCHAIN),)
DESTDIR		?= /usr/local
else
DESTDIR		?= $(shell dirname $(shell readlink -f $(shell which $(PREFIX)-gcc)))/..
endif

INCDIR		:= $(DESTDIR)/$(PREFIX)/include
LIBDIR		:= $(DESTDIR)/$(PREFIX)/lib
SHAREDIR	:= $(DESTDIR)/$(PREFIX)/share/libopencm3/scripts
INSTALL		:= install

SRCLIBDIR:= $(realpath lib)

TARGETS:= stm32/f0 stm32/f1 stm32/f2 stm32/f3 stm32/f4 stm32/l1 lpc13xx lpc17xx \
	  lpc43xx/m4 lpc43xx/m0 lm3s lm4f \
	  efm32/efm32tg efm32/efm32g efm32/efm32lg efm32/efm32gg sam/3x sam/3n

# Be silent per default, but 'make V=1' will show all compiler calls.
ifneq ($(V),1)
Q := @
# Do not print "Entering directory ...".
MAKEFLAGS += --no-print-directory
endif

YAMLFILES	:= $(shell find . -name 'irq.yaml')
STYLECHECKFILES := $(shell find . -name '*.[ch]')

all: build

build: lib

%.genhdr:
	@printf "  GENHDR  $*\n";
	@./scripts/irq2nvic_h ./$*;

%.cleanhdr:
	@printf "  CLNHDR  $*\n";
	@./scripts/irq2nvic_h --remove ./$*

LIB_DIRS:=$(wildcard $(addprefix lib/,$(TARGETS)))
$(LIB_DIRS): $(YAMLFILES:=.genhdr)
	@printf "  BUILD   $@\n";
	$(Q)$(MAKE) --directory=$@ SRCLIBDIR=$(SRCLIBDIR)

lib: $(LIB_DIRS)
	$(Q)true

install: lib
	@printf "  INSTALL headers\n"
	$(Q)$(INSTALL) -d $(INCDIR)/libopencm3
	$(Q)$(INSTALL) -d $(INCDIR)/libopencmsis
	$(Q)$(INSTALL) -d $(LIBDIR)
	$(Q)$(INSTALL) -d $(SHAREDIR)
	$(Q)cp -r include/libopencm3/* $(INCDIR)/libopencm3
	$(Q)cp -r include/libopencmsis/* $(INCDIR)/libopencmsis
	@printf "  INSTALL libs\n"
	$(Q)$(INSTALL) -m 0644 lib/*.a $(LIBDIR)
	@printf "  INSTALL ldscripts\n"
	$(Q)$(INSTALL) -m 0644 lib/*.ld $(LIBDIR)
	$(Q)$(INSTALL) -m 0644 lib/efm32/*/*.ld $(LIBDIR)
	@printf "  INSTALL scripts\n"
	$(Q)$(INSTALL) -m 0644 scripts/*.scr $(SHAREDIR)

doc:
	$(Q)$(MAKE) -C doc html

clean: $(YAMLFILES:=.cleanhdr) $(LIB_DIRS:=.clean) $(EXAMPLE_DIRS:=.clean) doc.clean styleclean

%.clean:
	$(Q)if [ -d $* ]; then \
		printf "  CLEAN   $*\n"; \
		$(MAKE) -C $* clean SRCLIBDIR=$(SRCLIBDIR) || exit $?; \
	fi;


stylecheck: $(STYLECHECKFILES:=.stylecheck)
styleclean: $(STYLECHECKFILES:=.styleclean)

# the cat is due to multithreaded nature - we like to have consistent chunks of text on the output
%.stylecheck:
	$(Q)if ! grep -q "* It was generated by the irq2nvic_h script." $* ; then \
		$(STYLECHECK) $(STYLECHECKFLAGS) $* > $*.stylecheck; \
		if [ -s $*.stylecheck ]; then \
			cat $*.stylecheck; \
		else \
			rm -f $*.stylecheck; \
		fi; \
	fi;

%.styleclean:
	$(Q)rm -f $*.stylecheck;

.PHONY: build lib $(LIB_DIRS) install doc clean stylecheck styleclean

