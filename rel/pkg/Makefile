##
## Export all variables to sub-invocation
##
export

MAKE = make  # maybe redefined as gmake for freebsd

OS            = $(shell uname -s)
ERLANG_BIN   ?= $(shell dirname $(shell which erl))

##
## Support RPM and Debian based linux systems
##
ifeq ($(OS),Linux)
ARCH          = $(shell uname -m)
ISAMZ         = $(shell cat /etc/system-release 2> /dev/null)
ISRPM         = $(shell cat /etc/redhat-release 2> /dev/null)
ISAMZ         = $(shell cat /etc/system-release 2> /dev/null)
ISDEB         = $(shell cat /etc/debian_version 2> /dev/null)
ISSLES        = $(shell cat /etc/SuSE-release 2> /dev/null)

ifneq ($(ISAMZ),)
OSNAME        = Amazon
PKGERDIR      = rpm
BUILDDIR      = rpmbuild
else
ifneq ($(ISRPM),)
OSNAME        = RedHat
PKGERDIR      = rpm
BUILDDIR      = rpmbuild
else
ifneq ($(ISDEB),)
OSNAME        = Debian
PKGERDIR      = deb
BUILDDIR      = debuild
else
ifneq ($(ISSLES),)
OSNAME        = SLES
PKGERDIR      = rpm
BUILDDIR      = rpmbuild
endif  # SLES
endif  # deb
endif  # rpm
endif  # amazon
endif  # linux

ifeq ($(OS),Darwin)          # OSX
OSNAME        = OSX
ARCH          = $(shell file `which erlc` | grep -c x86_64 2> /dev/null | awk \
                       '{if ($$1 == "0") {print "i386"} else {print "x86_64"}}')
PKGERDIR      = osx
BUILDDIR      = osxbuild
endif

ifeq ($(OS),FreeBSD)
OSNAME        = FreeBSD
ARCH          = $(shell uname -m)
BUILDDIR      = fbsdbuild
PKGNG         = $(shell uname -r | awk -F. '{ print ($$1 > 9) ? "true" : "false" }')
MAKE          = gmake
PKGERDIR      = fbsdng
endif

DATE          = $(shell date +%Y-%m-%d)

.PHONY: ostype

## Call platform dependent makefile
ostype:
	$(if $(PKGERDIR),,$(error "Operating system '$(OS)' not supported"))
	(cd $(BASE_DIR)/rel/pkg/out && $(MAKE) -f rel/pkg/$(PKGERDIR)/Makefile)
