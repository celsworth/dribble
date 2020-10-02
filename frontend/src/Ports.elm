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


getFullTorrents : Model -> Cmd Msg
getFullTorrents model =
    sendMessage (Model.Rtorrent.getFullTorrents model)


getUpdatedTorrents : Cmd Msg
getUpdatedTorrents =
    sendMessage Model.Rtorrent.getUpdatedTorrents


getTraffic : Cmd Msg
getTraffic =
    sendMessage Model.Rtorrent.getTraffic


addWindowResizeObserver : String -> Cmd Msg
addWindowResizeObserver id =
    observeWindowResize id
