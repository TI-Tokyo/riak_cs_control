REPO		?= riak_cs_control

HEAD_REVISION   ?= $(shell git describe --tags --exact-match HEAD 2>/dev/null)
PKG_REVISION    ?= $(shell git describe --tags 2>/dev/null)
PKG_BUILD        = 1
BASE_DIR         = $(shell pwd)
ERLANG_BIN       = $(shell dirname $(shell which erl 2>/dev/null) 2>/dev/null)
OTP_VER          = $(shell erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)
REBAR           ?= $(BASE_DIR)/rebar3
REL_DIR         ?= _build/default/rel

.PHONY: rel compile test

## Version and naming variables for distribution and packaging

REPO_TAG 	:= $(shell git describe --tags)

# Split off repo name
# Changes to 1.0.3 or 1.1.0pre1-27-g1170096 from example above
REVISION = $(shell echo $(REPO_TAG) | sed -e 's/^$(REPO)-//')

# Primary version identifier, strip off commmit information
# Changes to 1.0.3 or 1.1.0pre1 from example above
MAJOR_VERSION	?= $(shell echo $(REVISION) | sed -e 's/\([0-9.]*\)-.*/\1/')

PKG_ID := "$(REPO_TAG)-OTP$(OTP_VER)"

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
	@cp -a _build/rel/rel/riak_cs_control rel/

rel-rpm: compile
	@$(REBAR) as rpm release
	@cp -a _build/rpm/rel/riak_cs_control rel/

rel-deb: compile
	@$(REBAR) as deb release
	@cp -a _build/deb/rel/riak_cs_control rel/

rel-fbsdng: compile
	@$(REBAR) as fbsdng release
	@cp -a _build/fbsdng/rel/riak-cs-control rel/

relclean:
	@rm -rf $(REL_DIR)
	@rm -rf rel/riak_cs_control

##
## Packaging targets
##

# Yes another variable, this one is repo-<generatedhash
# which differs from $REVISION that is repo-<commitcount>-<commitsha>
PKG_VERSION = $(shell echo $(PKG_ID) | sed -e 's/^$(REPO)-//')

package:
	mkdir -p rel/pkg/out/riak_cs_control
	git archive --format=tar HEAD | tar -x -C rel/pkg/out/riak_cs_control
	$(MAKE) -f rel/pkg/Makefile

packageclean:
	rm -rf rel/pkg/out/*


.PHONY: package packageclean
export PKG_VERSION PKG_ID PKG_BUILD BASE_DIR ERLANG_BIN REBAR
