module Request.Signature exposing (v2, v4)

import Model exposing (Model)
import Iso8601
import Url
import Util exposing (hash, hmacHex, hmacBase64)
import Crypto.HMAC
import Crypto.Hash
import Strftime
import Time
import Word.Bytes as Bytes
import Word.Hex as Hex


v4 : Model -> String -> String -> List (String, String) -> List (String, String) -> String -> String -> String
v4 m verb path qs headers service hashedPayload =
    let
        canonicalRequest = makeCanonicalRequest m verb path qs headers hashedPayload
        canonicalDate = Strftime.format "%Y%m%d" Time.utc m.t
        sts = String.join "\n" [ "AWS4-HMAC-SHA256"
                               , Util.amzDate m.t
                               , String.join "/" [ canonicalDate
                                                 , m.c.region
                                                 , service
                                                 , "aws4_request"
                                                 ]
                               , Crypto.Hash.sha256 canonicalRequest
                               ]
        digest =
            \message key ->
                Crypto.HMAC.digestBytes Crypto.HMAC.sha256
                    key
                    (Bytes.fromUTF8 message)
    in
        ("AWS4" ++ m.c.csAdminSecret)
            |> Bytes.fromUTF8
            |> digest canonicalDate
            |> digest m.c.region
            |> digest service
            |> digest "aws4_request"
            |> digest sts
            |> Hex.fromByteList

makeCanonicalRequest m verb path qs headers hashedPayload =
    let
        canonicalQs = qs
           |> List.foldl toCanonicalTuple []
           |> List.sort
        signedHeaders = headers |> List.map (\(h, _) -> h) |> List.sort
        canonicalHeaders = headers |> List.map (\(h, v) -> (String.toLower h, String.trim v)) |> List.sort
    in
        String.join "\n" [ verb
                         , path
                         , String.join "&" (List.map (\(k, v) -> k ++ "=" ++ v) canonicalQs)
                         , (String.join "\n" (List.map (\(h, v) -> h ++ ":" ++ v) canonicalHeaders)) ++ "\n"
                         , String.join ";" signedHeaders
                         , hashedPayload
                         ]
toCanonicalTuple (k, v) q =
    (Url.percentEncode k, Url.percentEncode v) :: q



-- we use v2 signatures for calls to 'native' riak_cs endpoints

v2 : String -> String -> String -> String -> String -> List (String, String) -> String -> String
v2 authSecret cmd5 verb ct date amzHeaders resource =
    let
        flattenedHeaders = List.map (\(h, v) -> h ++ ":" ++ v) amzHeaders |> String.join "\n"
        sts = String.join "\n" [ verb
                               , cmd5
                               , ct
                               , date
                               , flattenedHeaders
                               , resource
                               ]
    in
        hmacBase64 authSecret sts
