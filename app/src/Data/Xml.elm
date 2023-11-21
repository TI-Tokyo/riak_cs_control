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
    )

import Data.Struct exposing (..)
import Xml.Decode as D exposing (..)
import Util

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


-- SAMLProviders

decodeSAMLProviders : D.Decoder (List SAMLProvider)
decodeSAMLProviders =
    path [ "ListSAMLProvidersResult", "SAMLProviderList", "SAMLProviderListEntry" ] (list decodeSAMLProvider)

decodeSAMLProvider =
    succeed SAMLProvider
        |> requiredPath ["Arn"] (single string)
        |> optionalPath ["Name"] (single string) ""
        |> requiredPath ["CreateDate"] (single string)
        |> requiredPath ["ValidUntil"] (single string)
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []

decodeGetSAMLProviderResponse a =
    path [ "GetSAMLProviderResult" ] (single (decodeGetSAMLProviderResult a))

decodeGetSAMLProviderResult a =
    succeed SAMLProvider
        |> optionalPath ["Arn"] (single string) a
        |> optionalPath ["Name"] (single string) ""
        |> requiredPath ["CreateDate"] (single string)
        |> requiredPath ["ValidUntil"] (single string)
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []

decodeSAMLProviderCreated =
    path ["CreateSAMLProviderResult"] (single decodeSAMLProviderCreateResponse)

decodeSAMLProviderCreateResponse =
    succeed SAMLProvider
        |> requiredPath ["SAMLProviderArn"] (single string)
        -- none the following is present in the response
        |> optionalPath ["Name"] (single string) ""
        |> optionalPath ["CreateDate"] (single string) ""
        |> optionalPath ["ValidUntil"] (single string) ""
        |> optionalPath ["SAMLMetadataDocument"] (single string) ""
        |> optionalPath ["Tags"] (list tag) []




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


-- common nodes

permissionsBoundary =
    succeed PermissionsBoundary
        |> requiredPath ["PermissionsBoundaryArn"] (single string)
        |> requiredPath ["PermissionsBoundaryType"] (single string) -- "Policy"

tag =
    succeed Tag
        |> requiredPath ["Name"] (single string)
        |> requiredPath ["Value"] (single string)
