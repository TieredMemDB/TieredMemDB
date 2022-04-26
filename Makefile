# Top level makefile, the real shit is at src/Makefile

default: all

.DEFAULT:
	cd src && $(MAKE) $@

install:
	cd src && $(MAKE) $@

.PHONY: install

TARBALL=tmdb-$(shell git describe)
git-tarball:
	git archive --prefix=$(TARBALL)/ @ >../$(TARBALL).tar
	cd deps/memkind && git archive --prefix=$(TARBALL)/deps/memkind/ @ >../../memkind.tar
	tar -Af ../$(TARBALL).tar memkind.tar
	rm memkind.tar
	xz ../$(TARBALL).tar
