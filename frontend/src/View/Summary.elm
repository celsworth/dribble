module View.Summary exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Rtorrent
import Utils.Filesize


view : Model -> Html Msg
view model =
    section [ class "summary" ]
        [ div [ class "session-traffic" ] (traffic model)
        , div [ class "system-info" ] (status model)
        ]


traffic : Model -> List (Html Msg)
traffic model =
    case model.prevTraffic of
        Just t ->
            [ trafficDirection model t.downTotal t.downDiff "fa-arrow-down"
            , trafficDirection model t.upTotal t.upDiff "fa-arrow-up"
            ]

        Nothing ->
            []


trafficDirection : Model -> Int -> Int -> String -> Html Msg
trafficDirection model total diff kls =
    div [ class "stat" ]
        [ i [ class <| "fas " ++ kls ] []
        , span []
            [ text <| Utils.Filesize.formatWith model.config.humanise.size total
            , text <| " (" ++ Utils.Filesize.formatWith model.config.humanise.speed diff ++ "/s)"
            ]
        ]


status : Model -> List (Html Msg)
status model =
    List.filterMap identity
        [ Maybe.map rtorrentSystemInfo model.rtorrentSystemInfo
        , Just <| websocketStatus model
        ]


websocketStatus : Model -> Html Msg
websocketStatus model =
    let
        faClass =
            if model.websocketConnected then
                "connected"

            else
                "disconnected"
    in
    span [] [ i [ class ("fas fa-circle " ++ faClass) ] [] ]


rtorrentSystemInfo : Model.Rtorrent.Info -> Html Msg
rtorrentSystemInfo info =
    text <|
        "rtorrent "
            ++ info.systemVersion
            ++ "/"
            ++ info.libraryVersion
            ++ " on "
            ++ info.hostname
            ++ ":"
            ++ String.fromInt info.listenPort
