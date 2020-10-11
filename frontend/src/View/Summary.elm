module View.Summary exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Model.Rtorrent
import Utils.Filesize


view : Model -> Html Msg
view model =
    section [ class "summary" ]
        [ div [ class "flex" ] (viewComponents model)
        , traffic model
        ]


viewComponents : Model -> List (Html Msg)
viewComponents model =
    List.filterMap identity
        [ Just <| websocketStatus model
        , Maybe.map rtorrentSystemInfo model.rtorrentSystemInfo
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
    div [] [ i [ class ("fas fa-circle " ++ faClass) ] [] ]


traffic : Model -> Html Msg
traffic model =
    case model.prevTraffic of
        Just t ->
            div [ class "session-traffic" ]
                [ div [ class "stat" ]
                    [ i [ class "fas fa-arrow-down" ] []
                    , span []
                        [ text <| Utils.Filesize.formatWith model.config.humanise.size t.downTotal
                        , text <| " (" ++ Utils.Filesize.formatWith model.config.humanise.speed t.downDiff ++ "/s)"
                        ]
                    ]
                , div [ class "stat" ]
                    [ i [ class "fas fa-arrow-up" ] []
                    , span []
                        [ text <| Utils.Filesize.formatWith model.config.humanise.size t.upTotal
                        , text <| " (" ++ Utils.Filesize.formatWith model.config.humanise.speed t.upDiff ++ "/s)"
                        ]
                    ]
                ]

        Nothing ->
            text ""


rtorrentSystemInfo : Model.Rtorrent.Info -> Html Msg
rtorrentSystemInfo info =
    div [ class "system-info" ]
        [ text <|
            "rtorrent "
                ++ info.systemVersion
                ++ "/"
                ++ info.libraryVersion
                ++ " on "
                ++ info.hostname
                ++ ":"
                ++ String.fromInt info.listenPort
        ]
