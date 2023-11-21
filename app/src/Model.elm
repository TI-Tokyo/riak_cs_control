module Model exposing
    ( Model
    , Config
    , State
    , SortByField(..)
    , SortOrder
    , userBy
    , policyByName
    , enrichSamlProvider
    , flattenUserBucketList
    , updateBucketStats
    )

import Data.Struct exposing (..)
import Msg

import Dict
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
    | ValidUntil
    | AttachmentCount
    | RoleLastUsed
    | TotalObjectSize
    | TotalObjectCount
    | TotalBucketCount
    | Unsorted

type alias SortOrder = Bool

type alias State =
    { users : List User
    , roles : List Role
    , policies : List Policy
    , samlProviders : List SAMLProvider
    , bucketStats : BucketStats
    -- , usage : Usage
    , msgQueue : Snackbar.Queue Msg.Msg
    , activeTab : Msg.Tab
    , topDrawerOpen : Bool

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

    -- saml providers
    , samlProviderFilterValue : String
    , samlProviderSortBy : SortByField
    , samlProviderSortOrder : SortOrder
    --
    , createSAMLProviderDialogShown : Bool
    , newSAMLProviderName : String
    , newSAMLProviderSAMLMetadataDocument : String
    , newSAMLProviderTags : List Tag

    -- bucket stats/usage
    , usageFilterValue : String
    , usageSortBy : SortByField
    , usageSortOrder : SortOrder
    , usageTopItemsShown : Int
    }


userBy : Model -> (User -> String) -> String -> Data.Struct.User
userBy m by a =
    case List.filter (\u -> a == by u) m.s.users of
        [] -> Data.Struct.dummyUser
        u :: _ -> u

policyByName : Model -> String -> Data.Struct.Policy
policyByName m a =
    case List.filter (\p -> p.policyName == a) m.s.policies of
        [] -> Data.Struct.dummyPolicy
        p :: _ -> p

enrichSamlProvider : Model -> SAMLProvider -> Model
enrichSamlProvider m a =
    let
        s_ = m.s
        replacer =
            \x ->
                if x.arn == a.arn then
                    let
                        name = String.split "/" a.arn |> List.reverse |> List.head |> Maybe.withDefault "?"
                    in
                        {x | name = name
                           , samlMetadataDocument = a.samlMetadataDocument
                           , tags = a.tags
                        }
                else
                    x
        pp = List.map replacer m.s.samlProviders
    in
        {m | s = {s_ | samlProviders = pp}}


flattenUserBucketList : Model -> List (String, String)
flattenUserBucketList m =
    let
        ubPairs = \u bb -> List.map (\{name} -> (u, name)) bb
    in
        List.foldl
            (\{userName, buckets} q -> (ubPairs userName buckets) ++ q)
            [] m.s.users

updateBucketStats : Model -> BucketContents -> Model
updateBucketStats m bc =
    let
        s_ = m.s
        stats0 = case Dict.get bc.userName m.s.bucketStats of
                     Nothing ->
                         BucketStatsItem 0 0 0
                     Just s ->
                         s
        stats9 = {stats0 | totalBucketCount = stats0.totalBucketCount + 1,
                           totalObjectCount = stats0.totalObjectCount + List.length bc.contents,
                           totalObjectSize = stats0.totalObjectSize + (List.foldl (\c q -> c.size + q) 0 bc.contents)}
        bucketStats9 =
            Dict.insert bc.userName stats9 m.s.bucketStats
    in
        {m | s = {s_ | bucketStats = bucketStats9}}

