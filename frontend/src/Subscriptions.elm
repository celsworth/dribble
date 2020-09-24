module Subscriptions exposing (..)

import Coders.Base
import Model exposing (..)
import Ports
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        List.filterMap identity <|
            [ Just <|
                Ports.messageReceiver
                    (WebsocketData << Coders.Base.decodeString)
            , Just <|
                Ports.websocketStatusUpdated
                    (WebsocketStatusUpdated << Coders.Base.decodeStatus)
            , updateTorrentsTicker model
            , updateTrafficTicker model
            ]


updateTorrentsTicker : Model -> Maybe (Sub Msg)
updateTorrentsTicker model =
    if model.websocketConnected then
        Just <|
            Time.every (toFloat model.config.refreshDelay * 1000)
                RequestUpdatedTorrents

    else
        Nothing


updateTrafficTicker : Model -> Maybe (Sub Msg)
updateTrafficTicker model =
    if model.websocketConnected then
        Just <| Time.every 10000 RequestUpdatedTraffic

    else
        Nothing
