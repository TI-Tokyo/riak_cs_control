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

module View.User exposing (makeContent, makeFilterControls)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Struct
import View.Common exposing (SortByField(..))
import View.Shared exposing (policiesAsList)
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, src)
import Material.Card as Card
import Material.Fab as Fab
import Material.Button as Button
import Material.IconButton as IconButton
import Material.TextField as TextField
import Material.Dialog as Dialog
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.List as List
import Material.List.Item as ListItem
import Material.Switch as Switch
import Material.Checkbox as Checkbox
import Material.Chip.Filter as FilterChip
import Material.ChipSet.Filter as FilterChipSet
import Iso8601


makeContent m =
    div View.Style.topContent
        [ div View.Style.card (makeUsers m)
        , div [] (makeCreateUserDialog m)
        , div [] (makeEditUserDialog m)
        , div [] (makeEditUserPoliciesDialog m)
        , div [] (makeAttachUserPolicyDialog m)
        , div [] (maybeShowCreateUserFab m)
        ]

makeFilterControls m =
    let n = View.Common.selectSortByString Name in
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter by")
          |> TextField.setValue (Just m.s.userFilterValue)
          |> TextField.setOnInput UserFilterChanged
          )
    , makeFilterChips m
    , Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.userSortBy))
          |> Select.setOnChange UserSortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [Email, CreateDate, BucketCount])
    , Button.text (Button.config |> Button.setOnClick UserSortOrderChanged)
            (View.Common.sortOrderText m.s.userSortOrder)
    ]


makeFilterChips m =
    let
        first = FilterChip.chip
                (FilterChip.config
                |> FilterChip.setSelected (List.member "Name" m.s.userFilterIn)
                |> FilterChip.setOnChange (UserFilterInItemClicked "Name")
                ) "Name"
        rest =
            List.map
                (\n ->
                     FilterChip.chip
                       (FilterChip.config
                       |> FilterChip.setSelected (List.member n m.s.userFilterIn)
                       |> FilterChip.setOnChange (UserFilterInItemClicked n)
                       )
                       n
                )
            ["Email", "Arn"]
    in
        FilterChipSet.chipSet [] first rest

makeUsers m =
    case m.s.users |> (filter m) |> (sort m) |> List.map (makeUser m) of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m uu =
    case m.s.userFilterValue of
        "" -> uu
        s ->
            List.filter
                (\u ->
                     (  (List.member "Name" m.s.userFilterIn && String.contains s u.userName)
                     || (List.member "Email" m.s.userFilterIn && String.contains s u.email)
                     || (List.member "Arn" m.s.userFilterIn && String.contains s u.arn)
                     )
                ) uu

sort m aa =
    let
        aa0 =
            case m.s.userSortBy of
                Name -> List.sortBy .userName aa
                CreateDate -> List.sortWith (Util.compareByPosixTime .createDate) aa
                BucketCount -> List.sortWith (\u1 u2 ->
                                                  case List.length u1.buckets < List.length u2.buckets of
                                                      True -> LT
                                                      False -> GT
                                             ) aa
                _ -> aa
    in
        if m.s.userSortOrder then aa0 else List.reverse aa0


makeUser m u =
    let
        maybeDisabled =
            if u.status == "enabled" then
                ""
            else
                " (disabled)"
    in
        div []
            [ Card.card Card.config
                 { blocks =
                       ( Card.block <|
                             div View.Style.cardInnerHeader
                             [ text (u.userName ++ maybeDisabled)]
                       , [ Card.block <|
                               div (View.Style.cardInnerContent ++ (isEnabledStyle u))
                               [ u |> cardContent |> text
                               , div [ Typography.body2 ]
                                   [ text (userBucketsDetail u) ]
                               , div [ Typography.body2 ]
                                   [ text (userPoliciesDetail u) ]
                               ]
                         ]
                       )
                 , actions = userCardActions m u
                }
            ]

isEnabledStyle {status} =
    if status == "disabled" then
        [ style "color" "grey" ]
    else
        []

cardContent u =
    "      Arn: " ++ u.arn ++ "\n" ++
    "     Path: " ++ u.path ++ "\n" ++
    "    Email: " ++ u.email ++ "\n" ++
    "  Created: " ++ (Iso8601.fromTime u.createDate) ++ "\n" ++
    "    KeyId: " ++ u.keyId ++ "\n" ++
    "SecretKey: " ++ u.secretKey ++ "\n" ++
    "       Id: " ++ u.userId
        ++ Util.maybeTags u.tags "\nTags: "

userCardActions m u =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeleteUser u.keyId)
                                |> Button.setDisabled ((isAdmin m u) || (0 < List.length u.attachedPolicies))
                                ) "Delete"
                  , Card.button (Button.config
                                |> Button.setOnClick (ShowEditUserDialog u)
                                |> Button.setDisabled (isAdmin m u)
                                ) "Edit"
                  , Card.button (Button.config
                                |> Button.setOnClick (ShowEditUserPoliciesDialog u.arn)
                                |> Button.setDisabled (isAdmin m u)
                                ) "Policies"
                  ]
            , icons =
                maybeAdminMark u m.c.csAdminKey
            }

userBucketsDetail u =
    case List.length u.buckets of
        0 ->
            "no buckets"
        n ->
            "Buckets (" ++ String.fromInt n ++ "): "
                ++ (String.join ", " (List.map (\{name} -> name) u.buckets))

