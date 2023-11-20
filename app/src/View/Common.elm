module View.Common exposing (..)

import Model exposing (Model, SortByField(..), SortOrder)
import Msg exposing (Msg(..))

import Html.Attributes exposing (style)
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.TextField as TextField
import Material.Button as Button


topContentStyle =
    [ style "display" "grid"
    , style "grid-template-columns" "1"
    ]

subTabStyle =
    [ style "align-self" "end"
    , style "align-content" "end"
    , style "padding" "0.1em 0"
    , style "scale" "0.7"
    , style "z-index" "20"
    ]

cardStyle =
    [ style "display" "flex"
    , style "flex-wrap" "wrap"
    , style "gap" "1em"
    ]

cardInnerHeaderStyle =
    [ style "padding" ".5em .5em 0"
    , style "border-bottom" "solid #cccccc"
    , Typography.headline5
    ]

cardInnerContentStyle =
    [ style "padding" "0 1em 0"
    ]


createFabStyle =
    [ style "position" "fixed"
    , style "bottom" "2rem"
    , style "right" "2rem"
    ]

jsonInsetStyle =
    [ style "scale" "0.8"
    , style "background-color" "lightgrey"
    , style "border" "thick"
    , style "border-radius" "0 0 1em 0"
    ]


makeSubTab m =
    let
        a =
            case m.s.activeTab of
                Msg.General ->  { a = ""
                                , b = Unsorted
                                , c = Discard
                                , d = Discard
                                , e = NoOp
                                , f = "Name"
                                , g = []
                                , h = True
                                }
                Msg.Users ->    { a = m.s.userFilterValue
                                , b = m.s.userSortBy
                                , c = UserFilterChanged
                                , d = UserSortByFieldChanged
                                , e = UserSortOrderChanged
                                , f = "Name"
                                , g = ["Create date"]
                                , h = m.s.userSortOrder
                                }
                Msg.Policies -> { a = m.s.policyFilterValue
                                , b = m.s.policySortBy
                                , c = PolicyFilterChanged
                                , d = PolicySortByFieldChanged
                                , e = PolicySortOrderChanged
                                , f = "Name"
                                , g = ["Create date", "Attachment count"]
                                , h = m.s.policySortOrder
                                }
                Msg.Roles ->    { a = m.s.roleFilterValue
                                , b = m.s.roleSortBy
                                , c = RoleFilterChanged
                                , d = RoleSortByFieldChanged
                                , e = RoleSortOrderChanged
                                , f = "Name"
                                , g = ["Create date", "Role last used"]
                                , h = m.s.roleSortOrder
                                }
                Msg.Usage ->    { a = m.s.usageFilterValue
                                , b = m.s.usageSortBy
                                , c = UsageFilterChanged
                                , d = UsageSortByFieldChanged
                                , e = UsageSortOrderChanged
                                , f = "Total object size"
                                , g = ["Create date", "Total object size", "Total object count", "Total bucket count", "Name"]
                                , h = m.s.usageSortOrder
                                }
    in
        [ TextField.outlined
              (TextField.config
              |> TextField.setLabel (Just "Filter")
              |> TextField.setValue (Just a.a)
              |> TextField.setOnInput a.c
              )
        , Select.outlined
              (Select.config
              |> Select.setLabel (Just "Sort by")
              |> Select.setSelected (Just (selectSortByString a.b))
              |> Select.setOnChange a.d
              )
              (SelectItem.selectItem (SelectItem.config { value = a.f }) a.f)
              (List.map (\i -> SelectItem.selectItem (SelectItem.config {value = i}) i) a.g)
        ] ++ maybeSortOrderButton m a

sortOrderText =
    \o -> if o then "Asc" else "Desc"

maybeSortOrderButton m a =
    case m.s.activeTab of
        Msg.Usage ->
            []
        _ ->
            [ Button.text (Button.config |> Button.setOnClick a.e) (sortOrderText a.h) ]


selectSortByString a =
    case a of
        Name -> "Name"
        CreateDate -> "Create date"
        AttachmentCount -> "Attachment count"
        RoleLastUsed -> "Role last used"
        TotalObjectSize -> "Total object size"
        TotalObjectCount -> "Total object count"
        TotalBucketCount -> "Total bucket count"
        Unsorted -> "None"

stringToSortBy a =
    case a of
        "Name" -> Name
        "Create date" -> CreateDate
        "Attachment count" -> AttachmentCount
        "Role last used" -> RoleLastUsed
        "Total object size" -> TotalObjectSize
        "Total object count" -> TotalObjectCount
        "Total bucket count" -> TotalBucketCount
        _ -> Unsorted

