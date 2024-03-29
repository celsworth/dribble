module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Html.Lazy
import Model exposing (..)
import Model.Table
import Model.TorrentFilter
import Utils.Mouse as Mouse
import View.Details
import View.DragBar
import View.Logs
import View.Messages
import View.Preferences
import View.SpeedChart
import View.Summary
import View.Table
import View.TorrentGroups
import View.TorrentTable
import View.Utils.CssVariable
import View.Utils.Events exposing (onEscape)


view : Model -> Html Msg
view model =
    div (viewAttributes model)
        [ cssVariablesStyleTag
        , Html.Lazy.lazy View.DragBar.view model.resizeOp
        , contextMenuCloser model
        , View.Preferences.view model
        , View.Logs.view model
        , View.Messages.view model
        , navigation model
        , div [ class "flex" ]
            [ aside [ class "sidebar" ]
                [ View.TorrentGroups.view model
                , View.SpeedChart.view model
                ]
            , div [ class "main" ]
                [ View.TorrentTable.view model
                , View.Details.view model
                ]
            ]
        , View.Summary.view model
        ]


cssVariablesStyleTag : Html Msg
cssVariablesStyleTag =
    View.Utils.CssVariable.style
        [ ( "--table-cell-lr-padding"
          , String.fromInt View.Table.cellLrPadding ++ "px"
          )
        , ( "--table-header-cell-r-padding"
          , String.fromInt View.Table.headerCellRightPadding ++ "px"
          )
        ]


viewAttributes : Model -> List (Attribute Msg)
viewAttributes model =
    let
        resizingAttributes =
            viewAttributesForResizeOp model.resizeOp
    in
    resizingAttributes


viewAttributesForResizeOp : Maybe Model.Table.ResizeOp -> List (Attribute Msg)
viewAttributesForResizeOp resizeOp =
    case resizeOp of
        Just r ->
            [ class "resizing-x"
            , Mouse.onUp (\e -> AttributeResizeEnded r e.clientPos)
            , Mouse.onMove (\e -> AttributeResized r e.clientPos)
            ]

        Nothing ->
            []


contextMenuCloser : Model -> Html Msg
contextMenuCloser model =
    -- when we have a context menu open, this renders a full-page div
    -- that captures clicks to close the context menu.
    if model.contextMenu /= Nothing then
        div
            [ Mouse.onContextMenu (\_ -> ClearContextMenu)
            , onClick ClearContextMenu
            , class "context-menu-closer"
            ]
            []

    else
        text ""


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
                [ i [ class "icon-left fa-fw fas fa-cogs" ] []
                , text "Preferences"
                ]
            , li [ onClick ToggleLogsVisible ]
                [ i [ class "icon-left fa-fw fas fa-bars" ] []
                , text "Logs"
                ]
            ]
        ]
