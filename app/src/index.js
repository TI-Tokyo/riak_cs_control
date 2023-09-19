'use strict';

require("./index.html");

const { Elm } = require("./Main.elm");
const app = Elm.Main.init({
    node: document.getElementById('root'),
    flags: {
        csUrl: process.env.CS_URL || "http://127.0.0.1:8080",
        csAdminKey: process.env.CS_ADMIN_KEY || "admin-key",
        csAdminSecret: process.env.CS_ADMIN_SECRET || "admin-ecret",
        csRegion: process.env.CS_REGION || "us-east-1"
    }
});
