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

module Data.Xml exposing
    ( decodeUsers
    , decodePolicies
    , decodePolicyCreated
    , decodeRoles
    , decodeRoleCreated
    , decodeSAMLProviders
    , decodeSAMLProvider
    , decodeSAMLProviderCreated
    , decodeGetSAMLProviderResponse
    , decodeEmptySuccessResponse
    , decodeBucketContents
    , decodeTempSessionList
    , decodeListAttachedRolePolicies
    )

import Data.Struct exposing (..)
import Util
import Xml.Decode as D exposing (..)
import Iso8601
import Time


-- Users

decodeUsers : D.Decoder (List User)
decodeUsers =
    path [ "ListUsersResult", "Users", "User" ] (list user)

user =
    succeed User
        |> requiredPath ["Arn"] (single string)
        |> requiredPath ["Path"] (single string)
        |> requiredPath ["UserId"] (single string)
        |> requiredPath ["UserName"] (single string)
        |> requiredPath ["CreateDate"] (single unixtime)
        |> possiblePath ["PasswordLastUsed"] (single unixtime)
        |> possiblePath ["PermissionsBoundary"] (single permissionsBoundary)
        |> optionalPath ["Tags"] (list tag) []
        -- rcs extensions, not reported in ListUsers:
        |> optionalPath ["DisplayName"] (single string) "to-be-filled-by-admin-call"
        |> optionalPath ["Email"] (single string)  "to-be-filled-by-admin-call"
        |> optionalPath ["KeyId"] (single string) "to-be-filled-by-admin-call"
        |> optionalPath ["KeySecret"] (single string) "to-be-filled-by-admin-call"
        |> optionalPath ["Status"] (single string) "to-be-filled-by-admin-call"
        |> optionalPath ["Buckets"] (list bucket) []
        |> optionalPath ["AttachedPolicies"] (list string) []

bucket =
    succeed Bucket
        |> requiredPath ["Name"] (single string)
        |> requiredPath ["LastAction"] (single string)
        |> requiredPath ["CreateDate"] (single int)
        |> requiredPath ["ModificationTime"] (single int)
        |> possiblePath ["Acl"] (single acl)

acl =
    succeed Acl
        |> requiredPath ["Owner"] (single owner)
        |> requiredPath ["Grants"] (list grant)
        |> requiredPath ["CreationTime"] (single int)  -- would naturally be a string, if/when implemented on riak_cs side

owner =
    succeed Owner
        |> optionalPath ["DisplayName"] (single string) ""
        |> requiredPath ["CanonicalId"] (single string)
        |> optionalPath ["Email"] (single string) ""
        |> optionalPath ["KeyId"] (single string) ""

grant =
    succeed Grant
        |> requiredPath ["Grantee"] (single grantee)
        |> requiredPath ["Perms"] (list perm)

grantee =
    oneOf
        [ map Group groupGrant
        , map Sole owner
        ]

groupGrant =
    map groupGrantFromString string

perm =
    map permFromString string


decodeEmptySuccessResponse =
    path ["ResponseMetadata", "RequestId"] (single string)


-- Policies

decodePolicies : D.Decoder (List Policy)
decodePolicies =
    path [ "ListPoliciesResult", "Policies", "Policy" ] (list policy)

policy =
    succeed Policy
        |> requiredPath ["Arn"] (single string)
        |> requiredPath ["Path"] (single string)
        |> requiredPath ["PolicyId"] (single string)
        |> requiredPath ["PolicyName"] (single string)
        |> requiredPath ["CreateDate"] (single isoDate)
        |> possiblePath ["Description"] (single string)
        |> requiredPath ["PolicyDocument"] (single string)
        |> requiredPath ["DefaultVersionId"] (single string)
        |> requiredPath ["AttachmentCount"] (single int)
        |> requiredPath ["PermissionsBoundaryUsageCount"] (single int)
        |> requiredPath ["IsAttachable"] (single bool)
        |> requiredPath ["UpdateDate"] (single string)
        |> optionalPath ["Tags"] (list tag) []

decodePolicyCreated =
    path ["CreatePolicyResult", "Policy"] (single policy)


decodeListAttachedRolePolicies : D.Decoder (List AttachedPolicy)
decodeListAttachedRolePolicies =
    path [ "ListAttachedRolePoliciesResult", "AttachedPolicies", "member" ] (list attachedPolicy)

attachedPolicy =
    succeed AttachedPolicy
        |> requiredPath ["PolicyArn"] (single string)
        |> requiredPath ["PolicyName"] (single string)

-- Roles

decodeRoles : D.Decoder (List Role)
decodeRoles =
    path [ "ListRolesResult", "Roles", "Role" ] (list role)

