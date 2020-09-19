module Init exposing (init)

import Coders.Config
import Dict
import Json.Decode as JD
import Model exposing (..)
import Model.Utils.TorrentAttribute
import Subscriptions
import Utils.Filesize


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
      , messages = []
      , dragging = Nothing
      , columnWidths = tmpWidths config
      , preferencesVisible = False

      -- temporary location until I bother encoding to JSON for Config
      , filesizeSettings = filesizeSettings
      , mousePosition = { x = 0, y = 0 }
      }
    , Cmd.none
    )


tmpWidths : Config -> Dict.Dict String Float
tmpWidths config =
    Dict.fromList <|
        List.map tmpMap config.torrentAttributeOrder


tmpMap : TorrentAttribute -> ( String, Float )
tmpMap attribute =
    ( Model.Utils.TorrentAttribute.attributeToKey attribute, 50.0 )


filesizeSettings : Utils.Filesize.Settings
filesizeSettings =
    let
        default =
            Utils.Filesize.defaultSettings
    in
    { default | units = Utils.Filesize.Base2 }
