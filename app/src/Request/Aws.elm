module Request.Aws exposing
    ( listUsers
    , listPolicies
    , createPolicy
    , deletePolicy
    , listRoles
    , createRole
    , deleteRole
    , listSAMLProviders
    , getSAMLProvider
    , createSAMLProvider
    , deleteSAMLProvider
    , attachUserPolicy
    , detachUserPolicy
    , listAttachedRolePolicies
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Xml
import Request.Signature as Signature
import Util exposing (hash)

import Http
import HttpBuilder
import HttpBuilder.Task
import Url.Builder as UrlBuilder
import Url
import Time
import Strftime
import Http.Xml
import Crypto.Hash
import Task
import Retry
import Xml.Decode


listUsers : Model -> Cmd Msg
listUsers m =
    iamCall m "ListUsers" []
        (Http.Xml.expectXml GotUserList Data.Xml.decodeUsers)


listPolicies : Model -> Cmd Msg
listPolicies m =
    iamCall m "ListPolicies" []
        (Http.Xml.expectXml GotPolicyList Data.Xml.decodePolicies)

createPolicy : Model -> Cmd Msg
createPolicy m =
    iamCall m "CreatePolicy"
        ([ ("Path", m.s.newPolicyPath)
         , ("PolicyDocument", m.s.newPolicyPolicyDocument)
         , ("PolicyName", m.s.newPolicyName)
         ] ++ (maybeAdd "Description" m.s.newPolicyDescription)
           ++ (maybeAddTags m.s.newPolicyTags)
        )
        (Http.Xml.expectXml PolicyCreated Data.Xml.decodePolicyCreated)

deletePolicy : Model -> String -> Cmd Msg
deletePolicy m a =
    iamCall m "DeletePolicy"
        [ ("PolicyArn", a) ]
        (Http.Xml.expectXml PolicyDeleted Data.Xml.decodeEmptySuccessResponse)


listRoles : Model -> Cmd Msg
listRoles m =
    iamCall m "ListRoles" []
        (Http.Xml.expectXml GotRoleList Data.Xml.decodeRoles)

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
        (Http.Xml.expectXml RoleCreated Data.Xml.decodeRoleCreated)

deleteRole : Model -> String -> Cmd Msg
deleteRole m a =
    iamCall m "DeleteRole"
        [ ("RoleName", a) ]
        (Http.Xml.expectXml RoleDeleted Data.Xml.decodeEmptySuccessResponse)


listSAMLProviders : Model -> Cmd Msg
listSAMLProviders m =
    iamCall m "ListSAMLProviders" []
        (Http.Xml.expectXml GotSAMLProviderList Data.Xml.decodeSAMLProviders)

getSAMLProvider : Model -> String -> Cmd Msg
getSAMLProvider m a =
    iamCall m "GetSAMLProvider"
        [("SAMLProviderArn", a)]
        (Http.Xml.expectXml GotSAMLProvider (Data.Xml.decodeGetSAMLProviderResponse a))

-- getSamlProviderResolver u a =
--     case a of
--         Http.GoodStatus_ _ body ->
--             case Xml.Decode.run (Data.Xml.decodeGetSAMLProviderResponse u) body of
--                 Ok b ->
--                     Ok b
--                 Err err ->
--                     Err (Http.BadBody "Bad XML")
--         Http.BadStatus_ md _ ->
--             Err (Http.BadStatus md.statusCode)
--         _ ->
--             Err (Http.NetworkError)


createSAMLProvider : Model -> Cmd Msg
createSAMLProvider m =
    iamCall m "CreateSAMLProvider"
        ([ ("Name", m.s.newSAMLProviderName)
         , ("SAMLMetadataDocument", m.s.newSAMLProviderSAMLMetadataDocument)
         ] ++ (maybeAddTags m.s.newSAMLProviderTags)
        )
        (Http.Xml.expectXml SAMLProviderCreated Data.Xml.decodeSAMLProviderCreated)

deleteSAMLProvider : Model -> String -> Cmd Msg
deleteSAMLProvider m a =
    iamCall m "DeleteSAMLProvider"
        [ ("SAMLProviderArn", a) ]
        (Http.Xml.expectXml SAMLProviderDeleted Data.Xml.decodeEmptySuccessResponse)



attachUserPolicy : Model -> String -> Cmd Msg
attachUserPolicy m a =
    let
        u = Model.userBy m .arn
            (Maybe.withDefault "" m.s.openAttachUserPoliciesDialogFor)
    in
    iamCall m "AttachUserPolicy"
        [ ("UserName", u.userName)
        , ("PolicyArn", a)
        ]
        (Http.Xml.expectXml UserPolicyAttached Data.Xml.decodeEmptySuccessResponse)

detachUserPolicy : Model -> String -> Cmd Msg
detachUserPolicy m a =
    let
        u = Model.userBy m .arn
            (Maybe.withDefault "" m.s.openEditUserPoliciesDialogFor)
    in
    iamCall m "DetachUserPolicy"
        [ ("UserName", u.userName)
        , ("PolicyArn", a)
        ]
        (Http.Xml.expectXml UserPolicyDetached Data.Xml.decodeEmptySuccessResponse)

listAttachedRolePolicies : Model -> String -> Cmd Msg
listAttachedRolePolicies m a =
    iamCall m "ListAttachedRolePolicies"
        [ ("RoleName", a)
        ]
        (Http.Xml.expectXml UserPolicyDetached Data.Xml.decodePolicies)



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

-- iamCallAsTask m a qs_ resolver =
--     let
--         qs = List.sort (("Action", a) :: qs_)
--         payloadHash = Crypto.Hash.sha256 (canonicalizeQs qs)
--         stdHeaders = makeStdHeaders m payloadHash
--         authHeader = ("Authorization", (makeAuthHeader m "POST" "/iam" [("Action", a)] stdHeaders "iam" payloadHash))
--     in
--         UrlBuilder.crossOrigin m.c.csUrl [ "iam" ] [ UrlBuilder.string "Action" a ]
--             |> HttpBuilder.Task.post
--             |> HttpBuilder.Task.withUrlEncodedBody qs
--             |> HttpBuilder.Task.withHeaders (authHeader :: stdHeaders)
--             |> HttpBuilder.Task.withResolver resolver
--             |> HttpBuilder.Task.toTask

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

