module View.Usage exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import View.Common
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


makeContent m =
    div View.Style.topContent
        [ div View.Style.filterAndSort (makeSubTab m)
        , div View.Style.card (makeUsage m)
        ]

makeSubTab m =
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
                                     })
             |> filter m |> sort selector |> packTail m
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
                 { q | packedUsers = a.userName :: q.packedUsers
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
