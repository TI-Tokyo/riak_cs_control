REPO		 = riak_cs_control

PKG_VERSION      = $(shell git describe --tags 2>/dev/null)
PKG_ID           = riak_cs_control-$(PKG_VERSION)
BASE_DIR         = $(shell pwd)

REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

all: compile

compile:
	@$(MAKE) -C app build

clean:
	@$(MAKE) -C app clean

rel: compile
	@rm -rf rel/out || :
	@mkdir -p rel/out/www rel/out/bin
	@cp -a app/build/* rel/out/www
	@cp -a bin/riak-cs-control rel/out/bin

package:
	rm -rf rel/pkg/out
	mkdir -p rel/pkg/out/$(PKG_ID)
	git archive --format=tar HEAD | gzip >rel/pkg/out/$(PKG_ID).tar.gz
	$(MAKE) -f rel/pkg/Makefile


.PHONY: all compile clean distclean

export PKG_VERSION PKG_ID BASE_DIR
