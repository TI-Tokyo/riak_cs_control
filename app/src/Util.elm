module Util exposing (..)

import Time
import Array
import HmacSha1
import HmacSha1.Key
import SHA1
import Strftime
import Json.Print
import DateTime
import Calendar


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

amzDateToPosix : String -> Time.Posix
amzDateToPosix a =
    let
        ye = String.slice  0  4 a |> String.toInt |> Maybe.withDefault 0
        mo = String.slice  5  7 a |> String.toInt |> Maybe.withDefault 0
        da = String.slice  8 10 a |> String.toInt |> Maybe.withDefault 0
        ho = String.slice 12 14 a |> String.toInt |> Maybe.withDefault 0
        mi = String.slice 15 17 a |> String.toInt |> Maybe.withDefault 0
        se = String.slice 18 20 a |> String.toInt |> Maybe.withDefault 0
        dt = DateTime.fromRawParts
             { year = ye
             , month = Array.get mo Calendar.months |> Maybe.withDefault Time.Jan
             , day = da}
             {hours = ho, minutes = mi, seconds = se, milliseconds = 0}
    in
        case dt of
            Just x ->
                DateTime.toPosix x
            Nothing ->
                Time.millisToPosix 0


stripMPBoundaries =
    String.split "\r\n"
      >> List.filter (\a -> (String.left 2 a) /= "--" && (String.left 8 a) /= "Content-" && a /= "")


maybeTags aa pfx =
    if aa == [] then
        ""
    else
        pfx ++ String.join "; " (List.map (\t -> t.name ++ ":" ++ t.value) aa)


pprintJson : String -> String
pprintJson a =
    let
        cfg =
            { indent = 4
            , columns = 50
            }
    in
    Result.withDefault "(bad json)" (Json.Print.prettyString cfg a)


-- timeBefore t a =
--     (Time.posixToMillis t - a * 1000) |> Time.millisToPosix


ellipsize : String -> Int -> String
ellipsize a n =
    if String.length a > n then
        (String.left n a) ++ "…"
    else
        a
