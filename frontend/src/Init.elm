module Init exposing (init)

import Coders.Config
import Dict
import Json.Decode as JD
import Model exposing (..)
import Time
import TimeZone


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    let
        config =
            Coders.Config.decodeOrDefault flags
    in
    ( { config = config
      , websocketConnected = False
      , sortedTorrents = []
      , torrentsByHash = Dict.empty
      , traffic = []
      , firstTraffic = Nothing
      , speedChartHover = []
      , messages = []
      , preferencesVisible = False
      , torrentAttributeResizeOp = Nothing
      , timezone = resolveTimezone config
      }
    , Cmd.none
    )


resolveTimezone : Config -> Time.Zone
resolveTimezone config =
    case Dict.get config.timezone TimeZone.zones of
        Just zone ->
            zone ()

        Nothing ->
            Time.utc
