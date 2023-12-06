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
                    { version = "---", systemVersion = "---", uptime = "---" }
                    (not haveCreds) f.csUrl f.csAdminKey f.csAdminSecret
                    -- User
                    "" ["Name", "Email"] Name True
                    False "" "/" "" Nothing False  Nothing
                    -- Policy
                    "" ["Name"] Name True
                    False "" "/" Nothing "" []
                    -- Role
                    "" Name True
                    False "" "/" Nothing "" Nothing 3600 [] Nothing
                    -- SAML Provider
                    "" Name True
                    False "" "" []
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
