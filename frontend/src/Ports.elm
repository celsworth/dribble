port module Ports exposing (..)

import Json.Encode as JE



-- https://elmprogramming.com/saving-app-state.html


port storeConfig : JE.Value -> Cmd msg


port sendMessage : String -> Cmd msg


port messageReceiver : (String -> msg) -> Sub msg
