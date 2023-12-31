-- ---------------------------------------------------------------------
--
-- Copyright (c) 2023 TI Tokyo    All Rights Reserved.
--
-- This file is provided to you under the Apache License,
-- Version 2.0 (the "License"); you may not use this file
-- except in compliance with the License.  You may obtain
-- a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--
-- ---------------------------------------------------------------------

module View.SAMLProvider exposing (makeContent, makeFilterControls)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
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
import Iso8601

makeContent m =
    div View.Style.topContent
        [ div View.Style.card (makeSAMLProviders m)
        , div [] (createSAMLProvider m)
        , div [] (View.Shared.makeDeleteThingConfirmDialog
                      m .confirmDeleteSAMLProviderDialogShownFor
                      Util.nameFromArn "SAML provider"
                      DeleteSAMLProviderConfirmed DeleteSAMLProviderNotConfirmed)
        , div [] (maybeShowCreateSAMLProviderFab m)
        ]

makeFilterControls m =
    let n = View.Common.selectSortByString Name in
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter")
          |> TextField.setValue (Just m.s.samlProviderFilterValue)
          |> TextField.setOnInput SAMLProviderFilterChanged
          )
    , Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.samlProviderSortBy))
          |> Select.setOnChange SAMLProviderSortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [CreateDate, ValidUntil])
    , Button.text (Button.config |> Button.setOnClick SAMLProviderSortOrderChanged)
            (View.Common.sortOrderText m.s.samlProviderSortOrder)
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
                CreateDate -> List.sortWith (Util.compareByPosixTime .createDate) aa
                ValidUntil -> List.sortWith (Util.compareByPosixTime .validUntil) aa
                _ -> aa
    in
        if m.s.samlProviderSortOrder then aa0 else List.reverse aa0

makeSAMLProvider a =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    div View.Style.cardInnerHeader
                    [ text (Util.nameFromArn a.arn) ]
              , [ Card.block <|
                      div View.Style.cardInnerContent
                      [ Html.pre [] [ a |> cardContent |> text] ]
                , Card.block <|
                    makeIdpMetadata a
                ]
              )
        , actions = samlProviderCardActions a
        }

cardContent a =
    "       Arn: " ++ a.arn ++ "\n" ++
    "CreateDate: " ++ (Iso8601.fromTime a.createDate) ++ "\n" ++
    "ValidUntil: " ++ (Iso8601.fromTime a.validUntil) ++ "\n"
        ++ Util.maybeTags a.tags "\nTags: "

makeIdpMetadata a =
    case a.samlMetadataDocument of
        "" ->
            div [ style "display" "grid"
                , style "align-items" "center"
                , style "justify-content" "center"
                ]
                [ Button.text
                      (Button.config |> Button.setOnClick (GetSAMLProvider a.arn))
                      "Fetch IDP Metadata"
                ]
        d ->
            div View.Style.cardInnerContent
                [ TextArea.outlined
                      (TextArea.config
                      |> TextArea.setLabel (Just "Metadata document")
                      |> TextArea.setValue (Just d)
                      |> TextArea.setCols (Just 77)
                      |> TextArea.setRows (Just 15)
                      |> TextArea.setDisabled True
                      |> TextArea.setAttributes [ attribute "spellCheck" "false" ]
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
                   View.Style.createFab
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
                    [ div [ style "display" "grid"
                          , style "grid-template-columns" "1"
                          , style "row-gap" "0.3em"
                          ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewSAMLProviderNameChanged
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                )
                          , TextArea.outlined
                                (TextArea.config
                                |> TextArea.setLabel (Just "SAML Metadata Document")
                                |> TextArea.setRequired True
                                |> TextArea.setOnChange NewSAMLProviderSAMLMetadataDocumentChanged
                                |> TextArea.setCols (Just 77)
                                |> TextArea.setRows (Just 12)
                                |> TextArea.setAttributes [ attribute "spellCheck" "false" ]
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
