-- ---------------------------------------------------------------------
--
-- Copyright (c) 2023 TI Tokyo    All Rights Reserved.
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

module View.General exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common
import View.Style

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style)
import Html.Events exposing (onClick, onInput)
import Material.Card as Card
import Material.Button as Button
import Material.Dialog as Dialog
import Material.TextField as TextField
import Material.Typography as Typography

makeContent m =
    Html.div View.Style.topContent
        [ Html.div [] [ makeServerInfo m ]
        , Html.div [style "width" "max(max-content, 80%)"] (configDialog m)
        ]

makeServerInfo m =
    Html.div [ style "align-content" "center"
             ]
        [ Html.div [ style "width" "min-content" ] [serverInfoDetails m]
        ]

serverInfoDetails m =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    Html.div View.Style.cardInnerHeader
                    [ text "Riak CS node" ]
              , [ Card.block <|
                      Html.div View.Style.cardInnerContent
                      [ Html.pre [] [ m |> cardContent |> text ] ]
                ]
              )
        , actions = cardActions
        }

cardContent m =
    "     Riak CS url: " ++ m.c.csUrl ++ "\n" ++
    "    Admin Key id: " ++ (withStars m.c.csAdminKey) ++ "\n" ++
    "Admin key secret: " ++ (withStars m.c.csAdminSecret) ++ "\n" ++
    "         Version: " ++ m.s.serverInfo.version ++ "\n" ++
    "  System Version: " ++ m.s.serverInfo.systemVersion ++ "\n" ++
    "          Uptime: " ++ m.s.serverInfo.uptime ++ "\n"

withStars s =
    let l = String.length s in
    (String.left 5 s) ++ (String.repeat (l-9) "*") ++ (String.right 4 s)

cardActions =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick ShowConfigDialog
                                ) "Change"
                  ]
            , icons =
                []
            }


configDialog m =
    if m.s.configDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose SetConfigCancelled
              )
              { title = "Riak CS url and admin creds"
              , content =
                    [ Html.div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Url")
                                |> TextField.setValue (Just m.s.newConfigUrl)
                                |> TextField.setOnInput ConfigUrlChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "KeyId")
                                |> TextField.setValue (Just m.s.newConfigKeyId)
                                |> TextField.setOnInput ConfigKeyIdChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "SecretKey")
                                |> TextField.setValue (Just m.s.newConfigSecretKey)
                                |> TextField.setOnInput ConfigSecretKeyChanged
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick SetConfigCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick SetConfig
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Ok"
                    ]
              }
        ]
    else
        []
