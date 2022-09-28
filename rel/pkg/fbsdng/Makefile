export

BUILDDIR        = $(shell pwd)
BUILD_STAGE_DIR = $(BUILDDIR)/riak_cs_control

# Where we install things (based on vars.config)
# /usr/local based dirs
PMAN_DIR         = $(BUILD_STAGE_DIR)/usr/local/man
PBIN_DIR         = $(BUILD_STAGE_DIR)/usr/local/lib/riak_cs_control/bin
PLIB_DIR         = $(BUILD_STAGE_DIR)/usr/local/lib/riak_cs_control
PUSRBIN_DIR      = $(BUILD_STAGE_DIR)/usr/local/bin
# /var based dirs
PLOG_DIR         = $(BUILD_STAGE_DIR)/var/log/riak_cs_control

PKGNAME = $(PKG_VERSION)-$(OSNAME)-$(ARCH).tbz
PKG_SHORT_VERSION = $(PKG_VERSION)

# Recursive assignment of ERTS version
# We will know this after building the rel
ERTS_PATH = $(shell ls $(BUILDDIR)/rel/riak_cs_control | egrep -o "erts-.*")

build: packing_list_files
	@echo "Building package $(PKGNAME)"

	cd $(BUILD_STAGE_DIR) && \
	mkdir ../../../out/packages && \
	pkg create -m . -r . -o ../../../out/packages

	cd ../../out/packages && \
		for f in *.pkg; do \
		shasum -a 256 $${f} > $${f}.sha \
	; done

packing_list_files: $(BUILD_STAGE_DIR)
	@mv ${BUILDDIR}/rel/pkg/fbsdng/+MANIFEST ${BUILD_STAGE_DIR}
	sed -e "s/%ERTS_PATH%/${ERTS_PATH}/" < \
	        ${BUILDDIR}/rel/pkg/fbsdng/rc.d > \
	        ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak_cs_control
	chmod -w ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak_cs_control
	chmod +x ${BUILD_STAGE_DIR}/usr/local/etc/rc.d/riak_cs_control
	@cd $(BUILD_STAGE_DIR) && \
	        echo "version: \"${PKG_SHORT_VERSION}\"" >> +MANIFEST && \
	        echo "files: {" >> +MANIFEST

	@echo "Copying Man pages to staging directory"
	@cd $(BUILDDIR) && \
	if [ -d doc/man/man1 ]; then \
		mkdir -p $(PMAN_DIR) && \
		cp -R doc/man/man1 $(PMAN_DIR); fi

	@echo "Packaging /usr/local files"
	@cd $(BUILD_STAGE_DIR) && \
	find usr -type f | while read file ; do \
	    mode=$$(stat -f%p "$$file" | cut -c 3-) && \
	    sum=$$(sha256 -q $$file) && \
			echo "  \"/$$file\": { sum: \"$$sum\", perm: \"$$mode\", uname: \"root\", gname: \"wheel\" }," >> +MANIFEST; done && \
		sed -i .bak '$$s/,$$//' +MANIFEST && \
		rm -- +MANIFEST.bak && \
		echo " }" >> +MANIFEST

	@cd $(BUILD_STAGE_DIR) && \
		echo "directories: {" >> +MANIFEST && \
		echo "  /usr/local/lib/riak_cs_control: \"y\"," >> +MANIFEST && \
		echo "  /usr/local/var/lib/riak_cs_control: \"y\"," >> +MANIFEST && \
		echo " }" >> +MANIFEST

# Copy the app rel directory to the staging directory to build our
# package structure and move the directories into the right place
# for the package, see the vars.config file for destination
# directories
$(BUILD_STAGE_DIR): buildrel
	@echo "Copying rel directory to staging directory"
	mkdir -p $@
	mkdir -p $(PBIN_DIR) $(PUSRBIN_DIR)
	cp -R rel/riak_cs_control/bin/riak_cs_control $(PUSRBIN_DIR)
	cp -R rel/riak_cs_control/bin $(PLIB_DIR);
	mkdir -p $(PLIB_DIR)
	cp -R rel/riak_cs_control/lib $(PLIB_DIR)
	cp -R rel/riak_cs_control/share $(PLIB_DIR)
	cp -R rel/riak_cs_control/erts-* $(PLIB_DIR)
	(cd $(PLIB_DIR) && ln -s erts-* erts)
	cp -R rel/riak_cs_control/releases $(PLIB_DIR)
	mkdir -p ${BUILD_STAGE_DIR}/usr/local/etc/rc.d

# Build the release we need to package
#  * Ensure all binaries are executable
#  * copy the vars.config over for build config
buildrel:
	tar -xf $(BASE_DIR)/rel/pkg/out/$(PKG_ID).tar.gz -C $(BASE_DIR)/rel/pkg/out/$(PKG_ID)
	$(MAKE) -C $(BASE_DIR)/rel/pkg/out/$(PKG_ID) rel-fbsdng
	rm -rf rel/riak_cs_control/lib/*/c_src rel/riak_cs_control/lib/*/src
	chmod 0755 rel/riak_cs_control/bin/* rel/riak_cs_control/erts-*/bin/*

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
