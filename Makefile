REPO		?= riak_cs_control

HEAD_REVISION   ?= $(shell git describe --tags --exact-match HEAD 2>/dev/null)
PKG_REVISION    ?= $(shell git describe --tags 2>/dev/null)
PKG_BUILD        = 1
BASE_DIR         = $(shell pwd)
ERLANG_BIN       = $(shell dirname $(shell which erl 2>/dev/null) 2>/dev/null)
OTP_VER          = $(shell erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)
REBAR           ?= $(BASE_DIR)/rebar3
OVERLAY_VARS    ?=
REL_DIR         ?= _build/default/rel

.PHONY: rel compile test

all: compile

compile:
	@$(REBAR) compile

clean:
	@$(REBAR) clean

distclean:
	@$(REBAR) clean -a
	@rm -rf _build

test: all
	@$(REBAR) eunit

##
## Developer targets
##
.PHONY : stage

stage : rel
	$(foreach app,$(wildcard apps/*),               rm -rf rel/riak_cs_control/lib/$(shell basename $(app))* && ln -sf $(abspath $(app)) rel/riak_cs_control/lib;)
	$(foreach dep,$(wildcard _build/default/lib/*), rm -rf rel/riak_cs_control/lib/$(shell basename $(dep))* && ln -sf $(abspath $(dep)) rel/riak_cs_control/lib;)

##
## Doc targets
##
docs:
	@$(REBAR) edoc

dialyzer: compile
	@$(REBAR) dialyzer

##
## Release targets
##
rel: compile
	@$(REBAR) as rel release
# freebsd tar won't write to stdout, so:
	@tar  -c -f rel.tar --exclude '*/.git/*' -C _build/rel/rel riak_cs_control && tar -x -f rel.tar -C rel && rm rel.tar

rel-rpm: compile
	@$(REBAR) as rpm release
	@tar --exclude-vcs -c -C _build/rpm/rel riak_cs_control | tar -x -C rel

rel-deb: compile
	@$(REBAR) as deb release
	@tar --exclude-vcs -c -C _build/deb/rel riak_cs_control | tar -x -C rel

rel-osx: compile
	@$(REBAR) as osx release
	@tar --exclude-vcs -c -C _build/osx/rel riak_cs_control | tar -x -C rel

# this one is to be called from an external make (not from rel/pkg/Makefile)
rel-alpine: compile
	@$(REBAR) as alpine release
	@tar --exclude-vcs -c -C _build/alpine/rel riak_cs_control | tar -x -C rel

rel-fbsdng: compile
	@$(REBAR) as fbsdng release
	@tar  -c -f rel.tar --exclude '*/.git/*' -C _build/fbsdng/rel riak_cs_control && tar -x -f rel.tar -C rel && rm rel.tar

rel-docker: compile relclean
	REBAR_CONFIG=rebar.docker.config $(REBAR) release
	cp -a _build/default/rel/riak_cs_control rel/

relclean:
	@rm -rf $(REL_DIR)
	@rm -rf rel/riak_cs_control

##
## Version and naming variables for distribution and packaging
##

REPO_TAG 	:= $(shell git describe --tags)

# Split off repo name
# Changes to 1.0.3 or 1.1.0pre1-27-g1170096 from example above
REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

# Primary version identifier, strip off commmit information
# Changes to 1.0.3 or 1.1.0pre1 from example above
MAJOR_VERSION	?= $(shell echo $(REVISION) | sed -e 's/\([0-9.]*\)-.*/\1/')

PKG_ID := "$(REPO_TAG)-OTP$(OTP_VER)"

##
## Packaging targets
##

# Yes another variable, this one is repo-<generatedhash
# which differs from $REVISION that is repo-<commitcount>-<commitsha>
PKG_VERSION = $(shell echo $(PKG_ID) | sed -e 's/^$(REPO)-//')

package:
	mkdir -p rel/pkg/out/riak-$(PKG_ID)
	git archive --format=tar HEAD | gzip >rel/pkg/out/$(PKG_ID).tar.gz
	$(MAKE) -f rel/pkg/Makefile

packageclean:
	rm -rf rel/pkg/out/*


.PHONY: package
export PKG_VERSION PKG_ID PKG_BUILD BASE_DIR ERLANG_BIN REBAR OVERLAY_VARS

# Package up a devrel to save time later rebuilding it
pkg-devrel: devrel
	echo -n $(PKG_REVISION) > VERSION
	tar -czf $(PKG_ID)-devrel.tar.gz dev/ VERSION
	rm -rf VERSION

pkg-rel: rel
	tar -czf $(PKG_ID)-rel.tar.gz -C rel/ .