role =
    succeed Role
        |> requiredPath ["Arn"] (single string)
        |> requiredPath ["Path"] (single string)
        |> requiredPath ["RoleId"] (single string)
        |> requiredPath ["RoleName"] (single string)
        |> requiredPath ["CreateDate"] (single isoDate)
        |> possiblePath ["Description"] (single string)
        |> possiblePath ["AssumeRolePolicyDocument"] (single string)
        |> possiblePath ["PermissionsBoundary"] (single permissionsBoundary)
        |> possiblePath ["RoleLastUsed"] (single roleLastUsed)
        |> possiblePath ["MaxSessionDuration"] (single int)
        |> optionalPath ["Tags"] (list tag) []
        |> optionalPath ["AttachedPolicies"] (list attachedPolicy) []
        |> optionalPath ["LearnMeSomeDecoding"] (single bool) False

roleLastUsed =
    succeed RoleLastUsed
        |> optionalPath ["LastUsedDate"] (single string) ""
        |> optionalPath ["Region"] (single string) ""


decodeRoleCreated =
    path ["CreateRoleResult", "Role"] (single role)


-- SAMLProviders

decodeSAMLProviders : D.Decoder (List SAMLProvider)
decodeSAMLProviders =
    path [ "ListSAMLProvidersResult", "SAMLProviderList", "SAMLProviderListEntry" ] (list decodeSAMLProvider)

decodeSAMLProvider =
    succeed SAMLProvider
        |> requiredPath ["Arn"] (single string)
        |> optionalPath ["Name"] (single string) ""
        |> requiredPath ["CreateDate"] (single isoDate)
        |> requiredPath ["ValidUntil"] (single isoDate)
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []

decodeGetSAMLProviderResponse a =
    path [ "GetSAMLProviderResult" ] (single (decodeGetSAMLProviderResult a))

decodeGetSAMLProviderResult a =
    succeed SAMLProvider
        |> optionalPath ["Arn"] (single string) a
        |> optionalPath ["Name"] (single string) ""
        |> requiredPath ["CreateDate"] (single isoDate)
        |> requiredPath ["ValidUntil"] (single isoDate)
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []

decodeSAMLProviderCreated =
    path ["CreateSAMLProviderResult"] (single decodeSAMLProviderCreateResponse)

decodeSAMLProviderCreateResponse =
    succeed SAMLProvider
        |> requiredPath ["SAMLProviderArn"] (single string)
        -- none the following is present in the response
        |> optionalPath ["Name"] (single string) ""
        |> optionalPath ["CreateDate"] (single isoDate) (Time.millisToPosix 0)
        |> optionalPath ["ValidUntil"] (single isoDate) (Time.millisToPosix 0)
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []


-- temp sessions
decodeTempSessionList : D.Decoder (List TempSession)
decodeTempSessionList =
    path [ "ListTempSessionsResult", "TempSessions", "TempSession" ] (list tempSession)

tempSession =
    succeed TempSession
        |> requiredPath ["AssumedRoleUser"] (single assumedRoleUser)
        |> requiredPath ["Role"] (single role)
        |> requiredPath ["Credentials"] (single credentials)
        |> requiredPath ["DurationSeconds"] (single int)
        |> requiredPath ["Created"] (single isoDate)
        |> possiblePath ["InlinePolicy"] (single string)
        |> requiredPath ["SessionPolicies", "SessionPolicy" ] (list string)
        |> requiredPath ["Subject"] (single string)
        |> requiredPath ["SourceIdentity"] (single string)
        |> requiredPath ["Email"] (single string)
        |> requiredPath ["UserId"] (single string)
        |> requiredPath ["CanonicalID"] (single string)

assumedRoleUser =
    succeed AssumedRoleUser
        |> requiredPath ["Arn"] (single string)
        |> requiredPath ["AssumedRoleId"] (single string)

credentials =
    succeed Credentials
        |> requiredPath ["AccessKeyId"] (single string)
        |> requiredPath ["SecretAccessKey"] (single string)
        |> requiredPath ["SessionToken"] (single string)
        |> requiredPath ["Expiration"] (single isoDate)


-- BucketContents

decodeBucketContents u =
    succeed BucketContents
        |> requiredPath ["Name"] (single string)
        |> optionalPath ["Contents"] (list bucketContentsItem) []
        -- threading user
        |> optionalPath ["UserName"] (single string) u

bucketContentsItem =
    succeed BucketContentsItem
        |> requiredPath ["Key"] (single string)
        |> requiredPath ["LastModified"] (single date)
        |> requiredPath ["Size"] (single int)
        |> requiredPath ["StorageClass"] (single string)
        |> requiredPath ["Owner"] (single owner2)

owner2 =
    succeed Owner
        |> optionalPath ["DisplayName"] (single string) ""
        |> requiredPath ["ID"] (single string)
        |> optionalPath ["Email"] (single string) ""
        |> optionalPath ["KeyId"] (single string) ""


date =
    map dateFromString string
dateFromString =
    Util.amzDateToPosix

isoDate =
    map Util.isoDateToPosix string

unixtime =
    map Time.millisToPosix int


-- common nodes

permissionsBoundary =
    succeed PermissionsBoundary
        |> requiredPath ["PermissionsBoundaryArn"] (single string)
        |> requiredPath ["PermissionsBoundaryType"] (single string) -- "Policy"

tag =
    succeed Tag
        |> requiredPath ["Name"] (single string)
        |> requiredPath ["Value"] (single string)
