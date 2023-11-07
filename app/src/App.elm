module App exposing (init, subscriptions, Flags)

import Model exposing (..)
import Msg exposing (Msg(..))
import Time
import Task
import Material.Snackbar as Snackbar

type alias Flags =
    { csUrl : String
    , csAdminKey : String
    , csAdminSecret : String
    , csRegion : String
    }

init : Flags -> (Model, Cmd Msg)
init f =
    let
        haveCreds = f.csAdminSecret /= "" && f.csAdminKey /= ""
        config = Config f.csUrl f.csAdminKey f.csAdminSecret f.csRegion
        state = State [] [] [] [] {} Snackbar.initialQueue Msg.General
                    { version = "---", systemVersion = "---", uptime = "---" }
                    (not haveCreds) f.csUrl f.csAdminKey f.csAdminSecret
                    "" Name True
                    False "" "/" "" Nothing False Nothing Nothing [] []
                    "" Name True
                    False "" "/" Nothing "" []
                    "" Name True
                    False "" "/" Nothing "" Nothing 3600 []
        model = Model config state (Time.millisToPosix 0)
    in
        ( model
        , Task.perform Tick Time.now
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 1000 Tick
