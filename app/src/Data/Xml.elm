module Data.Xml exposing
    ( decodeUsers
    , decodeRoles
    , decodePolicies
    , decodeRoleCreated
    , decodePolicyCreated
    , decodeEmptySuccessResponse
    )

import Data.Struct exposing (..)
import Xml.Decode as D exposing (..)


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
        |> requiredPath ["CreateDate"] (single string)
        |> possiblePath ["PasswordLastUsed"] (single string)
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
        |> requiredPath ["CreateDate"] (single string)
        |> possiblePath ["Description"] (single string)
        |> possiblePath ["AssumeRolePolicyDocument"] (single string)
        |> possiblePath ["PermissionsBoundary"] (single permissionsBoundary)
        |> possiblePath ["RoleLastUsed"] (single roleLastUsed)
        |> possiblePath ["MaxSessionDuration"] (single int)
        |> optionalPath ["Tags"] (list tag) []

roleLastUsed =
    succeed RoleLastUsed
        |> optionalPath ["LastUsedDate"] (single string) ""
        |> optionalPath ["Region"] (single string) ""


decodeRoleCreated =
    path ["CreateRoleResult", "Role"] (single role)



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
        |> requiredPath ["CreateDate"] (single string)
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



-- common nodes

permissionsBoundary =
    succeed PermissionsBoundary
        |> requiredPath ["PermissionsBoundaryArn"] (single string)
        |> requiredPath ["PermissionsBoundaryType"] (single string) -- "Policy"

tag =
    succeed Tag
        |> requiredPath ["Name"] (single string)
        |> requiredPath ["Value"] (single string)
