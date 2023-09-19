all: build

WWW_DEST = build

clean:
	rm -rf $(WWW_DEST)/*

deps:
	@yarn add -D parcel elm webpack elm-webpack-loader \
	  html-webpack-plugin copy-webpack-plugin \
	  html-loader postcss webpack-merge \
	  @webcomponents/webcomponentsjs \
	  bootstrap \
	  @popperjs/core \
	  web-component \
	  babel-loader

build: deps
	@mkdir -p $(WWW_DEST)
	yarn run build

.PHONY: clean deps build
