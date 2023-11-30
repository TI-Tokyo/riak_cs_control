module View.Role exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
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
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Iso8601

makeContent m =
    div View.Style.topContent
        [ div View.Style.filterAndSort (makeSubTab m)
        , div View.Style.card (makeRoles m)
        , div [] (createRole m)
        , div [] (maybeShowCreateRoleFab m)
        ]

makeSubTab m =
    let n = View.Common.selectSortByString Name in
    [ TextField.outlined
          (TextField.config
          |> TextField.setLabel (Just "Filter")
          |> TextField.setValue (Just m.s.roleFilterValue)
          |> TextField.setOnInput RoleFilterChanged
          )
    , Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.roleSortBy))
          |> Select.setOnChange RoleSortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [CreateDate, RoleLastUsed])
    , Button.text (Button.config |> Button.setOnClick RoleSortOrderChanged)
            (View.Common.sortOrderText m.s.roleSortOrder)
    ]

makeRoles m =
    case m.s.roles |> filter m |> sort m |> List.map makeRole of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    List.filter (\a -> String.contains m.s.roleFilterValue a.roleName) aa

sort m aa =
    let
        aa0 =
            case m.s.roleSortBy of
                Name -> List.sortBy .roleName aa
                CreateDate -> List.sortWith (Util.compareByPosixTime .createDate) aa
                RoleLastUsed -> List.sortWith
                                (\r1 r2 -> case (r1.roleLastUsed, r2.roleLastUsed) of
                                               (Just q1, Just q2) -> if q1.lastUsedDate < q2.lastUsedDate then LT else GT
                                               (Just q1, Nothing) -> GT
                                               _ -> EQ)
                                    aa
                _ -> aa
    in
        if m.s.roleSortOrder then aa0 else List.reverse aa0

makeRole a =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    div View.Style.cardInnerHeader
                    [ text a.roleName ]
              , [ Card.block <|
                      div View.Style.cardInnerContent
                      [ Html.pre [] [ a |> cardContent |>text] ]
                , Card.block <|
                    div (View.Style.cardInnerContent ++ View.Style.jsonInset)
                        [ a |> cardPolicyDocument |> text ]
                ]
              )
        , actions = roleCardActions a
        }

cardContent a =
    "               Arn: " ++ a.arn ++ "\n" ++
    "              Path: " ++ a.path ++ "\n" ++
    "       Description: " ++ (Maybe.withDefault "" a.description) ++ "\n" ++
    "                Id: " ++ a.roleId ++ "\n" ++
    "           Created: " ++ (Iso8601.fromTime a.createDate) ++ "\n" ++
    "MaxSessionDuration: " ++ (String.fromInt (Maybe.withDefault 3600 a.maxSessionDuration))
        ++ Util.maybeTags a.tags "\nTags: "

cardPolicyDocument a =
    Util.pprintJson
        (Maybe.withDefault "" a.assumeRolePolicyDocument)


roleCardActions a =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeleteRole a.roleName)
                                ) "Delete"
                  ]
            , icons = []
            }


maybeShowCreateRoleFab m =
    if m.s.createRoleDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreateRoleDialog
              |> Fab.setAttributes
                   [ style "position" "fixed"
                   , style "bottom" "2rem"
                   , style "right" "2rem"
                   ]
              )
              (Fab.icon "add")
        ]


createRole m =
    if m.s.createRoleDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateRoleCancelled
              )
              { title = "New role"
              , content =
                    [ div [ style "display" "grid"
                          , style "grid-template-columns" "1"
                          , style "row-gap" "0.3em"
                          ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Name")
                                |> TextField.setRequired True
                                |> TextField.setOnChange NewRoleNameChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Description")
                                |> TextField.setOnChange NewRoleDescriptionChanged
                                )
                          , TextArea.outlined
                                (TextArea.config
                                |> TextArea.setLabel (Just "Policy document")
                                |> TextArea.setRequired True
                                |> TextArea.setOnChange NewRoleAssumeRolePolicyDocumentChanged
                                |> TextArea.setRows (Just 12)
                                |> TextArea.setCols (Just 82)
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setLabel (Just "Permissions boundary")
                                |> TextField.setOnChange NewRolePermissionsBoundaryChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setValue (Just "3600")
                                |> TextField.setType (Just "number")
                                |> TextField.setMin (Just 3600)
                                |> TextField.setMax (Just 43200)
                                |> TextField.setSuffix (Just "sec")
                                |> TextField.setEndAligned True
                                |> TextField.setLabel (Just "Max session duration")
                                |> TextField.setOnChange (NewRoleMaxSessionDurationChanged << Maybe.withDefault -1 << String.toInt)
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateRoleCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreateRole
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Create"
                    ]
              }
        ]
    else
        []
