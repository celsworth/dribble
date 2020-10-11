module View.Summary exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Model exposing (..)
import Utils.Filesize


view : Model -> Html Msg
view model =
    section [ class "summary" ]
        [ websocketStatus model
        , traffic model
        ]


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


websocketStatus : Model -> Html Msg
websocketStatus model =
    if model.websocketConnected then
        i [ class "fas fa-circle connected" ] []

    else
        i [ class "fas fa-circle disconnected" ] []
