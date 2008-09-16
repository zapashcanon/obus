# Makefile
# --------
# Copyright : (c) 2008, Jeremie Dimino <jeremie@dimino.org>
# Licence   : BSD3
#
# This file is a part of obus, an ocaml implemtation of dbus.

OC = ocamlbuild
OF = ocamlfind
PREFIX = /usr/local

# Targets
SAMPLES = hello bus-functions eject notif monitor signals list-services avahi-list-workstations
LIB = obus
BINDINGS = hal notify
TOOLS = obus-introspect obus-binder
TEST = data dyn dumper valid

.PHONY: tools samples bindings all test lib default install

default: samples-byte

all: lib bindings tools samples doc META lib-dist

# List all package dependencies
list-deps:
	@sh check-deps.sh list

# Check that all dependencies are present
check-deps:
	@sh check-deps.sh

# +------------------+
# | Specific targets |
# +------------------+

lib-byte:
	$(OC) $(LIB:=.cma)

lib-native:
	$(OC) $(LIB:=.cmxa)

lib:
	$(OC) $(LIB:=.cma) $(LIB:=.cmxa)

bindings-byte:
	$(OC) $(BINDINGS:=.cma)

bindings-native:
	$(OC) $(BINDINGS:=.cmxa)

bindings:
	$(OC) $(BINDINGS:=.cma) $(BINDINGS:=.cmxa)

samples-byte:
	$(OC) $(SAMPLES:%=samples/%.byte)

samples-native:
	$(OC) $(SAMPLES:%=samples/%.native)

samples:
	$(OC) $(SAMPLES:%=samples/%.byte) $(SAMPLES:%=samples/%.native)

tools-byte:
	$(OC) $(TOOLS:%=tools/%.byte)

tools-native:
	$(OC) $(TOOLS:%=tools/%.native)

tools:
	$(OC) $(TOOLS:%=tools/%.byte)  $(TOOLS:%=tools/%.native)

test:
	$(OC) $(TEST:%=test/%.d.byte)

test-syntax: syntax/pa_obus.cmo
	camlp4o _build/syntax/pa_obus.cmo test/syntax_extension.ml

# +---------------+
# | Documentation |
# +---------------+

doc:
	$(OC) obus.docdir/index.html

dot:
	$(OC) obus.docdir/index.dot

# +--------------------+
# | Installation stuff |
# +--------------------+

install: all just-install

just-install:
	$(OF) install obus _build/META `cat _build/lib-dist` \
	 _build/syntax/pa_obus.cmo \
	 $(LIB:%=_build/%.cma) \
	 $(LIB:%=_build/%.cmxa) \
	 $(LIB:%=_build/%.a) \
	 $(BINDINGS:%=_build/%.cma) \
	 $(BINDINGS:%=_build/%.cmxa) \
	 $(BINDINGS:%=_build/%.a)
	for tool in $(TOOLS); do \
	  install -vm 0755 _build/tools/$$tool.native $(PREFIX)/bin/$$tool; \
	done
	mkdir -p $(PREFIX)/share/doc/obus/samples
	mkdir -p $(PREFIX)/share/doc/obus/html
	install -vm 0644 LICENSE $(PREFIX)/share/doc/obus
	install -vm 0644 _build/obus.docdir/* $(PREFIX)/share/doc/obus/html
	install -vm 0644 samples/*.ml $(PREFIX)/share/doc/obus/samples

uninstall:
	$(OF) remove obus
	rm -vf $(TOOLS:%=$(PREFIX)/bin/%)
	rm -rvf $(PREFIX)/share/doc/obus

# +-------+
# | Other |
# +-------+

clean:
	$(OC) -clean

# "make" is shorter than "ocamlbuild"...
%:
	$(OC) $*
