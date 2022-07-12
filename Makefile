# Top level makefile, the real shit is at src/Makefile

default: all

.DEFAULT:
	cd src && $(MAKE) $@

install:
	cd src && $(MAKE) $@

.PHONY: install

AUTOCONFAGE=Makefile.in \
	aclocal.m4 \
	ar-lib \
	compile \
	config.guess \
	config.h.in \
	config.sub \
	configure \
	depcomp \
	install-sh \
	ltmain.sh \
	m4/libtool.m4 \
	m4/ltoptions.m4 \
	m4/ltsugar.m4 \
	m4/ltversion.m4 \
	m4/lt~obsolete.m4 \
	missing \
	test-driver

TARBALL=tmdb-$(shell git describe --tags)
# Before running this target, two steps are required:
# make
# git submodule update --init
git-tarball:
	git archive --prefix=$(TARBALL)/ @ >../$(TARBALL).tar
	cd deps/memkind && git archive --prefix=$(TARBALL)/deps/memkind/ @ >../../memkind.tar
	cd deps/memkind && git clean -dfx && ./autogen.sh
	cd deps/memkind/jemalloc && autoconf
	tar cf memkind-autoconf.tar --transform s,^,$(TARBALL)/, $(addprefix deps/memkind/,$(AUTOCONFAGE) jemalloc/configure)
	tar -Af ../$(TARBALL).tar memkind.tar
	tar -Af ../$(TARBALL).tar memkind-autoconf.tar
	rm memkind.tar memkind-autoconf.tar
	xz ../$(TARBALL).tar
