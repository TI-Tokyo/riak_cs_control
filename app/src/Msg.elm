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

module Msg exposing (Msg(..), Tab(..))

import Data.Struct exposing
    ( User, Role, Policy, AttachedPolicy, SAMLProvider, TempSession
    , ServerInfo
    , BucketContents
    , RequestId
    )

import Http
import Time
import Material.Snackbar as Snackbar

type Tab
    = General
    | Users
    | Roles
    | Policies
    | Usage
    | SAMLProviders
    | TempSessions

type Msg
    = NoOp
    | Discard String

    -- General
    ----------
    | GetServerInfo
    | GotServerInfo (Result Http.Error ServerInfo)

    -- Users
    | ListUsers
    | GotUserList (Result Http.Error (List User))
    | GotUserListMultipart (Result Http.Error String)
    | CreateUser
    | UserCreated (Result Http.Error ())
    | DeleteUser String
    | DeleteUserConfirmed
    | DeleteUserNotConfirmed
    | UserDeleted (Result Http.Error ())
    | UpdateUser
    | ClearBucketsStats
    | ListAllBuckets
    | ListBucket String String
    | GotBucketList (Result Http.Error BucketContents)
    | AttachUserPolicyBatch
    | DetachUserPolicyBatch
    | UserPolicyAttached (Result Http.Error RequestId)
    | UserPolicyDetached (Result Http.Error RequestId)

    -- Policies
    | ListPolicies
    | GotPolicyList (Result Http.Error (List Policy))
    | CreatePolicy
    | PolicyCreated (Result Http.Error Policy)
    | DeletePolicy String
    | DeletePolicyConfirmed
    | DeletePolicyNotConfirmed
    | PolicyDeleted (Result Http.Error RequestId)

    -- Roles
    | ListRoles
    | GotRoleList (Result Http.Error (List Role))
    | CreateRole
    | RoleCreated (Result Http.Error Role)
    | DeleteRole String
    | DeleteRoleConfirmed
    | DeleteRoleNotConfirmed
    | RoleDeleted (Result Http.Error RequestId)
    | ListAttachedRolePolicies String
    | GotAttachedRolePolicyList String (Result Http.Error (List AttachedPolicy))
    | AttachRolePolicyBatch
    | DetachRolePolicyBatch
    | RolePolicyAttached (Result Http.Error RequestId)
    | RolePolicyDetached (Result Http.Error RequestId)

    -- SAMLProviders
    | ListSAMLProviders
    | GetSAMLProvider String
    | GotSAMLProvider (Result Http.Error SAMLProvider)
    | GotSAMLProviderList (Result Http.Error (List SAMLProvider))
    | CreateSAMLProvider
    | SAMLProviderCreated (Result Http.Error SAMLProvider)
    | DeleteSAMLProvider String
    | DeleteSAMLProviderConfirmed
    | DeleteSAMLProviderNotConfirmed
    | SAMLProviderDeleted (Result Http.Error RequestId)

    -- TempSessions
    | ListTempSessions
    | GotTempSessionList (Result Http.Error (List TempSession))

    -- -- Usage
    -- | GetAllUsage
    -- | GetUsage String
    -- | GotUsage (Result Http.Error UsagePerUser)

    -- UI interactions
    ------------------
    | TabClicked Tab
    | OpenTopDrawer
    | ShowConfigDialog
    | ConfigUrlChanged String
    | ConfigKeyIdChanged String
    | ConfigSecretKeyChanged String
    | SetConfig
    | SetConfigCancelled

    -- users
    | UserFilterChanged String
    | UserFilterInItemClicked String
    | UserSortByFieldChanged String
    | UserSortOrderChanged

    | ShowCreateUserDialog
    | NewUserNameChanged String
    | NewUserEmailChanged String
    | NewUserPathChanged String
    | CreateUserCancelled
    | ShowEditUserDialog User
    | EditedUserNameChanged String
    | EditedUserEmailChanged String
    | EditedUserPathChanged String
    | EditedUserStatusChanged
    | EditedUserRegenerateKeyChanged
    | EditUserCancelled
    | ShowEditUserPoliciesDialog String
    | EditUserPoliciesDialogDismissed

    -- policies
    | PolicyFilterChanged String
    | PolicyFilterInItemClicked String
    | PolicySortByFieldChanged String
    | PolicySortOrderChanged
    | ShowCreatePolicyDialog
    | NewPolicyNameChanged String
    | NewPolicyPathChanged String
    | NewPolicyDescriptionChanged String
    | NewPolicyPolicyDocumentChanged String
    | CreatePolicyCancelled

    -- roles
    | RoleFilterChanged String
    | RoleSortByFieldChanged String
    | RoleSortOrderChanged
    | ShowCreateRoleDialog
    | NewRoleNameChanged String
    | NewRolePathChanged String
    | NewRoleDescriptionChanged String
    | NewRoleAssumeRolePolicyDocumentChanged String
    | NewRolePermissionsBoundaryChanged String
    | NewRoleMaxSessionDurationChanged Int
    | CreateRoleCancelled
    | ShowEditRolePoliciesDialog String
    | EditRolePoliciesDialogDismissed

    -- saml providers
    | SAMLProviderFilterChanged String
    | SAMLProviderSortByFieldChanged String
    | SAMLProviderSortOrderChanged
    | ShowCreateSAMLProviderDialog
    | NewSAMLProviderNameChanged String
    | NewSAMLProviderSAMLMetadataDocumentChanged String
    | CreateSAMLProviderCancelled

    -- temp sessions
    | TempSessionFilterChanged String
    | TempSessionSortByFieldChanged String
    | TempSessionSortOrderChanged

    -- usage
    | UsageFilterChanged String
    | UsageTopItemsShownChanged String
    -- later
    -- | UsageDateFromChanged String
    -- | UsageDateToChanged String

    -- policy attach/detach dialog (shared between User and Role)
    | ShowAttachPolicyDialog String
    | SelectOrUnselectPolicyToAttach String
    | SelectOrUnselectPolicyToDetach String
    | AttachPolicyDialogCancelled

    -- misc
    | SnackbarClosed Snackbar.MessageId

    | Chain (List Msg)
    | Tick Time.Posix
