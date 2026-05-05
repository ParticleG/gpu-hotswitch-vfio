PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: install uninstall

install:
	install -Dm755 gpu-hotswitch-vfio $(DESTDIR)$(BINDIR)/gpu-hotswitch-vfio

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/gpu-hotswitch-vfio
