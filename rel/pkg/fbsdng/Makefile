export

BUILDDIR        = $(shell pwd)
MOTHERTOPDIR    = $(BUILDDIR)/../../../..
BUILD_STAGE_DIR = $(BUILDDIR)/$(PKG_ID)

# Where we install things (based on vars.config)
# /usr/local based dirs
PMAN_DIR         = $(BUILD_STAGE_DIR)/usr/local/man
PBIN_DIR         = $(BUILD_STAGE_DIR)/usr/local/lib/riak-cs-control/bin
PLIB_DIR         = $(BUILD_STAGE_DIR)/usr/local/lib/riak-cs-control
PRUN_DIR         = $(BUILD_STAGE_DIR)/run/riak-cs-control
PETC_DIR         = $(BUILD_STAGE_DIR)/usr/local/etc/riak-cs-control
# /var based dirs
PVAR_DIR         = $(BUILD_STAGE_DIR)/usr/local/var/lib/riak-cs-control
PLOG_DIR         = $(BUILD_STAGE_DIR)/var/log/riak-cs-control

PKGNAME = $(PKG_VERSION)-$(OSNAME)-$(ARCH).tbz
PKG_SHORT_VERSION = $(PKG_VERSION)

# Recursive assignment of ERTS version
# We will know this after building the rel
ERTS_PATH = $(shell ls $(BUILDDIR)/rel/riak-cs-control | ggrep -E -o "erts-.*")

build: link_deps packing_list_files
	@echo "Building package $(PKGNAME)"

	cd $(BUILD_STAGE_DIR) && \
	mkdir ../../../out/packages && \
	pkg create -m . -r . -o ../../../out/packages

	cd ../../out/packages && \
		for f in *.pkg; do \
		shasum -a 256 $${f} > $${f}.sha \
	; done

link_deps:
	(cd $(BUILDDIR) && \
	  (mkdir -p _build/default/lib && \
	    cd _build/default/lib && for d in $(MOTHERTOPDIR)/_build/default/lib/*; do ln -s $$d; done) && \
	  (mkdir -p _build/default/plugins && \
	    cd _build/default/plugins && for d in $(MOTHERTOPDIR)/_build/default/plugins/*; do ln -s $$d; done) \
	)

packing_list_files: $(BUILD_STAGE_DIR)
	mv ${BUILDDIR}/rel/pkg/fbsdng/+MANIFEST ${BUILD_STAGE_DIR}
	sed -e "s/%ERTS_PATH%/${ERTS_PATH}/" < \
	        ${BUILDDIR}/rel/pkg/fbsdng/rc.d > \
	        ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak-cs-control
	chmod -w ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak-cs-control
	chmod +x ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak-cs-control
	cd $(BUILD_STAGE_DIR) && \
	        echo "version: \"${PKG_SHORT_VERSION}\"" >> +MANIFEST && \
	        echo "files: {" >> +MANIFEST

	@echo "Copying Man pages to staging directory"
	cd $(BUILDDIR) && \
	if [ -d doc/man/man1 ]; then \
		mkdir -p $(PMAN_DIR) && \
		cp -R doc/man/man1 $(PMAN_DIR); fi

	@echo "Packaging /usr/local files"
	cd $(BUILD_STAGE_DIR) && \
	find usr -type f | while read file ; do \
	    mode=$$(stat -f%p "$$file" | cut -c 3-) && \
	    sum=$$(sha256 -q $$file) && \
			echo "  \"/$$file\": { sum: \"$$sum\", perm: \"$$mode\", uname: \"root\", gname: \"wheel\" }," >> +MANIFEST; done && \
		sed -i .bak '$$s/,$$//' +MANIFEST && \
		rm -- +MANIFEST.bak && \
		echo " }" >> +MANIFEST

	cd $(BUILD_STAGE_DIR) && \
		echo "directories: {" >> +MANIFEST && \
		echo "  /usr/local/etc/riak-cs-control: \"y\"," >> +MANIFEST && \
		echo "  /usr/local/lib/riak-cs-control: \"y\"," >> +MANIFEST && \
		echo "  /usr/local/var/lib/riak-cs-control: \"y\"," >> +MANIFEST && \
		echo "  /run/riak-cs-control: \"y\"," >> +MANIFEST && \
		echo "  /var/log/riak-cs-control: \"y\"," >> +MANIFEST && \
		echo " }" >> +MANIFEST

# Copy the app rel directory to the staging directory to build our
# package structure and move the directories into the right place
# for the package, see the vars.config file for destination
# directories
$(BUILD_STAGE_DIR): buildrel
	@echo "Copying rel directory to staging directory"
	mkdir -p $@
	mkdir -p $(PBIN_DIR) $(PVAR_DIR) $(PRUN_DIR) $(PLOG_DIR)
	cp -R rel/riak-cs-control/bin $(PLIB_DIR);
	mkdir -p $(PLIB_DIR)
	cp -R rel/riak-cs-control/lib $(PLIB_DIR)
	cp -R rel/riak-cs-control/erts-* $(PLIB_DIR)
	(cd $(PLIB_DIR) && ln -s erts-* erts)
	mkdir -p ${BUILD_STAGE_DIR}/usr/local/etc/rc.d
	mkdir -p ${BUILD_STAGE_DIR}/usr/local/etc/riak-cs-control
	cp rel/riak-cs-control/etc/config $(PETC_DIR)
	cp -R rel/riak-cs-control/releases $(PVAR_DIR)

# Build the release we need to package
#  * Ensure all binaries are executable
#  * copy the vars.config over for build config
buildrel:
	$(MAKE) rel-fbsdng
	rm -rf rel/riak-cs-control/lib/*/c_src rel/riak-cs-control/lib/*/src
	chmod 0755 rel/riak-cs-control/bin/* rel/riak-cs-control/erts-*/bin/*

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
