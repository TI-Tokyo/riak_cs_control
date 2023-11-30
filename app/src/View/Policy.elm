module View.Policy exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import View.Common
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, src)
import Html.Events exposing (onClick, onInput)
import Material.Card as Card
import Material.Fab as Fab
import Material.Button as Button
import Material.TextField as TextField
import Material.TextArea as TextArea
import Material.IconButton as IconButton
import Material.Dialog as Dialog
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Typography as Typography
import Iso8601

makeContent m =
    div View.Style.topContent
        [ div View.Style.filterAndSort (makeSubTab m)
        , div View.Style.card (makePolicies m)
        , div [] (createPolicy m)
        , div [] (maybeShowCreatePolicyFab m)
        ]

makeSubTab m =
    let n = View.Common.selectSortByString Name in
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter")
          |> TextField.setValue (Just m.s.policyFilterValue)
          |> TextField.setOnInput PolicyFilterChanged
          )
    , Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.policySortBy))
          |> Select.setOnChange PolicySortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [CreateDate, AttachmentCount])
    , Button.text (Button.config |> Button.setOnClick PolicySortOrderChanged)
            (View.Common.sortOrderText m.s.policySortOrder)
    ]


makePolicies m =
    case m.s.policies |> (filter m) |> (sort m) |> List.map makePolicy of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    List.filter (\a -> String.contains m.s.policyFilterValue a.policyName) aa

sort m aa =
    let
        aa0 =
            case m.s.policySortBy of
                Name -> List.sortBy .policyName aa
                CreateDate -> List.sortWith (Util.compareByPosixTime .createDate) aa
                AttachmentCount -> List.sortBy .attachmentCount aa
                _ -> aa
    in
        if m.s.policySortOrder then aa0 else List.reverse aa0


makePolicy a =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    div View.Style.cardInnerHeader
                    [ text a.policyName ]
              , [ Card.block <|
                      div View.Style.cardInnerContent
                      [ Html.pre [] [ a |> cardContent |> text ] ]
                , Card.block <|
                    div (View.Style.cardInnerContent ++
                                  [ style "scale" "0.8"
                                  , style "background-color" "lightgrey"
                                  , style "border" "thick"
                                  , style "border-radius" "0 0 1em 0"
                                  ])
                        [ Html.pre [] [ a |> cardPolicyDocument |> text ] ]
                ]
              )
        , actions = policyCardActions a
        }

cardContent a =
    "            Arn: " ++ a.arn ++ "\n" ++
    "           Path: " ++ a.path ++ "\n" ++
    "    Description: " ++ (Maybe.withDefault "" a.description) ++ "\n" ++
    "AttachmentCount: " ++ (String.fromInt a.attachmentCount) ++ "\n" ++
    "             Id: " ++ a.policyId ++ "\n" ++
    "        Created: " ++ (Iso8601.fromTime a.createDate)
        ++ Util.maybeTags a.tags "\nTags: "

cardPolicyDocument a =
    (Util.pprintJson a.policyDocument)

policyCardActions a =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeletePolicy a.arn)
                                |> Button.setDisabled (a.attachmentCount > 0)
                                ) "Delete"
                  ]
            , icons = []
            }



maybeShowCreatePolicyFab m =
    if m.s.createPolicyDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreatePolicyDialog
              |> Fab.setAttributes View.Style.createFab
              )
              (Fab.icon "add")
        ]


createPolicy m =
    if m.s.createPolicyDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreatePolicyCancelled
              )
              { title = "New policy"
              , content =
                    [ div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewPolicyNameChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Path")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewPolicyPathChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Description")
                                |> TextField.setOnChange NewPolicyDescriptionChanged
                                )
                          , TextArea.outlined
                                (TextArea.config
                                |> TextArea.setLabel (Just "Policy document")
                                |> TextArea.setRequired True
                                |> TextArea.setOnChange NewPolicyPolicyDocumentChanged
                                |> TextArea.setRows (Just 12)
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreatePolicyCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreatePolicy
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Create"
                    ]
              }
        ]
    else
        []
