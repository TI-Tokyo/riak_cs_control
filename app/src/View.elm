module View exposing (view)

import View.General
import View.User
import View.Usage
import View.Policy
import View.Role
import View.SAMLProvider
import View.TempSession
import Model exposing (Model)
import Msg exposing (Msg(..))

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, attribute, src)
import Material.Drawer.Dismissible as DismissibleDrawer
import Material.TopAppBar as TopAppBar
import Material.Snackbar as Snackbar
import Material.Button as Button
import Material.IconButton as IconButton
import Material.List as List
import Material.List.Item as ListItem
import Material.Typography as Typography


view : Model -> Html Msg
view m =
    Html.div [ Typography.typography ]
        [ Html.div [] [makeTopAppBar m]
        , Html.div [TopAppBar.fixedAdjust] [makeDrawer m]
        , Snackbar.snackbar
              (Snackbar.config { onClosed = SnackbarClosed })
                  m.s.msgQueue
        ]


makeTopAppBar m =
    TopAppBar.regular
        (TopAppBar.config
        |> TopAppBar.setFixed True
        |> TopAppBar.setAttributes [ style "z-index" "20" ])
        [ TopAppBar.row []
              [ TopAppBar.section [ TopAppBar.alignStart ]
                    [ IconButton.iconButton
                          (IconButton.config
                          |> IconButton.setOnClick OpenTopDrawer
                          |> IconButton.setAttributes
                               [ TopAppBar.navigationIcon ])
                          (IconButton.icon "menu")
                    , IconButton.iconButton
                          (IconButton.config
                          |> IconButton.setOnClick (listWhat m)
                          )
                          (IconButton.icon "refresh")
                    , text (activeTabName m)
                    ]
              , TopAppBar.section [ TopAppBar.alignEnd ]
                  [ Html.span [ TopAppBar.alignEnd, style "padding" "0 1em" ]
                        [ text m.c.csUrl ]
                  , Html.span [ TopAppBar.alignEnd ]
                      [ img [src "images/logo.png", style "object-fit" "contain"] [] ]
                  ]
              ]
        ]


listWhat m =
    case m.s.activeTab of
        Msg.General -> GetServerInfo
        Msg.Users -> ListUsers
        Msg.Policies -> ListPolicies
        Msg.Roles -> ListRoles
        Msg.SAMLProviders -> ListSAMLProviders
        Msg.TempSessions -> ListTempSessions
        Msg.Usage -> ListAllBuckets


makeDrawer m =
    Html.div
        [ style "display" "flex"
        , style "flex-flow" "row nowrap"
        ]
        [ DismissibleDrawer.drawer
              (DismissibleDrawer.config
              |> DismissibleDrawer.setOpen m.s.topDrawerOpen
              )
              [ DismissibleDrawer.content []
                    [ List.list List.config
                          ( ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.General)
                                )
                                [ text "CS node" ]
                          )
                          [ ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Users)
                                )
                                [ itemWithCount "Users" m.s.users ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Usage)
                                )
                                [ text "Disk usage" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Policies)
                                )
                                [ itemWithCount "Policies" m.s.policies ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Roles)
                                )
                                [ itemWithCount "Roles" m.s.roles ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.SAMLProviders)
                                )
                                [ itemWithCount "SAML Providers" m.s.samlProviders ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.TempSessions)
                                )
                                [ itemWithCount "Temp sessions" m.s.tempSessions ]
                          ]
                    ]
              ]
        , Html.div [ DismissibleDrawer.appContent ]
            [ makeContents m ]
        ]

itemWithCount s a =
     s ++ " (" ++ (List.length a |> String.fromInt) ++ ")" |> text

makeContents m =
    case m.s.activeTab of
        Msg.General -> View.General.makeContent m
        Msg.Users -> View.User.makeContent m
        Msg.Roles -> View.Role.makeContent m
        Msg.Policies -> View.Policy.makeContent m
        Msg.Usage -> View.Usage.makeContent m
        Msg.SAMLProviders -> View.SAMLProvider.makeContent m
        Msg.TempSessions -> View.TempSession.makeContent m

activeTabName m =
    case m.s.activeTab of
        Msg.General -> ""
        Msg.Users -> "Users"
        Msg.Roles -> "Roles"
        Msg.Policies -> "Policies"
        Msg.Usage -> "Disk usage & bucket stats"
        Msg.SAMLProviders -> "SAML providers"
        Msg.TempSessions -> "Temp sessions for federated users"
