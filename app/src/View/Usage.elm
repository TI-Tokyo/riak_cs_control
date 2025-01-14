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

module View.Usage exposing (makeContent, makeFilterControls)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
import View.Style
import Util

import Dict
import Iso8601
import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Html.Events exposing (onClick, onInput)
import Material.Button as Button
import Material.TextField as TextField
import Material.IconButton as IconButton
import Material.Typography as Typography
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Item as CI
import Svg.Attributes as SA
import Material.Card as Card
import Filesize
import Numeral


makeContent m =
    div View.Style.topContent
        [ div [ style "align" "center"
              , style "background-color" "yellow"
              , style "font-family" "monospace"
              , style "font-size" "small"
              , style "white-space" "pre"
              , style "padding" "1em"
              ] [text (makeStorageInfo m)]
        , div View.Style.card (makeUsage m)
        ]

makeStorageInfo m =
    String.join "\n" (List.map makeNodeStorageInfo m.s.serverInfo.storageInfo)
makeNodeStorageInfo a =
    let
        used_pc = 100 - a.dfAvailable * 100 // a.dfTotal
    in
        a.node ++ ": total " ++ (Numeral.format "000,00 b" (1024 * toFloat a.dfTotal))
            ++ ", SST total " ++ (Numeral.format "000,00 b" (toFloat a.backendDataTotalSize))
            ++ ", available " ++ (Numeral.format "000,00 b" (1024 * toFloat a.dfAvailable))
            ++ " (" ++ (String.fromInt used_pc) ++ "% used)"



makeFilterControls m =
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter")
          |> TextField.setValue (Just m.s.usageFilterValue)
          |> TextField.setOnInput UsageFilterChanged
          )
    , TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Top items to show")
          |> TextField.setType (Just "number")
          |> TextField.setValue (Just (String.fromInt m.s.usageTopItemsShown))
          |> TextField.setOnInput UsageTopItemsShownChanged
          )
    ]


makeUsage m =
    [ encard [makeChart m .totalObjectSize "#211892" toKMG ] "Total object size"
    , encard [makeChart m .totalObjectCount "#7a1892" String.fromFloat ] "Object count"
    , encard [makeChart m .totalBucketCount "#163506" String.fromFloat ] "Bucket count"
    ]

encard content title =
    div [ style "flex" "0 55em" ]
        [ Card.card Card.config
              { blocks =
                    ( Card.block <|
                          div View.Style.cardInnerHeader
                          [ text title ]
                    , [ Card.block <|
                            div (View.Style.cardInnerContent) content
                      ]
                    )
              , actions = Nothing
              }
        ]

makeChart m selector color yTicksFmt =
    let
        data = Dict.toList m.s.bucketStats
             |> List.map (\(k, u) -> { userName = Util.ellipsize k 7
                                     , totalObjectSize = toFloat u.totalObjectSize
                                     , totalObjectCount = toFloat u.totalObjectCount
                                     , totalBucketCount = toFloat u.totalBucketCount
                                     , packed = False
                                     , packedUsers = []
                                     , barStart = -1.1
                                     , barEnd = -1.1
                                     })
             |> filter m |> sort selector |> packTail m |> setBarWidths
    in
        div []
            [ C.chart
                  [ CA.height 220
                  , CA.width 500
                  , CA.padding
                        { top = 50
                        , bottom = 20
                        , left = 70
                        , right = 50
                        }
                  , CA.margin
                        { top = 20
                        , bottom = 10
                        , left = 20
                        , right = 20
                        }
                  , CA.domain [ CA.lowest 0 CA.exactly ]
                  ]
                  [ C.grid []
                  , C.yTicks [ CA.amount 3
                             , CA.ints
                             ]
                  , C.yLabels [ CA.withGrid
                              , CA.ints
                              , CA.format yTicksFmt
                              ]
                  , C.binLabels .userName [ CA.moveDown 20 ]
                  , C.bars [ CA.roundTop 0.1
                           , CA.margin 0.8
                           , CA.x1 .barStart
                           , CA.x2 .barEnd
                           ]
                      [ C.bar selector [ CA.color color ]
                      ]
                  data
                  ]
            ]

toKMG a =
    a |> round |> Filesize.format

makeLabel a selector =
    let d = CI.getData a in
    selector |> d |> String.fromFloat

filter m uu =
    List.filter (\u -> String.contains m.s.usageFilterValue u.userName) uu

sort selector aa =
    List.sortBy selector aa |> List.reverse

packTail m aa =
    let
        shown = List.take m.s.usageTopItemsShown aa
        packedBin = List.drop m.s.usageTopItemsShown aa |> packBin
    in
        if (List.length aa) - m.s.usageTopItemsShown > 1 then
            List.append shown [{packedBin | userName = relabelPackedBin (List.length packedBin.packedUsers)}]
        else
            aa

setBarWidths aa =
    List.foldl
        (\a q ->
             let
                 p = List.length q
                 b = if a.packed then
                         {a | barStart = (toFloat p), barEnd = (toFloat p) + 1.5}
                     else
                         {a | barStart = (toFloat p), barEnd = (toFloat p) + 1.0}
             in
                 b :: q
        ) [] aa

relabelPackedBin s =
    (s |> String.fromInt) ++ " more"

packBin aa =
    List.foldl
        (\a q ->
             let
                 t1 = q.totalObjectSize + a.totalObjectSize
                 t2 = q.totalObjectCount + a.totalObjectCount
                 t3 = q.totalBucketCount + a.totalBucketCount
             in
                 { q
                 | packedUsers = a.userName :: q.packedUsers
                 , totalObjectSize = t1
                 , totalObjectCount = t2
                 , totalBucketCount = t3
                 }
        )
        { totalObjectSize = 0
        , totalObjectCount = 0
        , totalBucketCount = 0
        , packed = True
        , userName = ""
        , packedUsers = []
        , barStart = -1.1
        , barEnd = -1.1
        }
        aa


-- bytesFrom ll =
--     let
--         a = Maybe.withDefault { objects = -1, bytes = -1 } (List.head ll)
--     in
--         toFloat a.bytes
-- localSubTabElements m =
--     [ TextField.outlined
--           (TextField.config
--           |> TextField.setLabel (Just "From")
--           |> TextField.setAttributes [ attribute "spellCheck" "false" ]
--           |> TextField.setValue (Just (Iso8601.fromTime m.s.usage.dateFrom))
--           |> TextField.setOnInput UsageDateFromChanged
--           )
--     , TextField.outlined
--           (TextField.config
--           |> TextField.setLabel (Just "To")
--           |> TextField.setAttributes [ attribute "spellCheck" "false" ]
--           |> TextField.setValue (Just (Iso8601.fromTime m.s.usage.dateTo))
--           |> TextField.setOnInput UsageDateToChanged
--           )
--     ]
