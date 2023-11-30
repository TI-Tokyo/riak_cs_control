module View.Common exposing (..)

import Model exposing (Model, SortByField(..), SortOrder)
import Msg exposing (Msg(..))

import Html.Attributes exposing (style)


sortOrderText =
    \o -> if o then "Asc" else "Desc"

selectSortByString a =
    case a of
        Name -> "Name"
        CreateDate -> "Create date"
        ValidUntil -> "Valid until"
        AttachmentCount -> "Attachment count"
        RoleLastUsed -> "Role last used"
        Unsorted -> "None"

stringToSortBy a =
    case a of
        "Name" -> Name
        "Create date" -> CreateDate
        "Valid until" -> ValidUntil
        "Attachment count" -> AttachmentCount
        "Role last used" -> RoleLastUsed
        _ -> Unsorted