userPoliciesDetail u =
    case List.length u.attachedPolicies of
        0 ->
            "no attached policies"
        n ->
            "Policies (" ++ String.fromInt n ++ "): "
                ++ (String.join ", " (u.attachedPolicies |> List.map Util.nameFromArn))


isAdmin m {keyId} =
    m.c.csAdminKey == keyId


maybeAdminMark u adminKey =
    if u.keyId == adminKey then
        [ Card.icon IconButton.config (IconButton.icon "#") ]
    else
        []


maybeShowCreateUserFab m =
    if m.s.createUserDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreateUserDialog
              |> Fab.setAttributes View.Style.createFab
              )
              (Fab.icon "add")
        ]


makeCreateUserDialog m =
    if m.s.createUserDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateUserCancelled
              )
              { title = "New user"
              , content =
                    [ div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewUserNameChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Email")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewUserEmailChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Path")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewUserPathChanged
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateUserCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreateUser
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Create"
                    ]
              }
        ]
    else
        []

makeEditUserDialog m =
    case m.s.openEditUserDialogFor of
        Just u ->
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose EditUserCancelled
                  )
                  { title = "Edit user"
                  , content =
                        [ div [ style "display" "grid"
                                   , style "grid-template-columns" "1"
                                   , style "row-gap" "0.3em"
                                   ]
                              [ TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Name")
                                    |> TextField.setRequired True
                                    |> TextField.setValue (Just u.userName)
                                    |> TextField.setOnInput EditedUserNameChanged
                                    )
                              , TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Email")
                                    |> TextField.setRequired True
                                    |> TextField.setValue (Just u.email)
                                    |> TextField.setOnInput EditedUserEmailChanged
                                    )
                              , TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Path")
                                    |> TextField.setRequired True
                                    |> TextField.setValue (Just u.path)
                                    |> TextField.setOnInput EditedUserPathChanged
                                    )
                              , div [ style "display" "grid"
                                         , style "grid-template-columns" "repeat(2, 1fr)"
                                         , style "align-items" "center"
                                         , style "margin" "0.6em 0 0 0"
                                         ]
                                  [ text "Enabled"
                                  , Switch.switch
                                    (Switch.config
                                    |> Switch.setChecked (u.status == "enabled")
                                    |> Switch.setOnChange EditedUserStatusChanged
                                    )
                                  , text "Regenerate key secret"
                                  , Checkbox.checkbox
                                        (Checkbox.config
                                        |> Checkbox.setState (checkboxStateFromBool m.s.generateNewCredsForEditedUser)
                                        |> Checkbox.setOnChange EditedUserRegenerateKeyChanged
                                        )
                                  ]
                              ]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick EditUserCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick UpdateUser
                              |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Update"
                        ]
                  }
            ]
        Nothing ->
            []



makeEditUserPoliciesDialog m =
    case m.s.openEditUserPoliciesDialogFor of
        Just arn ->
            let u = Model.userBy m .arn arn in
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose EditUserPoliciesDialogDismissed
                  )
                  { title = ("Policies attached to user " ++ u.userName)
                  , content =
                        [ div [ style "display" "grid"
                              , style "grid-template-columns" "1"
                              , style "row-gap" "0.3em"
                              ]
                              ([ policiesAsList m
                                     u.attachedPolicies
                                     m.s.selectedPoliciesForDetach
                                     SelectOrUnselectPolicyToDetach ]
                                   ++ [ div []
                                            [IconButton.iconButton
                                                 (IconButton.config
                                                 |> IconButton.setOnClick (ShowAttachPolicyDialog arn))
                                                 (IconButton.icon "add")
                                            ,  IconButton.iconButton
                                                 (IconButton.config
                                                 |> IconButton.setOnClick DetachUserPolicyBatch
                                                 |> IconButton.setDisabled (m.s.selectedPoliciesForDetach == []))
                                                 (IconButton.icon "delete")
                                            ]
                                      ]
                              )
                        ]
                  , actions =
                        [ Button.text
                              (Button.config
                              |> Button.setOnClick EditUserPoliciesDialogDismissed
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              )
                              "Dismiss"
                        ]
                  }
            ]
        Nothing ->
            []


makeAttachUserPolicyDialog m =
    case m.s.openAttachPoliciesDialogFor of
        Just arn ->
            let
                u = Model.userBy m .arn arn
                pp = List.map .arn m.s.policies
            in
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose AttachPolicyDialogCancelled
                  )
                  { title = "Available policies"
                  , content =
                        [ div [ style "display" "grid"
                              , style "grid-template-columns" "1"
                              , style "row-gap" "0.3em"
                              ]
                              [ policiesAsList m
                                    (Util.subtract pp u.attachedPolicies)
                                    m.s.selectedPoliciesForAttach
                                    SelectOrUnselectPolicyToAttach]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick AttachPolicyDialogCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick AttachUserPolicyBatch
                              |> Button.setDisabled (m.s.selectedPoliciesForAttach == [])
                              |> Button.setAttributes [ Dialog.defaultAction ])
                              "Attach"
                        ]
                  }
            ]
        Nothing ->
            []

checkboxStateFromBool a =
    if a then
        Just Checkbox.checked
    else
        Just Checkbox.unchecked
