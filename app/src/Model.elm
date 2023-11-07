module Model exposing
    ( Model
    , Config
    , State
    , SortByField(..)
    , SortOrder
    , userByArn
    , policyByName
    )

import Data.Struct exposing (..)
import Msg

import Time
import Material.Snackbar as Snackbar

type alias Model =
    { c : Config
    , s : State
    , t : Time.Posix
    }


type alias Config =
    { csUrl : String
    , csAdminKey : String
    , csAdminSecret : String
    , region : String
    }

type SortByField
    = Name
    | CreateDate
    | AttachmentCount
    | RoleLastUsed
    | Unsorted

type alias SortOrder = Bool

type alias State =
    { users : List User
    , roles : List Role
    , policies : List Policy
    , usageStats : List (String, Usage)
    , diskUsage : DiskUsage
    , msgQueue : Snackbar.Queue Msg.Msg
    , activeTab : Msg.Tab

    -- general
    , serverInfo : ServerInfo
    --
    , configDialogShown : Bool
    , newConfigUrl : String
    , newConfigKeyId : String
    , newConfigSecretKey : String

    -- users
    , userFilterValue : String
    , userSortBy : SortByField
    , userSortOrder : SortOrder
    --
    , createUserDialogShown : Bool
    , newUserName : String
    , newUserPath : String
    , newUserEmail : String
    , openEditUserDialogFor : Maybe User
    , generateNewCredsForEditedUser : Bool
    , openEditUserPoliciesDialogFor : Maybe String     -- these are arns
    , openAttachUserPoliciesDialogFor : Maybe String
    , selectedPoliciesForAttach : List String
    , selectedPoliciesForDetach : List String

    -- policies
    , policyFilterValue : String
    , policySortBy : SortByField
    , policySortOrder : SortOrder
    --
    , createPolicyDialogShown : Bool
    , newPolicyName : String
    , newPolicyPath : String
    , newPolicyDescription : Maybe String
    , newPolicyPolicyDocument : String
    , newPolicyTags : List Tag

    -- roles
    , roleFilterValue : String
    , roleSortBy : SortByField
    , roleSortOrder : SortOrder
    --
    , createRoleDialogShown : Bool
    , newRoleName : String
    , newRolePath : String
    , newRoleDescription : Maybe String
    , newRoleAssumeRolePolicyDocument : String
    , newRolePermissionsBoundary : Maybe String
    , newRoleMaxSessionDuration : Int
    , newRoleTags : List Tag
    }

userByArn : Model -> String -> Data.Struct.User
userByArn m a =
    case List.filter (\u -> u.arn == a) m.s.users of
        [] -> Data.Struct.dummyUser
        u :: _ -> u

policyByName : Model -> String -> Data.Struct.Policy
policyByName m a =
    case List.filter (\p -> p.policyName == a) m.s.policies of
        [] -> Data.Struct.dummyPolicy
        p :: _ -> p
