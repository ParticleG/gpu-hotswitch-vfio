PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall

install:
	install -Dm755 gpu-passthrough $(DESTDIR)$(BINDIR)/gpu-passthrough

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/gpu-passthrough
