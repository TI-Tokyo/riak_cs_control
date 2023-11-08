module Request.Rcs exposing
    ( getServerInfo
    , listUsers
    , createUser
    , deleteUser
    , updateUser
    , getUsage
    )

import Model exposing (Model)
import Data.Struct exposing (User)
import Data.Json
import Msg exposing (Msg(..))
import Request.Signature as Signature
import Util exposing (hash)

import Iso8601
import Http
import HttpBuilder
import Url.Builder
import Time
import Json.Encode
import Strftime
import Json.Encode
import MD5
import Base64
import Bytes.Extra
import Url


getServerInfo : Model -> Cmd Msg
getServerInfo m =
    let
        cmd5 = md5b64 ""
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("content-type", ct)
            , ("x-amz-date", date)
            ]
        sig = Signature.v2 m.c.csAdminSecret cmd5 "GET" ct date (extractAmzHeaders stdHeaders) "/riak-cs/info"
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
        Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "info" ] []
            |> HttpBuilder.get
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectJson GotServerInfo Data.Json.decodeServerInfo)
            |> HttpBuilder.request


listUsers : Model -> Cmd Msg
listUsers m =
    let
        cmd5 = md5b64 ""
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("content-type", ct)
            , ("x-amz-date", date)
            ]
        sig = Signature.v2 m.c.csAdminSecret cmd5 "GET" ct date (extractAmzHeaders stdHeaders) "/riak-cs/users"
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
        Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "users" ] []
            |> HttpBuilder.get
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectString GotUserListMultipart)
            |> HttpBuilder.request


createUser : Model -> Cmd Msg
createUser m  =
    let
        json = Json.Encode.object [ ("name", Json.Encode.string m.s.newUserName)
                                  , ("email", Json.Encode.string m.s.newUserEmail)
                                  , ("path", Json.Encode.string m.s.newUserPath)
                                  ]
        body = json |> Json.Encode.encode 0
        cmd5 = md5b64 body
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("x-amz-date", date)
            ]
        sig = Signature.v2 m.c.csAdminSecret cmd5 "POST" ct date (extractAmzHeaders stdHeaders) "/riak-cs/user"
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
       Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "user" ] []
            |> HttpBuilder.post
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectWhatever UserCreated)
            |> HttpBuilder.withStringBody ct body
            |> HttpBuilder.request


updateUser : Model -> Cmd Msg
updateUser m  =
    let
        u = Maybe.withDefault Data.Struct.dummyUser m.s.openEditUserDialogFor
        json = Json.Encode.object [ ("id", Json.Encode.string u.userId)
                                  , ("name", Json.Encode.string u.userName)
                                  , ("email", Json.Encode.string u.email)
                                  , ("path", Json.Encode.string u.path)
                                  , ("status", Json.Encode.string u.status)
                                  , ("new_key_secret", Json.Encode.bool m.s.generateNewCredsForEditedUser)
                                  ]
        body = json |> Json.Encode.encode 0
        cmd5 = md5b64 body
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("x-amz-date", date)
            ]
        sig = Signature.v2 m.c.csAdminSecret cmd5 "PUT" ct date (extractAmzHeaders stdHeaders) "/riak-cs/user"
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
       Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "user" ] []
            |> HttpBuilder.put
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectWhatever UserCreated)
            |> HttpBuilder.withStringBody ct body
            |> HttpBuilder.request


deleteUser : Model -> String -> Cmd Msg
deleteUser m a =
    let
        userKey = Url.percentEncode a
        cmd5 = md5b64 ""
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("content-type", ct)
            , ("x-amz-date", date)
            ]
        sig = Signature.v2 m.c.csAdminSecret cmd5 "DELETE" ct date (extractAmzHeaders stdHeaders) ("/riak-cs/user/" ++ userKey)
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
       Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "user", userKey ] []
            |> HttpBuilder.delete
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectWhatever UserDeleted)
            |> HttpBuilder.request


getUsage : Model -> String -> Time.Posix -> Time.Posix -> Cmd Msg
getUsage m k t0 t9 =
    let
        cmd5 = md5b64 ""
        date = rfc1123Date m.t
        ct = "application/json"
        stdHeaders =
            [ ("accept", ct)
            , ("content-md5", cmd5)
            , ("content-type", ct)
            , ("x-amz-date", date)
            ]
        path = Url.Builder.absolute [ "riak-cs", "usage", k, "bj" ]
            []
        sig = Signature.v2 m.c.csAdminSecret cmd5 "GET" ct date (extractAmzHeaders stdHeaders) path
        authHeader = ("Authorization", makeAuthHeader m sig)
    in
        Url.Builder.crossOrigin m.c.csUrl [ "riak-cs", "usage", k, "bj" ]
            [ Url.Builder.string "s" (Iso8601.fromTime t0)
            , Url.Builder.string "e" (Iso8601.fromTime t9)
            ]
            |> HttpBuilder.get
            |> HttpBuilder.withHeaders (authHeader :: stdHeaders)
            |> HttpBuilder.withExpect (Http.expectJson GotUsage (Data.Json.decodeUsage k))
            |> HttpBuilder.request



rfc1123Date t =
    Strftime.format "%a, %d %b %Y %H:%M:%S +0000Z" Time.utc t

extractAmzHeaders hh =
    List.filter (\(h, _) -> String.left 6 h == "x-amz-") hh

makeAuthHeader m sig =
    "AWS " ++ m.c.csAdminKey ++ ":" ++ sig

md5b64 a =
    case Bytes.Extra.fromByteValues (MD5.bytes a) |> Base64.fromBytes of
        Just s ->
            s
        Nothing ->
            ""
