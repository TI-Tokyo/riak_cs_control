module View exposing (view)

import View.General
import View.User
import View.Policy
import View.Role
import View.SAMLProvider
import View.Usage
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
                    , Html.span [ TopAppBar.title ]
                        [ img [src "images/logo.png", style "object-fit" "contain"] [] ]
                    ]
              , TopAppBar.section [ TopAppBar.alignEnd ]
                  [ Html.span [ TopAppBar.alignEnd ]
                        [ text m.c.csUrl ]
                  ]
              ]
        ]


listWhat m =
    case m.s.activeTab of
        Msg.General -> GetServerInfo
        Msg.Users -> ListUsers
        Msg.Policies -> ListPolicies
        Msg.Roles -> ListRoles
        Msg.SAMLProviders -> GetAllSAMLProviders
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
                                [ text "Users" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Usage)
                                )
                                [ text "Disk usage" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Policies)
                                )
                                [ text "Policies" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Roles)
                                )
                                [ text "Roles" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.SAMLProviders)
                                )
                                [ text "SAML Providers" ]
                          ]
                    ]
              ]
        , Html.div [ DismissibleDrawer.appContent ]
            [ makeContents m ]
        ]


makeContents m =
    case m.s.activeTab of
        Msg.General -> View.General.makeContent m
        Msg.Users -> View.User.makeContent m
        Msg.Roles -> View.Role.makeContent m
        Msg.Policies -> View.Policy.makeContent m
        Msg.Usage -> View.Usage.makeContent m
        Msg.SAMLProviders -> View.SAMLProvider.makeContent m
