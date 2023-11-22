module View.SAMLProvider exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import Data.Struct
import View.Common
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
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem


makeContent m =
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle (View.Common.makeSubTab m)
        , Html.div View.Common.cardStyle (makeSAMLProviders m)
        , Html.div [] (createSAMLProvider m)
        , Html.div [] (maybeShowCreateSAMLProviderFab m)
        ]

makeSAMLProviders m =
    case m.s.samlProviders |> filter m |> sort m |> List.map makeSAMLProvider of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    List.filter (\a -> String.contains m.s.samlProviderFilterValue a.name) aa

sort m aa =
    let
        aa0 =
            case m.s.samlProviderSortBy of
                Name -> List.sortBy .name aa
                CreateDate -> List.sortBy .createDate aa
                ValidUntil -> List.sortBy .validUntil aa
                _ -> aa
    in
        if m.s.samlProviderSortOrder then aa0 else List.reverse aa0

makeSAMLProvider a =
    let
        name = String.split "/" a.arn |> List.reverse |> List.head |> Maybe.withDefault "?"
    in
        Card.card Card.config
            { blocks =
                  ( Card.block <|
                        Html.div View.Common.cardInnerHeaderStyle
                        [ text name ]
                  , [ Card.block <|
                          Html.div View.Common.cardInnerContentStyle
                          [ Html.pre [] [ a |> cardContent |> text] ]
                    , Card.block <|
                        makeIdpMetadata a
                    ]
                  )
            , actions = samlProviderCardActions a
            }

cardContent a =
    "               Arn: " ++ a.arn ++ "\n" ++
    "        CreateDate: " ++ a.createDate ++ "\n" ++
    "        ValidUntil: " ++ a.validUntil ++ "\n"
        ++ Util.maybeTags a.tags "\nTags: "

makeIdpMetadata a =
    case a.samlMetadataDocument of
        "" ->
            Html.div [ style "display" "grid"
                     , style "align-items" "center"
                     , style "justify-content" "center"
                     ]
                [ Button.text
                      (Button.config |> Button.setOnClick (GetSAMLProvider a.arn))
                      "IDP Metadata"
                ]
        d ->
            Html.div View.Common.cardInnerContentStyle
                [ TextArea.outlined
                      (TextArea.config
                      |> TextArea.setLabel (Just "Metadata document")
                      |> TextArea.setValue (Just d)
                      |> TextArea.setCols (Just 77)
                      |> TextArea.setRows (Just 15)
                      |> TextArea.setDisabled True
                      |> TextArea.setAttributes []
                      )
                ]

cardMetadataDocument a =
    -- pprint that xml?
    a.samlMetadataDocument


samlProviderCardActions a =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeleteSAMLProvider a.arn)
                                ) "Delete"
                  ]
            , icons = []
            }


maybeShowCreateSAMLProviderFab m =
    if m.s.createSAMLProviderDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreateSAMLProviderDialog
              |> Fab.setAttributes
                   View.Common.createFabStyle
              )
              (Fab.icon "add")
        ]


createSAMLProvider m =
    if m.s.createSAMLProviderDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateSAMLProviderCancelled
              )
              { title = "New SAML provider"
              , content =
                    [ Html.div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewSAMLProviderNameChanged
                                )
                          , TextArea.outlined
                                (TextArea.config
                                |> TextArea.setLabel (Just "SAML Metadata Document")
                                |> TextArea.setRequired True
                                |> TextArea.setOnChange NewSAMLProviderSAMLMetadataDocumentChanged
                                |> TextArea.setRows (Just 12)
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateSAMLProviderCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreateSAMLProvider
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Create"
                    ]
              }
        ]
    else
        []
