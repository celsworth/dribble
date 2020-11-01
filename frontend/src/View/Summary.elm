module View.Summary exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Html.Lazy
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Preferences as MP
import Model.Rtorrent
import Model.Traffic exposing (Traffic)
import Utils.Filesize


view : Model -> Html Msg
view model =
    section [ class "summary" ]
        [ Html.Lazy.lazy2 traffic model.config model.prevTraffic
        , Html.Lazy.lazy quickPreferences model.config
        , Html.Lazy.lazy2 status model.rtorrentSystemInfo model.websocketConnected
        ]


traffic : Config -> Maybe Traffic -> Html Msg
traffic config maybeTraffic =
    case maybeTraffic of
        Just t ->
            div [ class "session-traffic" ]
                [ trafficDirection config t.downTotal t.downDiff "fa-arrow-down"
                , trafficDirection config t.upTotal t.upDiff "fa-arrow-up"
                ]

        Nothing ->
            text ""


trafficDirection : Config -> Int -> Int -> String -> Html Msg
trafficDirection config total diff kls =
    div [ class "stat" ]
        [ i [ class <| "fas " ++ kls ] []
        , span []
            [ text <| Utils.Filesize.formatWith config.humanise.size total
            , text <| " (" ++ Utils.Filesize.formatWith config.humanise.speed diff ++ "/s)"
            ]
        ]


quickPreferences : Config -> Html Msg
quickPreferences config =
    div [ class "quickpref" ]
        [ input
            [ type_ "checkbox"
            , checked config.enableContextMenus
            , onClick <|
                SetPreference (MP.EnableContextMenus (not config.enableContextMenus))
            ]
            []
        , span [] [ text "Custom context menus" ]
        ]


status : Maybe Model.Rtorrent.Info -> Bool -> Html Msg
status rtorrentSystemInfo websocketConnected =
    div [ class "system-info" ] <|
        List.filterMap identity
            [ Maybe.map rtorrentSystemInfoText rtorrentSystemInfo
            , Just <| websocketStatus websocketConnected
            ]


websocketStatus : Bool -> Html Msg
websocketStatus websocketConnected =
    let
        faClass =
            if websocketConnected then
                "connected"

            else
                "disconnected"
    in
    span [] [ i [ class ("fas fa-circle " ++ faClass) ] [] ]


rtorrentSystemInfoText : Model.Rtorrent.Info -> Html Msg
rtorrentSystemInfoText info =
    text <|
        "rtorrent "
            ++ info.systemVersion
            ++ "/"
            ++ info.libraryVersion
            ++ " on "
            ++ info.hostname
            ++ ":"
            ++ String.fromInt info.listenPort
