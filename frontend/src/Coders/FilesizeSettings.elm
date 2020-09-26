module Coders.FilesizeSettings exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (optional, required)
import Json.Encode as E
import Model exposing (..)
import Utils.Filesize exposing (Units(..))



--- ENCODERS


encode : Utils.Filesize.Settings -> E.Value
encode settings =
    E.object
        [ ( "units", encodeUnits settings.units )
        , ( "decimalPlaces", E.int settings.decimalPlaces )
        , ( "decimalSeparator", E.string settings.decimalSeparator )
        ]


encodeUnits : Utils.Filesize.Units -> E.Value
encodeUnits units =
    case units of
        Base2 ->
            E.string "Base2"

        Base10 ->
            E.string "Base10"



--- DECODERS


decoder : D.Decoder Utils.Filesize.Settings
decoder =
    D.succeed Utils.Filesize.Settings
        |> optional "units" unitsDecoder Utils.Filesize.defaultSettings.units
        |> optional "decimalPlaces" D.int Utils.Filesize.defaultSettings.decimalPlaces
        |> optional "decimalSeparator" D.string Utils.Filesize.defaultSettings.decimalSeparator


unitsDecoder : D.Decoder Units
unitsDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "Base2" ->
                        D.succeed Base2

                    "Base10" ->
                        D.succeed Base10

                    _ ->
                        D.fail <| "unknown units" ++ input
            )
