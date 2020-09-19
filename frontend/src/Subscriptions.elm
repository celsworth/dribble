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
            , ticker model
            ]


ticker : Model -> Maybe (Sub Msg)
ticker model =
    if model.websocketConnected then
        Just <|
            Time.every (toFloat model.config.refreshDelay * 1000)
                RequestUpdatedTorrents

    else
        Nothing
