module Util exposing (..)

import Time
import HmacSha1
import HmacSha1.Key
import SHA1
import Strftime
import Json.Print

hash : String -> String
hash a =
    a |> SHA1.fromString |> SHA1.toHex

hmacHex : String -> String -> String
hmacHex k a =
    a |> HmacSha1.fromString (HmacSha1.Key.fromString k) |> HmacSha1.toHex

hmacBase64 : String -> String -> String
hmacBase64 k a =
    a |> HmacSha1.fromString (HmacSha1.Key.fromString k) |> HmacSha1.toBase64

amzDate : Time.Posix -> String
amzDate t =
    Strftime.format "%Y%m%dT%H%M%SZ" Time.utc t


stripMPBoundaries =
    String.split "\r\n"
      >> List.filter (\a -> (String.left 2 a) /= "--" && (String.left 8 a) /= "Content-" && a /= "")


maybeTags aa pfx =
    if aa == [] then
        ""
    else
        pfx ++ String.join "; " (List.map (\t -> t.name ++ ":" ++ t.value) aa)

pprintJson a =
    let
        cfg =
            { indent = 4
            , columns = 50
            }
    in
    Result.withDefault "(bad json)" (Json.Print.prettyString cfg a)
