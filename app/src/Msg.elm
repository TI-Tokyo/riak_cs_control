module Msg exposing (Msg(..), Tab(..))

import Data.Struct exposing
    ( User, Role, Policy, SAMLProvider, TempSession
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
    | PolicyDeleted (Result Http.Error RequestId)

    -- Roles
    | ListRoles
    | GotRoleList (Result Http.Error (List Role))
    | CreateRole
    | RoleCreated (Result Http.Error Role)
    | DeleteRole String
    | RoleDeleted (Result Http.Error RequestId)

    -- SAMLProviders
    | ListSAMLProviders
    | GetSAMLProvider String
    | GotSAMLProvider (Result Http.Error SAMLProvider)
    | GotSAMLProviderList (Result Http.Error (List SAMLProvider))
    | CreateSAMLProvider
    | SAMLProviderCreated (Result Http.Error SAMLProvider)
    | DeleteSAMLProvider String
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
    | ShowAttachUserPolicyDialog String
    | SelectOrUnselectPolicyToAttach String
    | SelectOrUnselectPolicyToDetach String
    | AttachUserPolicyDialogCancelled
    | EditUserPoliciesDialogDismissed

    -- policies
    | PolicyFilterChanged String
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

    -- saml providers
    | SAMLProviderFilterChanged String
    | SAMLProviderSortByFieldChanged String
    | SAMLProviderSortOrderChanged
    | ShowCreateSAMLProviderDialog
    | NewSAMLProviderNameChanged String
    | NewSAMLProviderSAMLMetadataDocumentChanged String
    | CreateSAMLProviderCancelled

    -- saml providers
    | TempSessionFilterChanged String
    | TempSessionSortByFieldChanged String
    | TempSessionSortOrderChanged

    -- usage
    | UsageFilterChanged String
    | UsageTopItemsShownChanged String
    -- later
    -- | UsageDateFromChanged String
    -- | UsageDateToChanged String

    -- misc
    | SnackbarClosed Snackbar.MessageId
    | Tick Time.Posix
