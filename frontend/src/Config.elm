module Config exposing (Config, decodeConfigOrDefault, saveConfig)

import Json.Decode as JD
import Json.Decode.Pipeline as Pipeline
import Json.Encode as JE
import Ports exposing (storeConfig)


type alias Config =
    { refreshDelay : Int
    }


defaultConfig : Config
defaultConfig =
    { refreshDelay = 10
    }


saveConfig : Config -> Cmd msg
saveConfig config =
    encodeConfig config |> storeConfig



-- JSON Encoding


encodeConfig : Config -> JE.Value
encodeConfig config =
    JE.object
        [ ( "refreshDelay", JE.int config.refreshDelay )
        ]



-- JSON Decoding


decodeConfigOrDefault : JD.Value -> Config
decodeConfigOrDefault flags =
    case JD.decodeValue decodeConfig flags of
        Ok config ->
            config

        -- no config, or localStorage has invalid JSON?
        _ ->
            defaultConfig


decodeConfig : JD.Decoder Config
decodeConfig =
    JD.succeed Config
        |> Pipeline.required "refreshDelay" JD.int
