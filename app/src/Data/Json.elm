-- ---------------------------------------------------------------------
--
-- Copyright (c) 2023-2024 TI Tokyo    All Rights Reserved.
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

module Data.Json exposing
    ( decodeServerInfo
    , decodeUserList
    , seriallyDecodeMultipartUsers
--    , decodeUsage
    )

import Data.Struct exposing (..)
import Json.Decode as D exposing (succeed, list, string, int, map, oneOf, nullable)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Iso8601
import Time
import Util


decodeServerInfo =
    succeed ServerInfo
        |> required "version" string
        |> required "system_version" string
        |> required "uptime" string
        |> required "storage_info" (list storageInfoItem)

storageInfoItem =
    succeed StorageInfo
        |> required "node" string
        |> required "df_total" int
        |> required "df_available" int
        |> required "n_val" int
        |> required "backend_data_total_size" int

seriallyDecodeMultipartUsers s =
    List.concat
        (List.map
             ((D.decodeString decodeUserList) >> Result.withDefault [])
             (s |> Util.stripMPBoundaries))


decodeUserList : D.Decoder (List User)
decodeUserList =
    list user

user =
    succeed User
        |> required "arn" string
        |> required "path" string
        |> required "id" string
        |> required "name" string
        |> required "create_date" isoDate
        |> required "password_last_used" (nullable isoDate)
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

isoDate =
    map Time.millisToPosix int

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
        |> required "creation_date" int
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


-- decodeUsage k =
--     succeed UsagePerUser
--         |> hardcoded k  -- this is how we thread the keyId
--         |> required "Storage" storage
-- storage =
--     succeed UsageStorage
--         |> required "Samples" samples
-- samples =
--     list sample
-- sample =
--     succeed UsageStorageSample
--         |> required "Objects" int
--         |> required "Bytes" int
