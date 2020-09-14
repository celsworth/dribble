module Init exposing (init)

import Json.Decode as JD
import Model exposing (..)
import Model.ConfigCoder as ConfigCoder
import Subscriptions


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    ( { config = ConfigCoder.decodeOrDefault flags
      , torrents = []
      , error = Nothing
      , sort = Name Asc
      }
    , Subscriptions.getTorrents
    )
