module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Html.Events.Extra.Mouse
import Html.Lazy
import Model exposing (..)
import Model.MousePosition
import Model.Table
import Model.TorrentFilter
import View.Details
import View.GroupLists
import View.Logs
import View.Messages
import View.Preferences
import View.SpeedChart
import View.Summary
import View.TorrentTable
import View.Utils.Events exposing (onEscape)


view : Model -> Html Msg
view model =
    div (viewAttributes model)
        [ View.Preferences.view model
        , View.Logs.view model
        , View.Messages.view model
        , navigation model
        , div [ class "flex" ]
            [ aside [ class "sidebar" ]
                [ View.GroupLists.view model
                , View.SpeedChart.view model
                ]
            , div [ class "main" ]
                [ View.TorrentTable.view model
                , View.Details.view model
                ]
            ]
        , View.Summary.view model
        ]


viewAttributes : Model -> List (Attribute Msg)
viewAttributes model =
    let
        resizingAttributes =
            Maybe.map viewAttributesForResizeOp model.resizeOp
                |> Maybe.withDefault []
    in
    List.append [] resizingAttributes


viewAttributesForResizeOp : Model.Table.ResizeOp -> List (Attribute Msg)
viewAttributesForResizeOp resizeOp =
    [ class "resizing-x"
    , Html.Events.Extra.Mouse.onUp
        (\e -> AttributeResizeEnded resizeOp (Model.MousePosition.reconstructClientPos e))
    , Html.Events.Extra.Mouse.onMove
        (\e -> AttributeResized resizeOp (Model.MousePosition.reconstructClientPos e))
    ]


navigation : Model -> Html Msg
navigation model =
    section [ class "navigation" ]
        [ div [ class "flex" ]
            [ button [ onClick ResetConfigClicked ] [ text "Reset Config" ]
            , button [ onClick SaveConfigClicked ] [ text "Save Config" ]
            ]
        , div [ class "flex" ]
            [ Html.Lazy.lazy2 filterInput model.config.filter model.torrentFilter
            , Html.Lazy.lazy hamburgerButton model.hamburgerMenuVisible
            ]
        ]


filterInput : Model.TorrentFilter.Config -> Model.TorrentFilter.TorrentFilter -> Html Msg
filterInput filterConfig filter =
    let
        kls =
            case filter.filter of
                Err _ ->
                    class "filter error"

                _ ->
                    class "filter"
    in
    div [ class "filter" ]
        [ button [ onClick ResetFilterClicked ]
            [ i [ class "fas fa-times" ] [] ]
        , input
            [ placeholder "Filter"
            , kls
            , value filterConfig.filter
            , onInput TorrentFilterChanged
            , onEscape ResetFilterClicked
            , type_ "text"
            ]
            []
        ]


hamburgerButton : Bool -> Html Msg
hamburgerButton visible =
    let
        menu =
            if visible then
                hamburgerMenu

            else
                text ""
    in
    div [ class "hamburger-button" ]
        [ button [ onClick (SetHamburgerMenuVisible True) ] [ i [ class "fas fa-bars" ] [] ]
        , menu
        ]


hamburgerMenu : Html Msg
hamburgerMenu =
    div
        [ class "hamburger-menu"
        , onMouseLeave (SetHamburgerMenuVisible False)
        ]
        [ ul []
            [ li [ onClick TogglePreferencesVisible ]
                [ i [ class "fas fa-cogs" ] []
                , text "Preferences"
                ]
            , li [ onClick ToggleLogsVisible ]
                [ i [ class "fas fa-bars" ] []
                , text "Logs"
                ]
            ]
        ]
