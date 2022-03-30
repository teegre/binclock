PROGNAME  ?= binclock
PREFIX    ?= $(HOME)/.local
BINDIR    ?= $(PREFIX)/bin
SHAREDIR  ?= $(PREFIX)/share/$(PROGNAME)
LICENSE   ?= $(SHAREDIR)/license

.PHONY: install
install:src/$(PROGNAME)
	install -d $(BINDIR)
	install -m755 src/$(PROGNAME) $(BINDIR)/$(PROGNAME)
	install -Dm644 LICENSE -t $(LICENSE)
	rm src/$(PROGNAME)

.PHONY: uninstall
uninstall:
	rm $(BINDIR)/$(PROGNAME)
	rm -rf $(SHAREDIR)
