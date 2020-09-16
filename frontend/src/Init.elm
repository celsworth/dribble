module Init exposing (init)

import Dict
import Filesize
import Json.Decode as JD
import Model exposing (..)
import Model.ConfigCoder as ConfigCoder
import Subscriptions


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    ( { config = ConfigCoder.decodeOrDefault flags
      , torrents = { sorted = [], byHash = Dict.empty }
      , messages = []

      -- temporary until I bother encoding to JSON for Config
      , filesizeSettings = filesizeSettings
      }
    , Subscriptions.getTorrents
    )


filesizeSettings : Filesize.Settings
filesizeSettings =
    let
        default =
            Filesize.defaultSettings
    in
    { default | units = Filesize.Base2 }
