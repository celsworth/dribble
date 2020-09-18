module Init exposing (init)

import Dict
import Json.Decode as JD
import Model exposing (..)
import Model.ConfigCoder
import Model.Utils.TorrentAttribute
import Subscriptions
import Utils.Filesize


init : JD.Value -> ( Model, Cmd Msg )
init flags =
    let
        config =
            Model.ConfigCoder.decodeOrDefault flags
    in
    ( { config = config
      , websocketConnected = False
      , sortedTorrents = []
      , torrentsByHash = Dict.empty
      , messages = []

      -- temporary location until I bother encoding to JSON for Config
      , filesizeSettings = filesizeSettings
      }
    , Cmd.none
    )


filesizeSettings : Utils.Filesize.Settings
filesizeSettings =
    let
        default =
            Utils.Filesize.defaultSettings
    in
    { default | units = Utils.Filesize.Base2 }
