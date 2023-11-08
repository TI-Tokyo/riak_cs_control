module View.Usage exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common

import Dict
import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Html.Events exposing (onClick, onInput)
import Material.Button as Button
import Material.IconButton as IconButton
import Material.Typography as Typography
import Chart as C
import Chart.Attributes as CA


makeContent m =
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle (View.Common.makeSubTab m)
        , Html.div [] [makeUsage m]
        ]

makeUsage m =
    let
        data = Dict.toList m.s.usage.stats
             |> List.map (\(k, u) -> { label = k
                                     , bytes = bytesFrom u.storage.samples
                                     })
    in
        C.chart
            [ CA.height 300
            , CA.width 300
            ]
            [ C.grid []
            , C.yLabels [ CA.withGrid ]
            , C.binLabels .label [ CA.moveDown 20 ]
            , C.bars []
                [ C.bar .bytes []
                ]
                data
            ]

bytesFrom ll =
    let
        a = Maybe.withDefault { objects = -1, bytes = -1 } (List.head ll)
    in
        toFloat a.bytes
