module View exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onMouseLeave)
import Html.Events.Extra.Mouse
import Html.Lazy
import Model exposing (..)
import Model.Table
import View.Details
import View.Logs
import View.Messages
import View.Preferences
import View.Summary
import View.TorrentTable


view : Model -> Html Msg
view model =
    div (viewAttributes model)
        [ View.Preferences.view model
        , View.Logs.view model
        , View.Messages.view model
        , navigation model
        , View.TorrentTable.view model
        , View.Details.view model
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
        (\e -> TorrentAttributeResizeEnded resizeOp (reconstructClientPos e))
    , Html.Events.Extra.Mouse.onMove
        (\e -> TorrentAttributeResized resizeOp (reconstructClientPos e))
    ]


reconstructClientPos : { e | clientPos : ( Float, Float ) } -> Model.Table.MousePosition
reconstructClientPos event =
    {- this mess converts (x, y) to { x: x, y: y } -}
    let
        ( x, y ) =
            event.clientPos
    in
    { x = x, y = y }


navigation : Model -> Html Msg
navigation model =
    section
        [ class "navigation" ]
        [ div [ class "flex-container" ]
            [ button [ onClick ResetConfigClicked ] [ text "Reset Config" ]
            , button [ onClick SaveConfigClicked ] [ text "Save Config" ]
            ]
        , div [ class "flex-container" ]
            [ Html.Lazy.lazy filterInput model.config.filter.filter
            , Html.Lazy.lazy hamburgerButton model.hamburgerMenuVisible
            ]
        ]


filterInput : String -> Html Msg
filterInput filter =
    input
        [ placeholder "Filter"
        , class "filter"
        , value filter
        , onInput TorrentFilterChanged
        , type_ "text"
        ]
        []


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
