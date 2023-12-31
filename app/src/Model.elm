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

module Model exposing
    ( Model
    , Config
    , State
    , userBy
    , roleBy
    , policyByName
    , enrichSamlProvider
    , flattenUserBucketList
    , updateBucketStats
    , populateRoleAttachedPolicies
    , markRoleForRefresh
    , placeholderPolicy
    , resetCreateUserDialogFields
    , resetCreatePolicyDialogFields
    , resetCreateRoleDialogFields
    , resetCreateSAMLProviderDialogFields
    )

import Data.Struct exposing (..)
import Msg
import View.Common

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

type alias State =
    { users : List User
    , roles : List Role
    , policies : List Policy
    , samlProviders : List SAMLProvider
    , tempSessions : List TempSession
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
    , userFilterIn : List String
    , userSortBy : View.Common.SortByField
    , userSortOrder : View.Common.SortOrder
    --
    , createUserDialogShown : Bool
    , newUserName : String
    , newUserPath : String
    , newUserEmail : String
    , openEditUserDialogFor : Maybe User
    , generateNewCredsForEditedUser : Bool
    , openEditUserPoliciesDialogFor : Maybe String

    -- policies
    , policyFilterValue : String
    , policyFilterIn : List String
    , policySortBy : View.Common.SortByField
    , policySortOrder : View.Common.SortOrder
    --
    , createPolicyDialogShown : Bool
    , newPolicyName : String
    , newPolicyPath : String
    , newPolicyDescription : Maybe String
    , newPolicyPolicyDocument : String
    , newPolicyTags : List Tag

    -- roles
    , roleFilterValue : String
    , roleSortBy : View.Common.SortByField
    , roleSortOrder : View.Common.SortOrder
    --
    , createRoleDialogShown : Bool
    , newRoleName : String
    , newRolePath : String
    , newRoleDescription : Maybe String
    , newRoleAssumeRolePolicyDocument : String
    , newRolePermissionsBoundary : Maybe String
    , newRoleMaxSessionDuration : Int
    , newRoleTags : List Tag
    , openEditRolePoliciesDialogFor : Maybe String

    -- saml providers
    , samlProviderFilterValue : String
    , samlProviderSortBy : View.Common.SortByField
    , samlProviderSortOrder : View.Common.SortOrder
    --
    , createSAMLProviderDialogShown : Bool
    , newSAMLProviderName : String
    , newSAMLProviderSAMLMetadataDocument : String
    , newSAMLProviderTags : List Tag

    -- temp sessions
    , tempSessionFilterValue : String
    , tempSessionSortBy : View.Common.SortByField
    , tempSessionSortOrder : View.Common.SortOrder
    --

    -- bucket stats/usage
    , usageFilterValue : String
    , usageTopItemsShown : Int

    -- attach/detach policies dialog (shared between User and Role)
    , openAttachPoliciesDialogFor : Maybe String
    , selectedPoliciesForAttach : List String
    , selectedPoliciesForDetach : List String
    }


userBy : Model -> (User -> String) -> String -> User
userBy m by a =
    case List.filter (\u -> a == by u) m.s.users of
        [] -> Data.Struct.dummyUser
        u :: _ -> u

roleBy : Model -> (Role -> String) -> String -> Role
roleBy m by a =
    case List.filter (\r -> a == by r) m.s.roles of
        [] -> Data.Struct.dummyRole
        r :: _ -> r

policyByName : Model -> String -> Data.Struct.Policy
policyByName m a =
    case List.filter (\p -> p.policyName == a) m.s.policies of
        [] -> Data.Struct.dummyPolicy
        p :: _ -> p

markRoleForRefresh m =
    let
        s_ = m.s
        roles =
            case s_.openEditRolePoliciesDialogFor of
                Just s ->
                    List.map (\r ->
                                  if r.roleName == s then
                                      {r | attachedPoliciesFetched = False}
                                  else
                                      r
                             ) s_.roles
                Nothing ->
                    s_.roles
    in
        {m | s = { s_ | roles = roles}}

populateRoleAttachedPolicies : Model -> String -> List AttachedPolicy -> Model
populateRoleAttachedPolicies m rn pp =
    let
        s_ = m.s
        roles = List.map
                (\r ->
                     if r.roleName == rn then
                         {r
                         | attachedPolicies = pp
                         , attachedPoliciesFetched = True
                         }
                     else r
                ) s_.roles
    in
        { m | s = {s_ | roles = roles} }

placeholderPolicy : AttachedPolicy
placeholderPolicy =
    { policyName = "$$"
    , policyArn = ""
    }

enrichSamlProvider : Model -> SAMLProvider -> Model
enrichSamlProvider m a =
    let
        s_ = m.s
        replacer =
            \x ->
                if x.arn == a.arn then
                    {x | samlMetadataDocument = a.samlMetadataDocument
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


resetCreateUserDialogFields : Model -> Model
resetCreateUserDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createUserDialogShown = False
                 , newUserName = ""
                 , newUserPath = ""
                 , newUserEmail = ""}}


resetCreatePolicyDialogFields : Model -> Model
resetCreatePolicyDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createPolicyDialogShown = False
                 , newPolicyName = ""
                 , newPolicyPath = ""
                 , newPolicyDescription = Nothing}}


resetCreateRoleDialogFields : Model -> Model
resetCreateRoleDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createRoleDialogShown = False
                 , newRoleName = ""
                 , newRolePath = ""
                 , newRoleAssumeRolePolicyDocument = ""
                 , newRoleDescription = Nothing
                 , newRolePermissionsBoundary = Nothing
                 , newRoleMaxSessionDuration = 3600}}


resetCreateSAMLProviderDialogFields : Model -> Model
resetCreateSAMLProviderDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createSAMLProviderDialogShown = False
                 , newSAMLProviderName = ""
                 , newSAMLProviderSAMLMetadataDocument = ""}}
