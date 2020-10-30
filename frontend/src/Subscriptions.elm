module Subscriptions exposing (..)

import Json.Decode as D
import Model exposing (..)
import Model.File
import Model.Rtorrent
import Model.Table
import Model.Torrent
import Model.Traffic
import Model.WebsocketData
import Model.Window
import Ports
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        List.filterMap identity <|
            [ Just <| Time.every 1000 Tick
            , Just <| Ports.messageReceiver (WebsocketData << decodeMessage)
            , Just <| Ports.windowResizeObserved (WindowResized << decodeWindowResizeDetails)
            , Just <| Ports.websocketStatusUpdated (WebsocketStatusUpdated << decodeStatus)
            , Just <| (dndSystemTorrent Model.Table.Torrents).subscriptions model.dnd
            ]



-- JSON DECODING


decodeWindowResizeDetails : D.Value -> Result D.Error Model.Window.ResizeDetails
decodeWindowResizeDetails =
    D.decodeValue <| Model.Window.windowResizeDetailsDecoder


decodeMessage : String -> Result D.Error Model.WebsocketData.Data
decodeMessage =
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
        , systemInfoDecoder
        , torrentListDecoder
        , fileListDecoder
        , trafficDecoder
        ]


errorDecoder : D.Decoder Model.WebsocketData.Data
errorDecoder =
    D.map Model.WebsocketData.Error <|
        D.field "error" D.string


systemInfoDecoder : D.Decoder Model.WebsocketData.Data
systemInfoDecoder =
    D.map Model.WebsocketData.SystemInfoReceived <|
        D.field "systemInfo" Model.Rtorrent.decoder


torrentListDecoder : D.Decoder Model.WebsocketData.Data
torrentListDecoder =
    D.map Model.WebsocketData.TorrentsReceived <|
        D.field "torrentList" <|
            Model.Torrent.listDecoder


fileListDecoder : D.Decoder Model.WebsocketData.Data
fileListDecoder =
    D.map Model.WebsocketData.FilesReceived <|
        D.field "fileList" <|
            Model.File.listDecoder


trafficDecoder : D.Decoder Model.WebsocketData.Data
trafficDecoder =
    D.map Model.WebsocketData.TrafficReceived <|
        D.field "trafficRate" <|
            Model.Traffic.decoder
