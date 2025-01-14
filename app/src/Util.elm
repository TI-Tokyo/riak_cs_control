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
import Retry
import Iso8601

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

isoDateToPosix : String -> Time.Posix
isoDateToPosix a =
    case Iso8601.toTime a of
        Ok s -> s
        Err _ -> Time.millisToPosix 0

stripMPBoundaries =
    String.split "\r\n"
      >> List.filter (\a -> (String.left 2 a) /= "--" && (String.left 8 a) /= "Content-" && a /= "")


maybeItems aa pfx =
    if aa == [] then
        ""
    else
        pfx ++ String.join ", " aa

maybeTags tt pfx =
    maybeItems (List.map (\t -> t.name ++ ":" ++ t.value) tt) pfx


pprintJson : String -> String
pprintJson a =
    let
        cfg =
            { indent = 4
            , columns = 50
            }
    in
    Result.withDefault "(bad json)" (Json.Print.prettyString cfg a)

nameFromArn : String -> String
nameFromArn s =
    case s |> String.split "/" |> List.reverse |> List.head of
        Just a -> a
        Nothing -> "bad-arn"


ellipsize : String -> Int -> String
ellipsize a n =
    if String.length a > n then
        (String.left n a) ++ "…"
    else
        a

retryConfig : List (Retry.Policy x)
retryConfig =
    [ Retry.maxDuration 7000
    , Retry.exponentialBackoff { interval = 250, maxInterval = 3000 }
    ]


compareByPosixTime f a b =
    case (a |> f |> Time.posixToMillis) < (b |> f |> Time.posixToMillis) of
        True -> LT
        False -> GT

subtract : List a -> List a -> List a
subtract l1 l2 =
    List.filter (\a -> not (List.member a l2)) l1

addOrDeleteElement : List a -> a -> List a
addOrDeleteElement l a =
    if List.member a l then
        delElement l a
    else
        a :: l

delElement l a =
    List.filter (\x -> x /= a) l
