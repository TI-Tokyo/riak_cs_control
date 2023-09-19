module UserJson exposing
    ( decodeServerInfo
    , decodeList
    , seriallyDecodeMultipartUsers
    )

import Data exposing (..)
import Json.Decode as D exposing (succeed, list, string, int, map, oneOf, nullable)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Iso8601
import Time
import Util


decodeServerInfo =
    succeed ServerInfo
        |> required "version" string
        |> required "uptime" string


seriallyDecodeMultipartUsers s =
    List.concat
        (List.map
             ((D.decodeString decodeList) >> Result.withDefault [])
             (s |> Util.stripMPBoundaries))


decodeList : D.Decoder (List User)
decodeList =
    list user

user =
    succeed User
        |> required "arn" string
        |> required "path" string
        |> required "id" string
        |> required "name" string
        |> required "create_date" isoDateFromInt
        |> required "password_last_used" (nullable isoDateFromInt)
        |> required "permissions_boundary" (nullable permissionsBoundary)
        |> required "tags" (list tag)
        --
        |> required "display_name" string
        |> required "email" string
        |> required "key_id" string
        |> required "key_secret" string
        |> required "status" string
        |> required "buckets" (list bucket)
        |> required "attached_policies" (list string)

-- Riak CS stores unixtime in user password_last_used and create_date
-- kept fields. It exports these fields as such in admin interface
-- (json), but converts values to iso8601 date strings in IAM API
-- calls, so:
isoDateFromInt =
    map (Time.millisToPosix >> Iso8601.fromTime) int

tag =
    succeed Tag
        |> required "name" string
        |> required "value" string

permissionsBoundary =
    succeed PermissionsBoundary
        |> required "permissions_boundary_arn" string
        |> required "permissions_boundary_type" string

bucket =
    succeed Bucket
        |> required "name" string
        |> required "last_action" string
        |> required "create_date" int
        |> required "modification_time" int
        |> required "acl" (nullable acl)

acl =
    succeed Acl
        |> required "owner" owner
        |> required "grants" (list grant)
        |> required "creation_time" int

owner =
    succeed Owner
        |> optional "display_name" string ""
        |> required "canonical_id" string
        |> optional "email" string ""
        |> optional "key_id" string ""

grant =
    succeed Grant
        |> required "grantee" grantee
        |> required "perms" (list perm)

grantee =
    oneOf
        [ map Group groupGrant
        , map Sole owner
        ]

groupGrant =
    map groupGrantFromString string

groupGrantFromString a =
    case a of
        "AllUsers" -> AllUsers
        "AuthUsers" -> AuthUsers
        _ -> Invalid

perm =
    map permFromString string

permFromString a =
    case a of
        "READ" -> READ
        "WRITE" -> WRITE
        "READ_ACP" -> READ_ACP
        "WRITE_ACP" -> WRITE_ACP
        "FULL_CONTROL" -> FULL_CONTROL
        _ -> INVALID
