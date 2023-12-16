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

module View.TempSession exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Struct
import View.Common exposing (SortByField(..))
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, src)
import Html.Events exposing (onClick, onInput)
import Material.Card as Card
import Material.Fab as Fab
import Material.Button as Button
import Material.IconButton as IconButton
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.TextField as TextField
import Iso8601
import Time


makeContent m =
    div View.Style.topContent
        [ div View.Style.filterAndSort (makeSubTab m)
        , div View.Style.card (makeTempSessions m)
        ]

makeSubTab m =
    let n = View.Common.selectSortByString Name in
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter")
          |> TextField.setValue (Just m.s.tempSessionFilterValue)
          |> TextField.setOnInput TempSessionFilterChanged
          )
    , Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.tempSessionSortBy))
          |> Select.setOnChange TempSessionSortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [CreateDate, ValidUntil])
    , Button.text (Button.config |> Button.setOnClick TempSessionSortOrderChanged)
            (View.Common.sortOrderText m.s.tempSessionSortOrder)
    ]

makeTempSessions m =
    case m.s.tempSessions |> filter m |> sort m |> List.map makeTempSession of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    List.filter (\a -> String.contains m.s.tempSessionFilterValue a.role.roleName) aa

sort m aa =
    let
        aa0 =
            case m.s.tempSessionSortBy of
                CreateDate -> List.sortWith (Util.compareByPosixTime .created) aa
                _ -> aa
    in
        if m.s.tempSessionSortOrder then aa0 else List.reverse aa0

makeTempSession a =
    let
        name = a.role.roleName
    in
        Card.card Card.config
            { blocks =
                  ( Card.block <|
                        div View.Style.cardInnerHeader [ text name ]
                  , [ Card.block <|
                          div View.Style.cardInnerContent
                          [ a |> cardContent |> text ]
                    , Card.block <|
                        div View.Style.cardInnerContent
                            [ div []
                                  [ "InlinePolicy:" |> text ]
                            , div (View.Style.cardInnerContent ++ View.Style.jsonInset)
                                  [ a |> cardPolicyDocument |> text ]
                            ]
                    ]
                  )
            , actions = tempSessionCardActions a
            }

cardContent a =
    "    Credentials: " ++ a.credentials.accessKeyId ++ ":" ++ a.credentials.secretAccessKey ++ "\n" ++
    "AssumedRoleUser: " ++ a.assumedRoleUser.arn ++ "\n" ++
    "        Created: " ++ (Iso8601.fromTime a.created) ++ "\n" ++
    "DurationSeconds: " ++ (String.fromInt a.durationSeconds) ++ "\n" ++
    "        Expires: " ++ (Iso8601.fromTime a.credentials.expiration)
        ++ Util.maybeItems (List.map Util.nameFromArn a.sessionPolicies) "\nSessionPolicies: "

cardPolicyDocument a =
    Util.pprintJson
        (Maybe.withDefault "" a.role.assumeRolePolicyDocument)


tempSessionCardActions a =
    Just <|
        Card.actions
            { buttons =
                  []
            , icons = []
            }
