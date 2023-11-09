module View.Usage exposing (makeContent)

import Model exposing (Model)
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


makeContent m =
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle ((View.Common.makeSubTab m) ++ (localSubTabElements m))
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
        data = Dict.toList m.s.usage.stats
             |> List.map (\(k, u) -> { label = (Model.userBy m .keyId k) |> .userName
                                     , bytes = bytesFrom u.storage.samples
                                     })
        _ = Debug.log "data" data
    in
        Html.div [] [
             C.chart
                 [ CA.height 3
                 , CA.width 3
                 ]
                 [ C.grid []
                 , C.yLabels [ CA.withGrid ]
                 , C.binLabels .label [ CA.moveDown 20 ]
                 , C.bars []
                     [ C.bar .bytes []
                     ]
                     data
                 ]
            ]

bytesFrom ll =
    let
        a = Maybe.withDefault { objects = -1, bytes = -1 } (List.head ll)
    in
        toFloat a.bytes
