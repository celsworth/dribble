module Subscriptions exposing (..)

import Json.Decode as D
import Model exposing (..)
import Model.Torrent
import Model.Traffic
import Model.WebsocketData
import Ports
import Time


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch <|
        List.filterMap identity <|
            [ Just <| Time.every 1000 Tick
            , Just <| Ports.messageReceiver (WebsocketData << decodeString)
            , Just <| Ports.websocketStatusUpdated (WebsocketStatusUpdated << decodeStatus)
            ]


updateTrafficTicker : Model -> Maybe (Sub Msg)
updateTrafficTicker model =
    if model.websocketConnected then
        Just <| Time.every 10000 RequestUpdatedTraffic

    else
        Nothing



-- WEBSOCKET DECODING


decodeString : String -> Result D.Error Model.WebsocketData.Data
decodeString =
    D.decodeString websocketMessageDecoder


decodeStatus : D.Value -> Result D.Error Bool
decodeStatus =
    D.decodeValue websocketStatusDecoder


websocketStatusDecoder : D.Decoder Bool
websocketStatusDecoder =
    D.field "connected" D.bool


websocketMessageDecoder : D.Decoder Model.WebsocketData.Data
websocketMessageDecoder =
    D.oneOf
        [ errorDecoder
        , torrentListDecoder
        , trafficDecoder
        ]


errorDecoder : D.Decoder Model.WebsocketData.Data
errorDecoder =
    D.map Model.WebsocketData.Error <|
        D.field "error" D.string


torrentListDecoder : D.Decoder Model.WebsocketData.Data
torrentListDecoder =
    D.map Model.WebsocketData.TorrentsReceived <|
        D.field "torrentList" <|
            Model.Torrent.listDecoder


trafficDecoder : D.Decoder Model.WebsocketData.Data
trafficDecoder =
    D.map Model.WebsocketData.TrafficReceived <|
        D.field "trafficRate" <|
            Model.Traffic.decoder
