module Model.Table exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E


type alias Config =
    { layout : Layout
    }


type Layout
    = Fixed
    | Fluid


defaultConfig : Config
defaultConfig =
    { layout = Fluid }



-- JSON ENCODING


encode : Config -> E.Value
encode config =
    E.object
        [ ( "layout", encodeLayout config.layout )
        ]


encodeLayout : Layout -> E.Value
encodeLayout val =
    case val of
        Fixed ->
            E.string "fixed"

        Fluid ->
            E.string "fluid"



-- JSON DECODING


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "layout" layoutDecoder defaultConfig.layout


layoutDecoder : D.Decoder Layout
layoutDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "fixed" ->
                        D.succeed Fixed

                    "fluid" ->
                        D.succeed Fluid

                    _ ->
                        D.fail <| "unknown table.layout" ++ input
            )
