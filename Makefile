PROJECT ?= rockchip-alsa-config
PREFIX ?= /usr
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib
MANDIR ?= $(PREFIX)/share/man

.PHONY: all
all: build

#
# Test
#
.PHONY: test
test:

#
# Build
#
.PHONY: build
build: build-doc build-symlink

SRC-DOC		:=	.
DOCS		:=	$(SRC-DOC)/SOURCE
.PHONY: build-doc
build-doc: $(DOCS)

$(SRC-DOC):
	mkdir -p $(SRC-DOC)

.PHONY: $(SRC-DOC)/SOURCE
$(SRC-DOC)/SOURCE: $(SRC-DOC)
	echo -e "git clone $(shell git remote get-url origin)\ngit checkout $(shell git rev-parse HEAD)" > "$@"

SRC-SYMLINKS	:=	$(wildcard src/alsa/ucm2/conf.d/*)
SYMLINKS		:=	$(addprefix src/alsa/ucm2/, $(notdir $(SRC-SYMLINKS)))
.PHONY: build-symlink
build-symlink: $(SYMLINKS)

src/alsa/ucm2/%: src/alsa/ucm2/conf.d/%
	ln -s conf.d/$(notdir $@) $@

#
# Clean
#
.PHONY: distclean
distclean: clean

.PHONY: clean
clean: clean-doc clean-symlink clean-deb

.PHONY: clean-doc
clean-doc:
	rm -rf $(DOCS)

.PHONY: clean-symlink
clean-symlink:
	rm -f $(SYMLINKS)

.PHONY: clean-deb
clean-deb:
	rm -rf debian/.debhelper debian/${PROJECT} debian/debhelper-build-stamp debian/files debian/*.debhelper.log debian/*.postrm.debhelper debian/*.substvars

#
# Release
#
.PHONY: dch
dch: debian/changelog
	EDITOR=true gbp dch --debian-branch=main --commit --release --dch-opt=--upstream --multimaint-merge

.PHONY: deb
deb: debian
	debuild --no-lintian --lintian-hook "lintian --fail-on error,warning --suppress-tags bad-distribution-in-changes-file -- %p_%v_*.changes" --no-sign -b

.PHONY: release
release:
	gh workflow run .github/workflows/new_version.yml
