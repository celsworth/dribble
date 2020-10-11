port module Ports exposing (..)

import Json.Encode as JE
import Model exposing (..)
import Model.Rtorrent



-- https://elmprogramming.com/saving-app-state.html


port websocketStatusUpdated : (JE.Value -> msg) -> Sub msg


port messageReceiver : (String -> msg) -> Sub msg


port sendMessage : String -> Cmd msg


port storeConfig : JE.Value -> Cmd msg


port observeWindowResize : String -> Cmd msg


port windowResizeObserved : (JE.Value -> msg) -> Sub msg


getRtorrentSystemInfo : Cmd Msg
getRtorrentSystemInfo =
    sendMessage Model.Rtorrent.getSystemInfo


getTorrents : Model -> Cmd Msg
getTorrents model =
    sendMessage (Model.Rtorrent.getTorrents model.config)


getTraffic : Cmd Msg
getTraffic =
    sendMessage Model.Rtorrent.getTraffic


addWindowResizeObserver : String -> Cmd Msg
addWindowResizeObserver id =
    observeWindowResize id
