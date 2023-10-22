export

DEBEMAIL = $(shell git config user.email)
YARN     = yarnpkg

default:
	ln -sf $(BASE_DIR)/rel/pkg/out/$(PKG_ID).tar.gz $(BASE_DIR)/rel/pkg/out/$(PKG_VERSION).orig.tar.gz

	cp -R rel/pkg/deb/debian .

	dch  --create --package riak-cs-control -v "$(PKG_VERSION)" \
             "Build from $(PKG_ID)";\
	debuild	-e REVISION=$(PKG_VERSION) \
		-e RELEASE=$(PKG_BUILD) \
		-i -uc -us -b

	mkdir -p $(BASE_DIR)/rel/pkg/packages
	mv ../*.deb ../../packages
	cd $(BASE_DIR)/rel/pkg/packages && \
		for debfile in *.deb; do \
			sha256sum $${debfile} > $${debfile}.sha \
		; done
