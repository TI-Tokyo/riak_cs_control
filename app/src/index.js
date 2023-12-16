// ---------------------------------------------------------------------
//
// Copyright (c) 2023 TI Tokyo    All Rights Reserved.
//
// This file is provided to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file
// except in compliance with the License.  You may obtain
// a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
// ---------------------------------------------------------------------

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
