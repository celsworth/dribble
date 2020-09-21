module Init exposing (init)

import Coders.Config
import Dict
import Json.Decode as JD
import Model exposing (..)


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    ( { config = Coders.Config.decodeOrDefault flags
      , websocketConnected = False
      , sortedTorrents = []
      , torrentsByHash = Dict.empty
      , messages = []
      , preferencesVisible = False
      , torrentAttributeResizeOp = Nothing
      }
    , Cmd.none
    )
