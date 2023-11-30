module View.Style exposing (..)

import Html.Attributes exposing (style)
import Material.Typography as Typography

topContent =
    [ style "display" "grid"
    , style "grid-template-columns" "1"
    ]

subTab =
    [ style "align-self" "end"
    , style "align-content" "end"
    , style "padding" "0.1em 0"
    , style "scale" "0.7"
    , style "z-index" "20"
    ]

card =
    [ style "display" "flex"
    , style "flex-wrap" "wrap"
    , style "gap" "1em"
    ]

cardInnerHeader =
    [ style "padding" ".5em .5em 0"
    , style "border-bottom" "solid #cccccc"
    , Typography.headline5
    ]

cardInnerContent =
    [ style "padding" ".5em"
    , style "white-space" "pre"
    , style "font-family" "monospace"
    , style "padding" "1.5em"
    ]

jsonInset =
    [ style "scale" "0.8"
    , style "background-color" "#f5f5f5"
    , style "border" "thick"
    , style "border-radius" "0 0 1em 0"
    , style "font-family" "monospace"
    , style "white-space" "pre"
    ]

createFab =
    [ style "position" "fixed"
    , style "bottom" "2rem"
    , style "right" "2rem"
    ]

filterAndSort =
    [ style "position" "fixed"
    , style "top" "5rem"
    , style "right" "0"
    , style "scale" "0.6"
    , style "opacity" "0.1"
    , style "z-index" "20"
    ]
