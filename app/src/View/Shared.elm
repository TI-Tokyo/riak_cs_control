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

module View.Shared exposing
    ( policiesAsList
    , makeDeleteThingConfirmDialog
    )

import Msg exposing (..)
import Model exposing (Model)
import Util

import Html exposing (Html, text, div)
import Html.Attributes exposing (style)
import Material.List as List
import Material.List.Item as ListItem
import Material.Dialog as Dialog
import Material.Button as Button


--policiesAsList : Model -> List String -> String -> Msg -> Html Msg
policiesAsList m pp selected msg =
    let
        selectArg =
            \p ->
                if List.member p selected then
                    Just ListItem.selected
                else
                    Nothing
        element =
            case pp of
                [] ->
                    text "(no policies)"
                p0 :: pn ->
                    List.list List.config
                        (ListItem.listItem
                             (ListItem.config
                             |> ListItem.setSelected (selectArg p0)
                             |> ListItem.setOnClick (msg p0))
                             [ text p0 ])
                        (List.map (\p ->
                                       (ListItem.listItem
                                            (ListItem.config
                                            |> ListItem.setSelected (selectArg p)
                                            |> ListItem.setOnClick (msg p))
                                            [ text p ]))
                             pn)
    in
        div [] [element]




makeDeleteThingConfirmDialog m d g t confirmedMsg notConfirmedMsg =
    case d m.s of
        Just a ->
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose notConfirmedMsg
                  )
                  { title = "Confirm"
                  , content =
                        [ text ("Delete " ++ t ++ " \"" ++ g a ++ "\"?") ]
                  , actions =
                        [ Button.text
                              ( Button.config |> Button.setOnClick notConfirmedMsg
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              )
                              "No"
                        , Button.text
                              ( Button.config
                              |> Button.setOnClick confirmedMsg
                              )
                              "Yes"
                        ]
                  }
            ]
        Nothing ->
            []
