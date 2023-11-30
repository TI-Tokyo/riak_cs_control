module View.Common exposing (..)

import Msg exposing (Msg(..))

import Html.Attributes exposing (style)

type SortByField
    = Name
    | Email
    | BucketCount
    | CreateDate
    | ValidUntil
    | AttachmentCount
    | RoleLastUsed
    | Unsorted

type alias SortOrder = Bool

sortOrderText =
    \o -> if o then "Asc" else "Desc"

selectSortByString a =
    case a of
        Name -> "Name"
        Email -> "Email"
        BucketCount -> "Bucket count"
        CreateDate -> "Create date"
        ValidUntil -> "Valid until"
        AttachmentCount -> "Attachment count"
        RoleLastUsed -> "Role last used"
        Unsorted -> "None"

stringToSortBy a =
    case a of
        "Name" -> Name
        "Email" -> Email
        "Bucket count" -> BucketCount
        "Create date" -> CreateDate
        "Valid until" -> ValidUntil
        "Attachment count" -> AttachmentCount
        "Role last used" -> RoleLastUsed
        _ -> Unsorted
