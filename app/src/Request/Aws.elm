module Request.Aws exposing
    ( listUsers
    , listRoles
    , listPolicies
    , getDiskUsage
    , createRole
    , createPolicy
    , deleteRole
    , deletePolicy
    , attachUserPolicy
    , detachUserPolicy
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data exposing (User, Role, Policy, DiskUsage)
import AwsXml
import Request.Signature as Signature
import Util exposing (hash)

import Http
import HttpBuilder
import Url.Builder as UrlBuilder
import Url
import Time
import Strftime
import Http.Xml
import Crypto.Hash


listUsers : Model -> Cmd Msg
listUsers m =
    iamCall m "ListUsers" []
        (Http.Xml.expectXml GotUserList AwsXml.decodeUsers)

listPolicies : Model -> Cmd Msg
listPolicies m =
    iamCall m "ListPolicies" []
        (Http.Xml.expectXml GotPolicyList AwsXml.decodePolicies)

listRoles : Model -> Cmd Msg
listRoles m =
    iamCall m "ListRoles" []
        (Http.Xml.expectXml GotRoleList AwsXml.decodeRoles)

createPolicy : Model -> Cmd Msg
createPolicy m =
    iamCall m "CreatePolicy"
        ([ ("Path", m.s.newPolicyPath)
         , ("PolicyDocument", m.s.newPolicyPolicyDocument)
         , ("PolicyName", m.s.newPolicyName)
         ] ++ (maybeAdd "Description" m.s.newPolicyDescription)
           ++ (maybeAddTags m.s.newPolicyTags)
        )
        (Http.Xml.expectXml PolicyCreated AwsXml.decodePolicyCreated)

deletePolicy : Model -> String -> Cmd Msg
deletePolicy m a =
    iamCall m "DeletePolicy"
        [ ("PolicyArn", a) ]
        (Http.Xml.expectXml PolicyDeleted AwsXml.decodeEmptySuccessResponse)

createRole : Model -> Cmd Msg
createRole m =
    iamCall m "CreateRole"
        ([ ("RoleName", m.s.newRoleName)
         , ("Path", m.s.newRolePath)
         , ("AssumeRolePolicyDocument", m.s.newRoleAssumeRolePolicyDocument)
         , ("MaxSessionDuration", String.fromInt m.s.newRoleMaxSessionDuration)
         ] ++ (maybeAdd "Description" m.s.newRoleDescription)
           ++ (maybeAdd "PermissionsBoundary" m.s.newRolePermissionsBoundary)
           ++ (maybeAddTags m.s.newRoleTags)
        )
        (Http.Xml.expectXml RoleCreated AwsXml.decodeRoleCreated)

deleteRole : Model -> String -> Cmd Msg
deleteRole m a =
    iamCall m "DeleteRole"
        [ ("RoleName", a) ]
        (Http.Xml.expectXml RoleDeleted AwsXml.decodeEmptySuccessResponse)


attachUserPolicy : Model -> String -> Cmd Msg
attachUserPolicy m a =
    let
        u = Model.userByArn m
            (Maybe.withDefault "" m.s.openAttachUserPoliciesDialogFor)
    in
    iamCall m "AttachUserPolicy"
        [ ("UserName", u.userName)
        , ("PolicyArn", a)
        ]
        (Http.Xml.expectXml UserPolicyAttached AwsXml.decodeEmptySuccessResponse)

detachUserPolicy : Model -> String -> Cmd Msg
detachUserPolicy m a =
    let
        u = Model.userByArn m
            (Maybe.withDefault "" m.s.openEditUserPoliciesDialogFor)
    in
    iamCall m "DetachUserPolicy"
        [ ("UserName", u.userName)
        , ("PolicyArn", a)
        ]
        (Http.Xml.expectXml UserPolicyDetached AwsXml.decodeEmptySuccessResponse)



iamCall m a qs_ exp =
    let
        qs = List.sort (("Action", a) :: qs_)
        payloadHash = Crypto.Hash.sha256 (canonicalizeQs qs)
        stdHeaders = makeStdHeaders m payloadHash
        authHeader = ("Authorization", (makeAuthHeader m "POST" "/iam" [("Action", a)] stdHeaders "iam" payloadHash))
    in
        UrlBuilder.crossOrigin m.c.csUrl [ "iam" ] [ UrlBuilder.string "Action" a ]
            |> HttpBuilder.post
            |> HttpBuilder.withUrlEncodedBody qs
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect exp
            |> HttpBuilder.request

canonicalizeQs qs =
    qs |> List.sort |> List.map (\(q,s) -> q++"="++s) |> String.join "&"


maybeAdd s v_ =
    case v_ of
        Nothing -> []
        Just v -> [(s, v)]
maybeAddTags tt =
    if tt == [] then
        []
    else
        [("Tags", formatTags tt)]
formatTags tt =
    -- this will need to be reworked. Need examples.
    String.join ";" (List.map (\t -> t.name ++ "=" ++ t.value) tt)


getDiskUsage : Model -> Cmd Msg
getDiskUsage m =
    Cmd.none


makeStdHeaders m hashedPayload =
    [ ("x-amz-content-sha256", hashedPayload)
    , ("x-amz-date", Util.amzDate m.t)
    ]

justHostWithPort a =
    case Url.fromString a of
        Just u ->
            u.host ++ ":" ++ (Maybe.withDefault 8080 u.port_ |> String.fromInt)
        Nothing ->
            ""

makeAuthHeader m verb path qs headers service hashedPayload =
    let
        canonicalDate = Strftime.format "%Y%m%d" Time.utc m.t
        credential = String.join "/" [ m.c.csAdminKey
                                     , canonicalDate
                                     , m.c.region
                                     , service
                                     , "aws4_request"
                                     ]
        signedHeaders = headers |> List.map (\(h, _) -> h) |> List.sort

    in
        "AWS4-HMAC-SHA256 " ++
            String.join ","
                [ "Credential=" ++ credential
                , "SignedHeaders=" ++ String.join ";" signedHeaders
                , "Signature=" ++ (Signature.v4 m verb path (List.sort qs) headers service hashedPayload)
                ]

