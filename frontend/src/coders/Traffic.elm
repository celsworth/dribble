module Coders.Traffic exposing (decoder)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom, hardcoded)
import Model exposing (..)



{-
   time, up, down
   {"data":[[1600958252],[61463171320],[52765651306]]}
-}


decoder : D.Decoder DecodedData
decoder =
    D.map TrafficReceived <|
        D.field "data" trafficDecoder


trafficDecoder : D.Decoder Traffic
trafficDecoder =
    D.succeed Traffic
        |> custom (D.index 0 intFromArrayDecoder)
        |> hardcoded 0
        |> hardcoded 0
        |> custom (D.index 1 intFromArrayDecoder)
        |> custom (D.index 2 intFromArrayDecoder)


intFromArrayDecoder : D.Decoder Int
intFromArrayDecoder =
    D.index 0 D.int
