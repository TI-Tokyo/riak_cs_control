var path = require('path');
const CopyWebpackPlugin = require("copy-webpack-plugin");
const webpack = { EnvironmentPlugin } = require("webpack");

const destDir = path.resolve(__dirname, "../build");

module.exports = {
    entry: {
        application: [
            "babel-polyfill",
            path.join(__dirname, "../src/index.js")
        ],
        vendor: [
            "bootstrap",
            "@webcomponents/webcomponentsjs/webcomponents-loader",
            "@webcomponents/webcomponentsjs/custom-elements-es5-adapter",
            "web-component"
        ]
    },
    output: {
        filename: "rcsc_ui-[name].js",
        path: destDir,
    },
    module: {
        rules: [
            {
                test: /\.html$/i,
                loader: "file-loader",
            },
            {
                test: /\.(sass|less|css)$/,
                use: ['style-loader', 'css-loader', 'less-loader']
            },
            {
                test: /\.js$/,
                exclude: [ /elm-stuff/, /node_modules/ ],
                use: {
                    loader: "babel-loader"
                },
            },

            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: {
                    loader: "elm-webpack-loader",
                    options: {
                        cwd: "src"
                    }
                }
            }
        ],
        noParse: [/.elm$/]
    },

    plugins: [
        new CopyWebpackPlugin({
            patterns: [
                {
                    from: path.join(__dirname, "../assets/images"),
                    to: "images"
                },
                {
                    from: "./src/index.html",
                    to: "."
                },
                {
                    from: path.join(__dirname, "../assets/favicon.ico"),
                    to: "."
                }
            ]
        }),
        new webpack.EnvironmentPlugin({
            CS_URL: "http://127.0.0.1:8080",
            CS_ADMIN_KEY: "admin-key",
            CS_ADMIN_SECRET: "admin-secret",
            CS_REGION: "us-east-1"
        }),
    ],

    devServer: {
        contentBase: path.join(__dirname, "src"),
        stats: 'errors-only'
    },

};
