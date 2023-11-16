module View.Usage exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import View.Common

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
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle (View.Common.makeSubTab m)
        , Html.div [ style "display" "flex"
                   , style "flex-wrap" "wrap"
                   , style "gap" "2em"
                   ] (makeUsage m)
        ]

makeUsage m =
    let
        data = Dict.toList m.s.bucketStats
             |> List.map (\(k, u) -> { userName = k
                                     , totalObjectSize = toFloat u.totalObjectSize
                                     , totalObjectCount = toFloat u.totalObjectCount
                                     , totalBucketCount = toFloat u.totalBucketCount
                                     })
             |> filter m |> sort m
    in
        [ encard [makeChart m .totalBucketCount data "#163506" String.fromFloat ] "Bucket count"
        , encard [makeChart m .totalObjectCount data "#7a1892" String.fromFloat ] "Object count"
        , encard [makeChart m .totalObjectSize data "#211892" toKMG ] "Total object size"
        ]

encard content title =
    Html.div [ style "flex" "0 35em" ]
        [ Card.card Card.config
              { blocks =
                    ( Card.block <|
                          Html.div View.Common.cardInnerHeaderStyle
                          [ text title ]
                    , [ Card.block <|
                            Html.div (View.Common.cardInnerContentStyle) content
                      ]
                    )
              , actions = Nothing
              }
        ]

makeChart m selector data color yTicksFmt =
    Html.div []
        [ C.chart
              [ CA.width 500
              , CA.padding { top = 50
                           , bottom = 50
                           , left = 70
                           , right = 50
                           }
              , CA.margin { top = 20
                          , bottom = 10
                          , left = 20
                          , right = 20
                          }
              ]
              [ C.grid []
              , C.yTicks [ CA.amount 3
                         , CA.ints
                         , CA.limits
                               [ CA.lowest 0 CA.exactly
                               ]
                         ]
              , C.yLabels [ CA.withGrid
                          , CA.ints
                          , CA.format yTicksFmt
                          ]
              , C.binLabels .userName [ CA.moveDown 20 ]
              , C.bars [ CA.margin 0.8 ]
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

sort m aa =
    let
        aa0 =
            case m.s.usageSortBy of
                Name -> List.sortBy .userName aa
                TotalObjectSize -> List.sortBy .totalObjectSize aa
                TotalObjectCount -> List.sortBy .totalObjectCount aa
                TotalBucketCount -> List.sortBy .totalBucketCount aa
                _ -> aa
    in
        if m.s.usageSortOrder then aa0 else List.reverse aa0


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
