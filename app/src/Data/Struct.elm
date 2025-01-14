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

module Data.Struct exposing (..)

import Dict exposing (Dict)
import Time


type alias StorageInfo =
    { node : String
    , dfTotal : Int
    , dfAvailable : Int
    , nVal : Int
    , backendDataTotalSize : Int
    }

type alias ServerInfo =
    { version : String
    , systemVersion : String
    , uptime : String
    , storageInfo : List StorageInfo
    }


type alias PermissionsBoundary =
    { permissionsBoundaryArn : String
    , permissionsBoundaryType : String
    }

type GroupGrant
    = AllUsers
    | AuthUsers
    | Invalid

type Grantee
    = Sole Owner
    | Group GroupGrant

type Perm
    = READ
    | WRITE
    | READ_ACP
    | WRITE_ACP
    | FULL_CONTROL
    | INVALID

type alias Grant =
    { grantee : Grantee
    , perms : List Perm
    }

type alias Owner =
    { displayName : String
    , canonicalId : String
    , email : String
    , keyId : String
    }

type alias Acl =
    { owner : Owner
    , grants : List Grant
    , creationTime : Int
    }

type alias Bucket =
    { name : String
    , lastAction : String
    , creationDate : Int
    , modificationTime : Int
    , acl : Maybe Acl
    }

type alias Tag =
    { name : String
    , value : String
    }


-- Disk Usage has two alternative/complimentary implementations
-- 1. Via ListBucket, where the disk usage per user is the total
--    size of objects in all user's buckets

type alias BucketContentsItem =
    { key : String
    , lastModified : Time.Posix
    , size : Int
    , storageClass : String
    , owner : Owner
    }
type alias BucketContents =
    { name : String
    , contents : List BucketContentsItem
    -- threaded via request
    , userName : String
    }

type alias BucketStatsItem =
    { totalBucketCount : Int
    , totalObjectCount : Int
    , totalObjectSize : Int
    }
type alias BucketStats =
    Dict String BucketStatsItem

-- -- 2. More detailed/rcs-specific usage, as reported by /riak-cs/usage
-- type alias UsageStorageSample =
--     { objects : Int
--     , bytes : Int
--     }
-- type alias UsageStorage =
--     { samples : List UsageStorageSample
--     }
-- type alias UsagePerUser =
--     { keyId : String
--     , storage : UsageStorage
--     }
-- type alias Usage =
--     { dateFrom : Time.Posix
--     , dateTo : Time.Posix
--     , stats : Dict String UsagePerUser
--     }

type alias User =
    { arn : String
    , path : String
    , userId : String
    , userName : String
    , createDate : Time.Posix
    , passwordLastUsed : Maybe Time.Posix
    , permissionsBoundary : Maybe PermissionsBoundary
    , tags : List Tag
    -- rcs extensions:
    , display_name : String
    , email : String
    , keyId : String
    , secretKey : String
    , status : String
    , buckets : List Bucket
    , attachedPolicies : List String
    }

type Status
    = Enabled | Disabled

groupGrantFromString a =
    case a of
        "AllUsers" -> AllUsers
        "AuthUsers" -> AuthUsers
        _ -> Invalid

permFromString a =
    case a of
        "READ" -> READ
        "WRITE" -> WRITE
        "READ_ACP" -> READ_ACP
        "WRITE_ACP" -> WRITE_ACP
        "FULL_CONTROL" -> FULL_CONTROL
        _ -> INVALID


type alias Policy =
    { arn : String
    , path : String
    , policyId : String
    , policyName : String
    , createDate : Time.Posix
    , description : Maybe String
    , policyDocument : String
    , defaultVersionId : String
    , attachmentCount : Int
    , permissionsBoundaryUsageCount : Int
    , isAttachable : Bool
    , updateDate : String
    , tags : List Tag
    }


type alias Role =
    { arn : String
    , path : String
    , roleId : String
    , roleName : String
    , createDate : Time.Posix
    , description : Maybe String
    , assumeRolePolicyDocument : Maybe String
    , permissionsBoundary : Maybe PermissionsBoundary
    , roleLastUsed : Maybe RoleLastUsed
    , maxSessionDuration : Maybe Int
    , tags : List Tag
    , attachedPolicies : List AttachedPolicy
    , attachedPoliciesFetched : Bool
    }

type alias AttachedPolicy =
    { policyArn : String
    , policyName : String
    }

type alias RoleLastUsed =
    { lastUsedDate : String
    , region : String
    }


type alias SAMLProvider =
    { arn : String
    , name : String
    , createDate : Time.Posix
    , validUntil : Time.Posix
    , samlMetadataDocument : String
    , tags : List Tag
    }


type alias AssumedRoleUser =
    { arn : String
    , assumedRoleId : String
    }

type alias Credentials =
    { accessKeyId : String
    , secretAccessKey : String
    , sessionToken : String
    , expiration : Time.Posix
    }

type alias TempSession =
    { assumedRoleUser : AssumedRoleUser
    , role : Role
    , credentials : Credentials
    , durationSeconds : Int
    , created : Time.Posix
    , inlinePolicy : Maybe String
    , sessionPolicies : List String
    , subject : String
    , sourceIdentity : String
    , email : String
    , userId : String
    , canonicalId : String
    }



type alias RequestId =
    String


dummyUser =
    { arn = ""
    , path = ""
    , userId = ""
    , userName = ""
    , createDate = Time.millisToPosix 0
    , passwordLastUsed = Nothing
    , permissionsBoundary = Nothing
    , tags = []
    , display_name = ""
    , email = ""
    , keyId = ""
    , secretKey = ""
    , status = ""
    , buckets = []
    , attachedPolicies = []
    }

dummyRole =
    { arn = ""
    , path = ""
    , roleId = ""
    , roleName = ""
    , createDate = Time.millisToPosix 0
    , description = Nothing
    , assumeRolePolicyDocument = Nothing
    , permissionsBoundary = Nothing
    , roleLastUsed = Nothing
    , maxSessionDuration = Nothing
    , tags = []
    , attachedPolicies = []
    , attachedPoliciesFetched = False
    }

dummyPolicy =
    { arn = ""
    , path = ""
    , policyId = ""
    , policyName = ""
    , createDate = Time.millisToPosix 0
    , description = Nothing
    , policyDocument = ""
    , defaultVersionId = ""
    , attachmentCount = -1
    , permissionsBoundaryUsageCount = -1
    , isAttachable = False
    , updateDate = ""
    , tags = []
    }


dummySAMLProvider =
    { arn = ""
    , name = ""
    , createDate = Time.millisToPosix 0
    , validUntil = Time.millisToPosix 0
    , samlMetadataDocument = ""
    , tags = []
    }

dummyRoleLastUsed =
    { lastUsedDate = ""
    , region = ""
    }
