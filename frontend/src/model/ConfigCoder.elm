module Model.ConfigCoder exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline
import Json.Encode as E
import Model exposing (..)


default : Config
default =
    { refreshDelay = 10
    }


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        ]


decodeOrDefault : D.Value -> Config
decodeOrDefault flags =
    case D.decodeValue decoder flags of
        Ok config ->
            config

        -- no config, or localStorage has invalid JSON?
        _ ->
            default


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> Pipeline.required "refreshDelay" D.int
