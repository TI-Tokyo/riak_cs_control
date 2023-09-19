module View.DiskUsage exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Html.Events exposing (onClick, onInput)
import Material.Card as Card
import Material.Button as Button
import Material.IconButton as IconButton
import Material.Typography as Typography


makeContent m =
    Html.div [ style "display" "flex"
             , style "flex-flow" "row-reverse wrap"
             ]
        [ makeDiskUsage m
        ]

makeDiskUsage m =
    Html.div []
        [ img [ src "images/wip-man.png"
              , style "object-fit" "contain"
              ] [] ]
