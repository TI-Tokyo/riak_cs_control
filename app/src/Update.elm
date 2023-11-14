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
import Dict exposing (Dict)
import Iso8601
import Json.Decode
import Http
import Material.Snackbar as Snackbar


update : Msg -> Model -> (Model, Cmd Msg)
update msg m =
    case msg of
        TabClicked t ->
            let s_ = m.s in
            ({m | s = {s_ | activeTab = t}}, refreshTabMsg m t)

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

        ListAllBuckets ->
            (m, (List.map
                     (\b -> Request.Rcs.listBucket m b)
                     m.s.users) |> Cmd.batch)
        ListBucket b ->
            (m, Request.Rcs.listBucket m b)
        GotBucketList (Ok a) ->
            let
                s_ = m.s
                bucketStats_ = s_.bucketstats
            in
                ( {m | s = {s_ | bucketStats = Model.updateBucketStats a}}
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
        ShowAttachUserPolicyDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openAttachUserPoliciesDialogFor = Just a}}, Cmd.none)
        AttachUserPolicyDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openAttachUserPoliciesDialogFor = Nothing}}, Cmd.none)
        EditUserPoliciesDialogDismissed ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserPoliciesDialogFor = Nothing}}, Cmd.none)
        SelectOrUnselectPolicyToAttach a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedPoliciesForAttach = addOrDeleteElement s_.selectedPoliciesForAttach a}}, Cmd.none)
        SelectOrUnselectPolicyToDetach a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedPoliciesForDetach = addOrDeleteElement s_.selectedPoliciesForDetach a}}, Cmd.none)
        AttachUserPolicyBatch ->
            let s_ = m.s in
            ( {m | s = {s_ | openAttachUserPoliciesDialogFor = Nothing
                       , selectedPoliciesForAttach = []
                       , selectedPoliciesForDetach = []}}
            , Cmd.batch (List.map (Request.Aws.attachUserPolicy m) s_.selectedPoliciesForAttach)
            )
        DetachUserPolicyBatch ->
            let s_ = m.s in
            ( {m | s = {s_ | selectedPoliciesForAttach = []
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


        -- Usage
        ------------------------------
        UsageFilterChanged s ->
            (m, Cmd.none)
        UsageSortByFieldChanged s ->
            (m, Cmd.none)

        UsageDateFromChanged s ->
            let
                s_ = m.s
                usage_ = s_.usage
            in
                case Iso8601.toTime s of
                    Ok t ->
                        ({m | s = {s_ | usage = {usage_ | dateFrom = t}}}, Cmd.none)
                    Err _ ->
                        ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                                        (Snackbar.message "Invalid date") m.s.msgQueue}}
                        , Cmd.none
                        )
        UsageDateToChanged s ->
            let
                s_ = m.s
                usage_ = s_.usage
            in
                case Iso8601.toTime s of
                    Ok t ->
                        ({m | s = {s_ | usage = {usage_ | dateTo = t}}}, Cmd.none)
                    Err _ ->
                        ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                                        (Snackbar.message "Invalid date") m.s.msgQueue}}
                        , Cmd.none
                        )

        GetAllUsage ->
            (m, (List.map
                     (\{keyId} -> Request.Rcs.getUsage m keyId m.s.usage.dateFrom m.s.usage.dateTo)
                     m.s.users) |> Cmd.batch)
        GetUsage k ->
            (m, Request.Rcs.getUsage m k m.s.usage.dateFrom m.s.usage.dateTo)
        GotUsage (Ok i) ->
            let
                s_ = m.s
                usage_ = s_.usage
                stats_ = usage_.stats
            in
                ({m | s = {s_ | usage = {usage_ | stats = Dict.insert i.keyId i stats_}}}
                 , Cmd.none
                 )
        GotUsage (Err err) ->
            let
                s_ = m.s
                usage_ = s_.usage
            in
                ( {m | s = {s_ | usage = {usage_ | stats = Dict.empty}, msgQueue = Snackbar.addMessage
                                (Snackbar.message ("Failed to fetch usage stats: " ++ (explainHttpError err))) m.s.msgQueue}}
                , Cmd.none
                )

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
                    usage_ = s_.usage
                    oneDayEarlier = \x -> (Time.posixToMillis x) - 24 * 3600 * 1000 |> Time.millisToPosix
                in
                    ({m | t = a, s = {s_ | usage = {usage_ | dateFrom = oneDayEarlier a, dateTo = a}}}, Cmd.none)
            else
                ({ m | t = a}, Cmd.none)

        NoOp ->
            (m, Cmd.none)
        Discard _ ->
            (m, Cmd.none)

refreshTabMsg m t =
    case t of
        Msg.General -> Cmd.none
        Msg.Users -> Cmd.batch [Request.Rcs.listUsers m, Request.Aws.listPolicies m]
        Msg.Policies -> Request.Aws.listPolicies m
        Msg.Roles -> Request.Aws.listRoles m
        Msg.Usage ->
            (List.map
                 (\{keyId} -> Request.Rcs.getUsage m keyId m.s.usage.dateFrom m.s.usage.dateTo)
                 m.s.users)
                |> Cmd.batch


explainHttpError a =
    case a of
        Http.BadBody s ->
            "" ++ (ellipsize s)
        Http.Timeout ->
            "Request timed out"
        Http.NetworkError ->
            "Network error"
        Http.BadStatus s ->
            "Bad status " ++ String.fromInt s
        Http.BadUrl s ->
            "BadUrl. This shouldn't have happened"

ellipsize a =
    if String.length a > 40 then
        (String.left 40 a) ++ "..."
    else
        a

toggleStatus a =
    case a of
        "enabled" -> "disabled"
        _ -> "enabled"

addOrDeleteElement l a =
    if List.member a l then
        delElement l a
    else
        a :: l

delElement l a =
    List.filter (\x -> x /= a) l
