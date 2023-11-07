module Data.Struct exposing (..)


type alias ServerInfo =
    { version : String
    , systemVersion : String
    , uptime : String
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

type alias Usage =
    { objects : Int
    , bytes : Int
    }

type alias User =
    { arn : String
    , path : String
    , userId : String
    , userName : String
    , createDate : String
    , passwordLastUsed : Maybe String
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
    , createDate : String
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
    , createDate : String
    , description : Maybe String
    , assumeRolePolicyDocument : Maybe String
    , permissionsBoundary : Maybe PermissionsBoundary
    , roleLastUsed : Maybe RoleLastUsed
    , maxSessionDuration : Maybe Int
    , tags : List Tag
    }

type alias RoleLastUsed =
    { lastUsedDate : String
    , region : String
    }

type alias DiskUsage =
    {}


type alias RequestId =
    String


dummyUser =
    { arn = ""
    , path = ""
    , userId = ""
    , userName = ""
    , createDate = ""
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

dummyPolicy =
    { arn = ""
    , path = ""
    , policyId = ""
    , policyName = ""
    , createDate = ""
    , description = Nothing
    , policyDocument = ""
    , defaultVersionId = ""
    , attachmentCount = -1
    , permissionsBoundaryUsageCount = -1
    , isAttachable = False
    , updateDate = ""
    , tags = []
    }

dummyRoleLastUsed =
    { lastUsedDate = ""
    , region = ""
    }
