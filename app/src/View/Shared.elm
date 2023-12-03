module View.Shared exposing (policiesAsList)

import Msg exposing (..)
import Model exposing (Model)
import Util

import Html exposing (Html, text, div)
import Html.Attributes exposing (style)
import Material.List as List
import Material.List.Item as ListItem


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

