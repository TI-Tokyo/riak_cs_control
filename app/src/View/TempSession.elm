module View.TempSession exposing (makeContent)

import Model exposing (Model, SortByField(..))
import Msg exposing (Msg(..))
import Data.Struct
import View.Common
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, src)
import Html.Events exposing (onClick, onInput)
import Material.Card as Card
import Material.Fab as Fab
import Material.Button as Button
import Material.IconButton as IconButton
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Iso8601
import Time


makeContent m =
    div View.Common.topContentStyle
        [ div View.Common.subTabStyle (View.Common.makeSubTab m)
        , div View.Common.cardStyle (makeTempSessions m)
        ]

makeTempSessions m =
    case m.s.tempSessions |> filter m |> sort m |> List.map makeTempSession of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    List.filter (\a -> String.contains m.s.tempSessionFilterValue a.role.roleName) aa

sort m aa =
    let
        aa0 =
            case m.s.tempSessionSortBy of
                CreateDate -> List.sortWith (\a b -> case (Time.posixToMillis a.created) < (Time.posixToMillis b.created) of
                                                         True -> LT
                                                         False -> GT
                                            ) aa
                _ -> aa
    in
        if m.s.tempSessionSortOrder then aa0 else List.reverse aa0

makeTempSession a =
    let
        name = a.role.roleName
    in
        Card.card Card.config
            { blocks =
                  ( Card.block <|
                        div View.Common.cardInnerHeaderStyle [ text name ]
                  , [ Card.block <|
                          div View.Common.cardInnerContentStyle
                          [ a |> cardContent |> text ]
                    , Card.block <|
                        div View.Common.cardInnerContentStyle
                            [ div []
                                  [ "InlinePolicy:" |> text ]
                            , div (View.Common.cardInnerContentStyle ++ View.Common.jsonInsetStyle)
                                  [ a |> cardPolicyDocument |> text ]
                            ]
                    ]
                  )
            , actions = tempSessionCardActions a
            }

cardContent a =
    "    Credentials: " ++ a.credentials.accessKeyId ++ ":" ++ a.credentials.secretAccessKey ++ "\n" ++
    "AssumedRoleUser: " ++ a.assumedRoleUser.arn ++ "\n" ++
    "        Created: " ++ (Iso8601.fromTime a.created) ++ "\n" ++
    "DurationSeconds: " ++ (String.fromInt a.durationSeconds) ++ "\n" ++
    "        Expires: " ++ (Iso8601.fromTime a.credentials.expiration)
        ++ Util.maybeItems (List.map Util.nameFromArn a.sessionPolicies) "\nSessionPolicies: "

cardPolicyDocument a =
    Util.pprintJson
        (Maybe.withDefault "" a.role.assumeRolePolicyDocument)


tempSessionCardActions a =
    Just <|
        Card.actions
            { buttons =
                  []
            , icons = []
            }
