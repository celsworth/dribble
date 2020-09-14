module Subscriptions exposing (..)

import JSON
import Json.Encode as JE
import Model exposing (..)
import Ports exposing (..)


subscriptions : Model -> Sub Msg
subscriptions _ =
    messageReceiver (WebsocketData << JSON.decodeString)


getTorrents : Cmd Msg
getTorrents =
    sendMessage JSON.getTorrentsRequest
