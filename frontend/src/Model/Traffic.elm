module Model.Traffic exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (custom, hardcoded)


type alias Traffic =
    { time : Int
    , upDiff : Int
    , downDiff : Int
    , upTotal : Int
    , downTotal : Int
    }



-- JSON DECODER
{-
   time, up, down
   {"data":[[1600958252],[61463171320],[52765651306]]}
-}


decoder : D.Decoder Traffic
decoder =
    D.succeed Traffic
        |> custom (D.index 0 intFromArrayDecoder)
        |> hardcoded 0
        |> hardcoded 0
        |> custom (D.index 1 intFromArrayDecoder)
        |> custom (D.index 2 intFromArrayDecoder)


intFromArrayDecoder : D.Decoder Int
intFromArrayDecoder =
    D.index 0 D.int
