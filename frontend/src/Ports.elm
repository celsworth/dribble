port module Ports exposing (..)

import Coders.Base
import Json.Encode as JE
import Model exposing (..)



-- https://elmprogramming.com/saving-app-state.html


port storeConfig : JE.Value -> Cmd msg


port websocketStatusUpdated : (JE.Value -> msg) -> Sub msg


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg


getFullTorrents : Cmd Msg
getFullTorrents =
    sendMessage Coders.Base.getFullTorrents


getUpdatedTorrents : Cmd Msg
getUpdatedTorrents =
    sendMessage Coders.Base.getUpdatedTorrents


getTraffic : Cmd Msg
getTraffic =
    sendMessage Coders.Base.getTraffic
