REPO		 = riak_cs_control

PKG_REVISION     = $(shell git describe --tags 2>/dev/null)
BASE_DIR         = $(shell pwd)

REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

all: compile

compile:
	@$(MAKE) -C app build

clean:
	@$(MAKE) -C app clean

distclean:
	@$(MAKE) -C distclean

rel: compile
	@rm -rf rel/out
	@mkdir -p rel/out/{www,bin}
	@cp -a app/build/* rel/out/www
	@cp -a bin/riak-cs-control rel/out/bin

.PHONY: all compile clean distclean

export PKG_VERSION BASE_DIR
