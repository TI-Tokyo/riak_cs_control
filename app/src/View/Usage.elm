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
import Svg.Attributes as SA


makeContent m =
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle (View.Common.makeSubTab m)
        , Html.div [] [makeUsage m]
        ]

localSubTabElements m =
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "From")
          |> TextField.setAttributes [ attribute "spellCheck" "false" ]
          |> TextField.setValue (Just (Iso8601.fromTime m.s.usage.dateFrom))
          |> TextField.setOnInput UsageDateFromChanged
          )
    , TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "To")
          |> TextField.setAttributes [ attribute "spellCheck" "false" ]
          |> TextField.setValue (Just (Iso8601.fromTime m.s.usage.dateTo))
          |> TextField.setOnInput UsageDateToChanged
          )
    ]

makeUsage m =
    let
        byWhich =
            case m.s.usageSortBy of
                -- Name -> .label
                TotalObjectSize -> .bytes
                _ -> .bytes
        maybeReverse =
            if m.s.usageSortOrder then identity else List.reverse

        data = Dict.toList m.s.bucketStats
             |> List.map (\(k, u) -> { label = k
                                     , bytes = toFloat u.totalSize
                                     })
             |> List.sortBy byWhich
             |> maybeReverse
    in
        Html.div [ style "display" "grid"
                 , style "max-height" "500"
                 ]
            [C.chart
                 []
                 [ C.grid []
                 , C.yLabels [ CA.withGrid ]
                 , C.binLabels .label [ CA.moveDown 20 ]
                 , C.bars []
                     [ C.bar .bytes []
                     ]
                     data
                 , C.barLabels [ CA.moveDown 15, CA.color "white" ]
                 ]
            ]

bytesFrom ll =
    let
        a = Maybe.withDefault { objects = -1, bytes = -1 } (List.head ll)
    in
        toFloat a.bytes
