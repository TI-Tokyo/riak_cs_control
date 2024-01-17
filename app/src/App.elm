-- ---------------------------------------------------------------------
--
-- Copyright (c) 2023-2024 TI Tokyo    All Rights Reserved.
--
-- This file is provided to you under the Apache License,
-- Version 2.0 (the "License"); you may not use this file
-- except in compliance with the License.  You may obtain
-- a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--
-- ---------------------------------------------------------------------

module App exposing (init, subscriptions, Flags)

import Model exposing (..)
import Data.Struct
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))

import Time
import Dict exposing (Dict)
import Task
import Material.Snackbar as Snackbar

type alias Flags =
    { csUrl : String
    , csAdminKey : String
    , csAdminSecret : String
    , csRegion : String
    }

-- emptyUsage =
--     Data.Struct.Usage (Time.millisToPosix 0) (Time.millisToPosix 0) Dict.empty


init : Flags -> (Model, Cmd Msg)
init f =
    let
        haveCreds = f.csAdminSecret /= "" && f.csAdminKey /= ""
        config = Config f.csUrl f.csAdminKey f.csAdminSecret f.csRegion
        state = State
                    [] [] [] [] [] Dict.empty
                    Snackbar.initialQueue Msg.General True
                    { version = "---", systemVersion = "---", uptime = "---", storageInfo = [] }
                    (not haveCreds) f.csUrl f.csAdminKey f.csAdminSecret
                    -- User
                    "" ["Name", "Email"] Name True
                    False "" "/" "" Nothing False  Nothing Nothing
                    -- Policy
                    "" ["Name"] Name True
                    False "" "/" Nothing "" [] Nothing
                    -- Role
                    "" Name True
                    False "" "/" Nothing "" Nothing 3600 [] Nothing Nothing
                    -- SAML Provider
                    "" Name True
                    False "" "" [] Nothing
                    -- temp sessions
                    "" CreateDate True
                    "" 8
                    -- attach policy dialog
                    Nothing [] []
        model = Model config state (Time.millisToPosix 0)
    in
        ( model
        , Task.perform Tick Time.now
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick
