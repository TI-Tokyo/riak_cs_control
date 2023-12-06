module Update exposing (update)

import Model exposing (..)
import Msg exposing (Msg(..))
import Request.Aws
import Request.Rcs
import Data.Struct
import Data.Json
import View.Common
import Util

import Time
import Task
import Process
import Dict exposing (Dict)
import Iso8601
import Json.Decode
import Http
import Retry
import Material.Snackbar as Snackbar


update : Msg -> Model -> (Model, Cmd Msg)
update msg m =
    case msg of
        TabClicked t ->
            let s_ = m.s in
            ( {m | s = {s_ | activeTab = t, bucketStats = Dict.empty, topDrawerOpen = False}}
            , refreshTabMsg m t
            )
        OpenTopDrawer ->
            let s_ = m.s in
            ( {m | s = {s_ | topDrawerOpen = not s_.topDrawerOpen}}
            , Cmd.none
            )

        -- ServerInfo
        ------------------------------
        GetServerInfo ->
            (m, Request.Rcs.getServerInfo m)
        GotServerInfo (Ok s) ->
            let s_ = m.s in
            ({m | s = {s_ | serverInfo = s}}, Cmd.none)
        GotServerInfo (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to get server info: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        -- User
        ------------------------------
        UserFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterValue = s}}, Cmd.none)
        UserFilterInItemClicked s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterIn = Util.addOrDeleteElement s_.userFilterIn s}}, Cmd.none)
        UserSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        UserSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | userSortOrder = not s_.userSortOrder}}, Cmd.none)

        ListUsers ->
            (m, Request.Rcs.listUsers m)
        GotUserListMultipart (Ok usersRaw) ->
            let
                users = Data.Json.seriallyDecodeMultipartUsers usersRaw
                s_ = m.s
            in
                ({m | s = {s_ | users = users}}, Cmd.none)
        GotUserListMultipart (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch users: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )
        GotUserList (Ok users) ->
            let s_ = m.s in
            ({m | s = { s_ | users = users}}, Cmd.none)
        GotUserList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch users: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowCreateUserDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createUserDialogShown = True}}, Cmd.none)
        NewUserNameChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newUserName = s}}, Cmd.none)
        NewUserEmailChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newUserEmail = s}}, Cmd.none)
        NewUserPathChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newUserPath = s}}, Cmd.none)
        CreateUser ->
            (m, Request.Rcs.createUser m)
        CreateUserCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | createUserDialogShown = False}}, Cmd.none)
        UserCreated (Ok ()) ->
            let s_ = m.s in
            ({m | s = {s_ | createUserDialogShown = False}}, Request.Rcs.listUsers m)
        UserCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteUser u ->
            (m, Request.Rcs.deleteUser m u)
        UserDeleted (Ok ()) ->
            (m, Request.Rcs.listUsers m)
        UserDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ClearBucketsStats ->
            let s_ = m.s in
            ({m | s = {s_ | bucketStats = Dict.empty}}, Cmd.none)
        ListAllBuckets ->
            let s_ = m.s in
            ({m | s = {s_ | bucketStats = Dict.empty}}, listAllBucketsCmd m)
        ListBucket u b ->
            (m, Request.Rcs.listBucket m u b)
        GotBucketList (Ok a) ->
            ( Model.updateBucketStats m a
            , Cmd.none
            )
        GotBucketList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to get bucket contents: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowEditUserDialog u ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Just u}}, Cmd.none)
        EditedUserNameChanged s ->
            let
                s_ = m.s
                u_ = Maybe.withDefault Data.Struct.dummyUser m.s.openEditUserDialogFor
            in
                ({m | s = {s_ | openEditUserDialogFor = Just {u_ | userName = s}}}, Cmd.none)
        EditedUserEmailChanged s ->
            let
                s_ = m.s
                u_ = Maybe.withDefault Data.Struct.dummyUser m.s.openEditUserDialogFor
            in
                ({m | s = {s_ | openEditUserDialogFor = Just {u_ | email = s}}}, Cmd.none)
        EditedUserPathChanged s ->
            let
                s_ = m.s
                u_ = Maybe.withDefault Data.Struct.dummyUser m.s.openEditUserDialogFor
            in
                ({m | s = {s_ | openEditUserDialogFor = Just {u_ | path = s}}}, Cmd.none)
        EditedUserStatusChanged ->
            let
                s_ = m.s
                u_ = Maybe.withDefault Data.Struct.dummyUser m.s.openEditUserDialogFor
            in
                ({m | s = {s_ | openEditUserDialogFor = Just {u_ | status = toggleStatus u_.status}}}, Cmd.none)
        EditedUserRegenerateKeyChanged ->
            let s_ = m.s in
            ({m | s = {s_ | generateNewCredsForEditedUser = not m.s.generateNewCredsForEditedUser}}, Cmd.none)
        UpdateUser ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Request.Rcs.updateUser m)
        EditUserCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Cmd.none)


        ShowEditUserPoliciesDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserPoliciesDialogFor = Just a}}, Cmd.none)
        EditUserPoliciesDialogDismissed ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserPoliciesDialogFor = Nothing}}, Cmd.none)

        AttachUserPolicyBatch ->
            let s_ = m.s in
            ( {m | s = { s_
                       | openEditUserPoliciesDialogFor = Nothing
                       , selectedPoliciesForAttach = []
                       , selectedPoliciesForDetach = []}}
            , Cmd.batch (List.map (Request.Aws.attachUserPolicy m) s_.selectedPoliciesForAttach)
            )
        DetachUserPolicyBatch ->
            let s_ = m.s in
            ( {m | s = { s_
                       | selectedPoliciesForAttach = []
                       , selectedPoliciesForDetach = []}}
            , Cmd.batch (List.map (Request.Aws.detachUserPolicy m) s_.selectedPoliciesForDetach)
            )
        UserPolicyAttached _ ->
            (m, Cmd.batch [Request.Rcs.listUsers m, Request.Aws.listPolicies m])
        UserPolicyDetached _ ->
            (m, Cmd.batch [Request.Rcs.listUsers m, Request.Aws.listPolicies m])


        -- Policy
        ------------------------------
        PolicyFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | policyFilterValue = s}}, Cmd.none)
        PolicyFilterInItemClicked s ->
            let s_ = m.s in
            ({m | s = {s_ | policyFilterIn = Util.addOrDeleteElement s_.policyFilterIn s}}, Cmd.none)
        PolicySortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | policySortBy = View.Common.stringToSortBy s}}, Cmd.none)
        PolicySortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | policySortOrder = not s_.policySortOrder}}, Cmd.none)

        ListPolicies ->
            (m, Request.Aws.listPolicies m)
        GotPolicyList (Ok aa) ->
            let s_ = m.s in
            ({m | s = { s_ | policies = aa}}, Cmd.none)
        GotPolicyList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | policies = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch policies: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowCreatePolicyDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createPolicyDialogShown = True}}, Cmd.none)
        NewPolicyNameChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newPolicyName = s}}, Cmd.none)
        NewPolicyPathChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newPolicyPath = s}}, Cmd.none)
        NewPolicyDescriptionChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newPolicyDescription = Just s}}, Cmd.none)
        NewPolicyPolicyDocumentChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newPolicyPolicyDocument = s}}, Cmd.none)
        CreatePolicy ->
            (m, Request.Aws.createPolicy m)
        CreatePolicyCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | createPolicyDialogShown = False}}, Cmd.none)
        PolicyCreated (Ok _) ->
            let s_ = m.s in
            ({m | s = {s_ | createPolicyDialogShown = False}}, Request.Aws.listPolicies m)
        PolicyCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create role: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeletePolicy a ->
            (m, Request.Aws.deletePolicy m a)
        PolicyDeleted (Ok _) ->
            (m, Request.Aws.listPolicies m)
        PolicyDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete policy: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        -- Role
        ------------------------------
        RoleFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | roleFilterValue = s}}, Cmd.none)
        RoleSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | roleSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        RoleSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | roleSortOrder = not s_.roleSortOrder}}, Cmd.none)

        ListRoles ->
            (m, Request.Aws.listRoles m)
        GotRoleList (Ok aa) ->
            let s_ = m.s in
            ({m | s = {s_ | roles = aa}}, Cmd.none)
        GotRoleList (Err err) ->
            let s_ = m.s in
            ( { m | s = {s_ | roles = [], msgQueue = Snackbar.addMessage
                             (Snackbar.message ("Failed to fetch roles: " ++ (explainHttpError err))) m.s.msgQueue } }
            , Cmd.none
            )
        ListAttachedRolePolicies a ->
            (m, Request.Aws.listAttachedRolePolicies m a)
        GotAttachedRolePolicyList rn (Ok aa) ->
            (Model.populateRoleAttachedPolicies m rn aa, Cmd.none)
        GotAttachedRolePolicyList _ (Err err) ->
            let s_ = m.s in
            ( { m | s = {s_ | roles = [], msgQueue = Snackbar.addMessage
                             (Snackbar.message ("Failed to fetch role attached policies: " ++ (explainHttpError err))) m.s.msgQueue } }
            , Cmd.none
            )

        ShowCreateRoleDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createRoleDialogShown = True}}, Cmd.none)
        NewRoleNameChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRoleName = s}}, Cmd.none)
        NewRolePathChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRolePath = s}}, Cmd.none)
        NewRoleAssumeRolePolicyDocumentChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRoleAssumeRolePolicyDocument = s}}, Cmd.none)
        NewRoleDescriptionChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRoleDescription = Just s}}, Cmd.none)
        NewRolePermissionsBoundaryChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRolePermissionsBoundary = Just s}}, Cmd.none)
        NewRoleMaxSessionDurationChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newRoleMaxSessionDuration = s}}, Cmd.none)
        CreateRole ->
            (m, Request.Aws.createRole m)
        CreateRoleCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | createRoleDialogShown = False}}, Cmd.none)
        RoleCreated (Ok _) ->
            let s_ = m.s in
            ({m | s = {s_ | createRoleDialogShown = False}}, Request.Aws.listRoles m)
        RoleCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create role: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteRole a ->
            (m, Request.Aws.deleteRole m a)
        RoleDeleted (Ok _) ->
            (m, Request.Aws.listRoles m)
        RoleDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete role: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowEditRolePoliciesDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditRolePoliciesDialogFor = Just a}}, Cmd.none)
        EditRolePoliciesDialogDismissed ->
            let s_ = m.s in
            ({m | s = {s_ | openEditRolePoliciesDialogFor = Nothing}}, Cmd.none)

        AttachRolePolicyBatch ->
            let
                s_ = m.s
                roleNeedRefresh = s_.openEditRolePoliciesDialogFor
            in
            -- need to do ListAttachedRolePolicies. tried
            -- making a task out of Aws.iamCall for
            -- "ListRoles" (then to combine it with
            -- ListAttachedRolePolicies), saw 415 from
            -- webmachine, backed off
            ( {m | s = { s_
                       | openAttachPoliciesDialogFor = Nothing
                       , selectedPoliciesForAttach = []
                       , selectedPoliciesForDetach = []}}
            , Cmd.batch (List.map (Request.Aws.attachRolePolicy m) s_.selectedPoliciesForAttach)
            )
        DetachRolePolicyBatch ->
            let
                s_ = m.s
                roleNeedRefresh = s_.openEditRolePoliciesDialogFor
            in
            ( {m | s = { s_
                       | selectedPoliciesForAttach = []
                       , selectedPoliciesForDetach = []}}
            , Cmd.batch (List.map (Request.Aws.detachRolePolicy m) s_.selectedPoliciesForDetach)
            )
        RolePolicyAttached _ ->
            ( m
            , Request.Aws.listRoles m
            )
        RolePolicyDetached _ ->
            ( Model.markRoleForRefresh m
            , Cmd.none
            )

        -- shared dialog messages (User and Role)
        ShowAttachPolicyDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openAttachPoliciesDialogFor = Just a}}, Cmd.none)
        AttachPolicyDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openAttachPoliciesDialogFor = Nothing}}, Cmd.none)
        SelectOrUnselectPolicyToAttach a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedPoliciesForAttach = Util.addOrDeleteElement s_.selectedPoliciesForAttach a}}, Cmd.none)
        SelectOrUnselectPolicyToDetach a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedPoliciesForDetach = Util.addOrDeleteElement s_.selectedPoliciesForDetach a}}, Cmd.none)

        -- SAMLProvider
        ------------------------------
        SAMLProviderFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | samlProviderFilterValue = s}}, Cmd.none)
        SAMLProviderSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | samlProviderSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        SAMLProviderSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | samlProviderSortOrder = not s_.samlProviderSortOrder}}, Cmd.none)

        ListSAMLProviders ->
            (m, Request.Aws.listSAMLProviders m)
        GetSAMLProvider a ->
            (m, Request.Aws.getSAMLProvider m a)
        GotSAMLProvider (Ok a) ->
            (Model.enrichSamlProvider m a, Cmd.none)
        GotSAMLProvider (Err err) ->
            let s_ = m.s in
            ( { m | s = {s_ | msgQueue = Snackbar.addMessage
                             (Snackbar.message ("Failed to get SAML Provider: " ++ (explainHttpError err))) m.s.msgQueue } }
            , Cmd.none
            )
        GotSAMLProviderList (Ok aa) ->
            let s_ = m.s in
            ({m | s = {s_ | samlProviders = aa}}, Cmd.none)
        GotSAMLProviderList (Err err) ->
            let s_ = m.s in
            ( { m | s = {s_ | samlProviders = [], msgQueue = Snackbar.addMessage
                             (Snackbar.message ("Failed to fetch SAML Providers: " ++ (explainHttpError err))) m.s.msgQueue } }
            , Cmd.none
            )

        ShowCreateSAMLProviderDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createSAMLProviderDialogShown = True}}, Cmd.none)
        NewSAMLProviderNameChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newSAMLProviderName = s}}, Cmd.none)
        NewSAMLProviderSAMLMetadataDocumentChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newSAMLProviderSAMLMetadataDocument = s}}, Cmd.none)
        CreateSAMLProvider ->
            (m, Request.Aws.createSAMLProvider m)
        CreateSAMLProviderCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | createSAMLProviderDialogShown = False}}, Cmd.none)
        SAMLProviderCreated (Ok _) ->
            let s_ = m.s in
            ({m | s = {s_ | createSAMLProviderDialogShown = False}}, Request.Aws.listSAMLProviders m)
        SAMLProviderCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create SAML Provider: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteSAMLProvider a ->
            (m, Request.Aws.deleteSAMLProvider m a)
        SAMLProviderDeleted (Ok _) ->
            (m, Request.Aws.listSAMLProviders m)
        SAMLProviderDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete SAML Provider: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        -- temp sessions
        ListTempSessions ->
            (m, Request.Rcs.listTempSessions m)
        GotTempSessionList (Ok aa) ->
            let s_ = m.s in
            ({m | s = {s_ | tempSessions = aa}}, Cmd.none)
        GotTempSessionList (Err err) ->
            let s_ = m.s in
            ( { m | s = {s_ | tempSessions = [], msgQueue = Snackbar.addMessage
                             (Snackbar.message ("Failed to fetch temp sessions: " ++ (explainHttpError err))) m.s.msgQueue } }
            , Cmd.none
            )

        TempSessionFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | tempSessionFilterValue = s}}, Cmd.none)
        TempSessionSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | tempSessionSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        TempSessionSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | tempSessionSortOrder = not s_.tempSessionSortOrder}}, Cmd.none)


        -- Usage
        ------------------------------
        UsageFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | usageFilterValue = s}}, Cmd.none)
        UsageTopItemsShownChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | usageTopItemsShown = String.toInt s |> Maybe.withDefault 8}}, Cmd.none)

        -- UsageDateFromChanged s ->
        --     let
        --         s_ = m.s
        --         usage_ = s_.usage
        --     in
        --         case Iso8601.toTime s of
        --             Ok t ->
        --                 ({m | s = {s_ | usage = {usage_ | dateFrom = t}}}, Cmd.none)
        --             Err _ ->
        --                 ( {m | s = {s_ | msgQueue = Snackbar.addMessage
        --                                 (Snackbar.message "Invalid date") m.s.msgQueue}}
        --                 , Cmd.none
        --                 )
        -- UsageDateToChanged s ->
        --     let
        --         s_ = m.s
        --         usage_ = s_.usage
        --     in
        --         case Iso8601.toTime s of
        --             Ok t ->
        --                 ({m | s = {s_ | usage = {usage_ | dateTo = t}}}, Cmd.none)
        --             Err _ ->
        --                 ( {m | s = {s_ | msgQueue = Snackbar.addMessage
        --                                 (Snackbar.message "Invalid date") m.s.msgQueue}}
        --                 , Cmd.none
        --                 )

        -- GetAllUsage ->
        --     (m, getAllUsageCmd m)
        -- GetUsage k ->
        --     (m, Request.Rcs.getUsage m k m.s.usage.dateFrom m.s.usage.dateTo)
        -- GotUsage (Ok i) ->
        --     let
        --         s_ = m.s
        --         usage_ = s_.usage
        --         stats_ = usage_.stats
        --     in
        --         ({m | s = {s_ | usage = {usage_ | stats = Dict.insert i.keyId i stats_}}}
        --          , Cmd.none
        --          )
        -- GotUsage (Err err) ->
        --     let
        --         s_ = m.s
        --         usage_ = s_.usage
        --     in
        --         ( {m | s = {s_ | usage = {usage_ | stats = Dict.empty}, msgQueue = Snackbar.addMessage
        --                         (Snackbar.message ("Failed to fetch usage stats: " ++ (explainHttpError err))) m.s.msgQueue}}
        --         , Cmd.none
        --         )

        -- Admin creds
        ------------------------------
        ShowConfigDialog ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = True}}, Cmd.none)
        ConfigUrlChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigUrl = s}}, Cmd.none)
        ConfigKeyIdChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigKeyId = s}}, Cmd.none)
        ConfigSecretKeyChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigSecretKey = s}}, Cmd.none)
        SetConfig ->
            let
                c_ = m.c
                s_ = m.s
            in
            ( { m | c = {c_ | csUrl = m.s.newConfigUrl
                            , csAdminKey = m.s.newConfigKeyId
                            , csAdminSecret = m.s.newConfigSecretKey},
                    s = {s_ | configDialogShown = False}
              }
            , Cmd.none
            )
        SetConfigCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = False}}, Cmd.none)


        -- Notifications
        ------------------------------
        SnackbarClosed a ->
            let
                s_ = m.s
                b = Snackbar.close a m.s.msgQueue
            in
                ({m | s = {s_ | msgQueue = b}}, Cmd.none)

        Tick a ->
            if Time.posixToMillis m.t == 0 then
                let
                    s_ = m.s
                    -- usage_ = s_.usage
                    -- oneDayEarlier = \x -> (Time.posixToMillis x) - 24 * 3600 * 1000 |> Time.millisToPosix
                    m_ = {m | t = a}
                in
                    ( m_
                    , refreshAll m_
                    )
            else
                ({ m | t = a}, maybeRefreshRolePolicies m)

        -- internal
        Chain aa ->
            let
                chain msgi (m0, cmds) =
                    let (m1, c) = update msgi m0 in
                    (m1, cmds ++ [c])
                (m9, cmd9) = List.foldl chain (m, []) aa
            in
                (m9, Cmd.batch cmd9)

        NoOp ->
            (m, Cmd.none)
        Discard _ ->
            (m, Cmd.none)


listAllBucketsCmd m =
    List.map
        (\(u, b) -> Request.Rcs.listBucket m u b)
        (Model.flattenUserBucketList m)
            |> Cmd.batch

getAllSamlProvidersCmd m =
    List.map (\{arn} -> Request.Aws.getSAMLProvider m arn) m.s.samlProviders |> Cmd.batch

-- getAllUsageCmd m =
--     (List.map
--          (\{keyId} -> Request.Rcs.getUsage m keyId m.s.usage.dateFrom m.s.usage.dateTo)
--          m.s.users) |> Cmd.batch


refreshTabMsg m t =
    case t of
        Msg.General -> Request.Rcs.getServerInfo m
        Msg.Users -> refreshEssentials m
        Msg.Policies -> Request.Aws.listPolicies m
        Msg.Roles -> Request.Aws.listRoles m
        Msg.SAMLProviders -> Request.Aws.listSAMLProviders m -- getAllSamlProvidersCmd m
        Msg.TempSessions -> Request.Rcs.listTempSessions m
        Msg.Usage -> listAllBucketsCmd m

refreshEssentials m =
    Cmd.batch [ Request.Rcs.getServerInfo m
              , Request.Rcs.listUsers m
              , Request.Aws.listPolicies m
              ]

refreshAll m =
    Cmd.batch [ Request.Rcs.getServerInfo m
              , Request.Rcs.listUsers m
              , Request.Aws.listPolicies m
              , Request.Aws.listRoles m
              , Request.Aws.listSAMLProviders m
              , Request.Rcs.listTempSessions m
              ]

maybeRefreshRolePolicies m =
    let
        nn = List.filterMap (\{attachedPoliciesFetched, roleName} ->
                                 case attachedPoliciesFetched of
                                     True -> Nothing
                                     False -> Just roleName
                            ) m.s.roles
    in
        Cmd.batch <| List.map (Request.Aws.listAttachedRolePolicies m) nn

explainHttpError a =
    case a of
        Http.BadBody s ->
            "" ++ (Util.ellipsize s 500)
        Http.Timeout ->
            "Request timed out"
        Http.NetworkError ->
            "Network error"
        Http.BadStatus s ->
            "Bad status " ++ String.fromInt s
        Http.BadUrl s ->
            "BadUrl. This shouldn't have happened"

toggleStatus a =
    case a of
        "enabled" -> "disabled"
        _ -> "enabled"
