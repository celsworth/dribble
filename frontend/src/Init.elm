module Init exposing (init)

import Dict
import Json.Decode as JD
import Model exposing (..)
import Model.Config exposing (Config)
import Time
import TimeZone


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    let
        config =
            Model.Config.decodeOrDefault flags
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
      , resizeOp = Nothing
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
