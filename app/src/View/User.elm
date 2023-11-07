module View.User exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import Data.Struct
import View.Common
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

makeContent m =
    Html.div View.Common.topContentStyle
        [ Html.div View.Common.subTabStyle (View.Common.makeSubTab m)
        , Html.div View.Common.cardStyle (makeUsers m)
        , Html.div [] (makeCreateUserDialog m)
        , Html.div [] (makeEditUserDialog m)
        , Html.div [] (makeEditUserPoliciesDialog m)
        , Html.div [] (makeAttachUserPolicyDialog m)
        , Html.div [] (maybeShowCreateUserFab m)
        ]

makeUsers m =
    case m.s.users |> (filter m) |> (sort m) |> List.map (makeUser m) of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m uu =
    List.filter (\u -> String.contains m.s.userFilterValue u.userName) uu

sort m aa =
    let
        aa0 =
            case m.s.userSortBy of
                Name -> List.sortBy .userName aa
                CreateDate -> List.sortBy .createDate aa
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
        Html.div []
            [ Card.card Card.config
                 { blocks =
                       ( Card.block <|
                             Html.div View.Common.cardInnerHeaderStyle
                             [ text (u.userName ++ maybeDisabled)]
                       , [ Card.block <|
                               Html.div (View.Common.cardInnerContentStyle ++ (isEnabledStyle u))
                               [ Html.pre [ style "row-span" "2" ] [ u |> cardContent |> text ]
                               , Html.div [ Typography.body2 ]
                                   [ text (userBucketsDetail u) ]
                               , Html.div [ Typography.body2 ]
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
    "  Created: " ++ u.createDate ++ "\n" ++
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
                                |> Button.setDisabled (isAdmin m u)
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
                ++ (String.join ", " u.attachedPolicies)


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
              |> Fab.setAttributes View.Common.createFabStyle
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
                    [ Html.div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setOnChange NewUserNameChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Email")
                                |> TextField.setOnChange NewUserEmailChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Path")
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
                        [ Html.div [ style "display" "grid"
                                   , style "grid-template-columns" "1"
                                   , style "row-gap" "0.3em"
                                   ]
                              [ TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Name")
                                    |> TextField.setValue (Just u.userName)
                                    |> TextField.setOnInput EditedUserNameChanged
                                    )
                              , TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Email")
                                    |> TextField.setValue (Just u.email)
                                    |> TextField.setOnInput EditedUserEmailChanged
                                    )
                              , TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Path")
                                    |> TextField.setValue (Just u.path)
                                    |> TextField.setOnInput EditedUserPathChanged
                                    )
                              , Html.div [ style "display" "grid"
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
            let u = Model.userByArn m arn in
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose EditUserPoliciesDialogDismissed
                  )
                  { title = ("Policies attached to user " ++ u.userName)
                  , content =
                        [ Html.div [ style "display" "grid"
                                   , style "grid-template-columns" "1"
                                   , style "row-gap" "0.3em"
                                   ]
                              ([ policiesAsList m
                                     u.attachedPolicies
                                     m.s.selectedPoliciesForDetach
                                     SelectOrUnselectPolicyToDetach ]
                                   ++ [ Html.div []
                                            [IconButton.iconButton
                                                 (IconButton.config
                                                 |> IconButton.setOnClick (ShowAttachUserPolicyDialog arn))
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
    case m.s.openAttachUserPoliciesDialogFor of
        Just arn ->
            let
                u = Model.userByArn m arn
                pp = List.map .arn m.s.policies
            in
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose AttachUserPolicyDialogCancelled
                  )
                  { title = "Available policies"
                  , content =
                        [ Html.div [ style "display" "grid"
                                   , style "grid-template-columns" "1"
                                   , style "row-gap" "0.3em"
                                   ]
                              [ policiesAsList m
                                    (subtract pp u.attachedPolicies)
                                    m.s.selectedPoliciesForAttach
                                    SelectOrUnselectPolicyToAttach]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick AttachUserPolicyDialogCancelled)
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
        Html.div [] [element]

subtract l1 l2 =
    List.filter (\a -> not (List.member a l2)) l1

checkboxStateFromBool a =
    if a then
        Just Checkbox.checked
    else
        Just Checkbox.unchecked
