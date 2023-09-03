export

TAR_VERSION = $(shell git describe --tags)

DEBEMAIL = $(shell git config user.email)

default:
	ln -sf $(BASE_DIR)/rel/pkg/out/$(PKG_ID).tar.gz $(BASE_DIR)/rel/pkg/out/$(TAR_VERSION).orig.tar.gz

	cp -R $(BASE_DIR)/rel/pkg/deb/debian .
	(mkdir -p _build/default/lib && cd _build/default/lib && for d in $(BASE_DIR)/_build/default/lib/*; do ln -fs $$d; done)
	(mkdir -p _build/default/plugins && cd _build/default/plugins && for d in $(BASE_DIR)/_build/default/plugins/*; do ln -fs $$d; done)

	dch  --create --package riak-cs-control -v "$(TAR_VERSION)" \
             "Build from $(PKG_ID)";\
	debuild --prepend-path=$(ERLANG_BIN) \
			-e REVISION=$(PKG_VERSION) \
			-e RELEASE=$(PKG_BUILD) \
		-i -uc -us -b

	mkdir -p $(BASE_DIR)/rel/pkg/out/packages
	cd $(BASE_DIR)/rel/pkg/out && mv *.deb ../out/packages
	cd $(BASE_DIR)/rel/pkg/out/packages && \
		for debfile in *.deb; do \
			sha256sum $${debfile} > $${debfile}.sha \
		; done
