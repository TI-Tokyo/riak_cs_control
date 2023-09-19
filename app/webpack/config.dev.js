const path = require("path");
const { merge } = require("webpack-merge");
const webpack = require("webpack");
const config = require("./config.base.js");

module.exports = merge(config, {
    devtool: "nosources-source-map",
    devServer: {
        port: 3003,
    },
    plugins: [
        new webpack.LoaderOptionsPlugin({
            minimize: false
        }),
    ],
    module: {
        noParse: /\.min\.js$/
    }
});
