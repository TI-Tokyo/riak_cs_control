module View exposing (view)

import View.General
import View.User
import View.Role
import View.Policy
import View.Usage
import Model exposing (Model)
import Msg exposing (Msg(..))

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (style, attribute, src)
import Material.TopAppBar as TopAppBar
import Material.Tab as Tab
import Material.TabBar as TabBar
import Material.Snackbar as Snackbar
import Material.Button as Button
import Material.IconButton as IconButton
import Material.TextField as TextField
import Material.Typography as Typography
import Material.Dialog as Dialog
import Material.Icons as Filled
import Material.Icons.Outlined as Outlined


view : Model -> Html Msg
view m =
    Html.div [ Typography.typography ]
        [ Html.div [] (makeTopAppBar m)
        , Html.div [TopAppBar.fixedAdjust] (makeTabs m)
        , Html.div [] [makeContents m]
        , Snackbar.snackbar
              (Snackbar.config { onClosed = SnackbarClosed })
                  m.s.msgQueue
        ]


makeTopAppBar m =
    [ TopAppBar.regular (TopAppBar.config |> TopAppBar.setFixed True)
          [ TopAppBar.row []
                [ TopAppBar.section [ TopAppBar.alignStart ]
                      [ IconButton.iconButton
                            (IconButton.config
                            |> IconButton.setOnClick (listWhat m)
                            )
                            (IconButton.icon "refresh")
                      , Html.span [ TopAppBar.title ]
                          [ img [src "images/logo.png", style "object-fit" "contain"] [] ]
                      ]
                , TopAppBar.section [ TopAppBar.alignEnd ]
                    [ Html.span [ TopAppBar.alignEnd ]
                          [ text m.c.csUrl ]
                    ]
                ]
          ]
    ]

listWhat m =
    case m.s.activeTab of
        Msg.General -> GetServerInfo
        Msg.Users -> ListUsers
        Msg.Roles -> ListRoles
        Msg.Policies -> ListPolicies
        Msg.Usage -> ListAllBuckets


makeTabs m =
        [ TabBar.tabBar TabBar.config
              (Tab.tab
               (Tab.config
               |> Tab.setActive (m.s.activeTab == Msg.General)
               |> Tab.setOnClick (TabClicked Msg.General)
               )
               { label = "General", icon = Nothing }
          )
              [ Tab.tab
                    (Tab.config
                    |> Tab.setActive (m.s.activeTab == Msg.Users)
                    |> Tab.setOnClick (TabClicked Msg.Users)
                    )
                    { label = "Users", icon = Nothing }
              , Tab.tab
                    (Tab.config
                    |> Tab.setActive (m.s.activeTab == Msg.Policies)
                    |> Tab.setOnClick (TabClicked Msg.Policies)
                    )
                    { label = "Policies", icon = Nothing }
              , Tab.tab
                    (Tab.config
                    |> Tab.setActive (m.s.activeTab == Msg.Roles)
                    |> Tab.setOnClick (TabClicked Msg.Roles)
                    )
                    { label = "Roles", icon = Nothing }
              , Tab.tab
                    (Tab.config
                    |> Tab.setActive (m.s.activeTab == Msg.Usage)
                    |> Tab.setOnClick (TabClicked Msg.Usage)
                    )
                    { label = "Usage", icon = Nothing }
              ]
    ]


makeContents m =
    case m.s.activeTab of
        Msg.General -> View.General.makeContent m
        Msg.Users -> View.User.makeContent m
        Msg.Roles -> View.Role.makeContent m
        Msg.Policies -> View.Policy.makeContent m
        Msg.Usage -> View.Usage.makeContent m
