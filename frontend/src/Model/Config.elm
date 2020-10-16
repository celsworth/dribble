module Model.Config exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Model.FileTable
import Model.PeerTable
import Model.Sort exposing (SortDirection(..))
import Model.Table
import Model.Torrent
import Model.TorrentFilter
import Model.TorrentTable
import Model.Window
import Utils.Filesize


type ConfigWithResult
    = DecodeOk Config
    | DecodeError String Config


type alias Humanise =
    { size : Utils.Filesize.Settings
    , speed : Utils.Filesize.Settings
    }


type alias Config =
    { refreshDelay : Int

    -- as an optimisation, torrent table sort is stored here, NOT in torrentTable.
    -- this is so when the sort changes, we don't invalidate the lazy cache of all
    -- the rows, because there could be thousands of them.
    , sortBy : Model.Torrent.Sort
    , torrentTable : Model.Table.Config
    , filter : Model.TorrentFilter.Config
    , fileTable : Model.Table.Config
    , peerTable : Model.Table.Config
    , humanise : Humanise
    , preferences : Model.Window.Config
    , logs : Model.Window.Config
    }


setSortBy : Model.Torrent.Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setTorrentTable : Model.Table.Config -> Config -> Config
setTorrentTable new config =
    { config | torrentTable = new }


setFilter : Model.TorrentFilter.Config -> Config -> Config
setFilter new config =
    { config | filter = new }


setFileTable : Model.Table.Config -> Config -> Config
setFileTable new config =
    { config | fileTable = new }


setPeerTable : Model.Table.Config -> Config -> Config
setPeerTable new config =
    { config | peerTable = new }


setPreferences : Model.Window.Config -> Config -> Config
setPreferences new config =
    { config | preferences = new }


setLogs : Model.Window.Config -> Config -> Config
setLogs new config =
    { config | logs = new }



-- DEFAULT


default : Config
default =
    { refreshDelay = 5
    , sortBy = Model.Torrent.SortBy Model.Torrent.StartedTime Desc
    , torrentTable = Model.TorrentTable.defaultConfig
    , filter = Model.TorrentFilter.default
    , fileTable = Model.FileTable.defaultConfig
    , peerTable = Model.PeerTable.defaultConfig
    , humanise =
        { size = { units = Utils.Filesize.Base2, decimalPlaces = 2, decimalSeparator = "." }
        , speed = { units = Utils.Filesize.Base10, decimalPlaces = 1, decimalSeparator = "." }
        }
    , preferences = { visible = False, width = 600, height = 400 }
    , logs = { visible = False, width = 800, height = 400 }
    }



--- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", Model.Torrent.encodeSortBy config.sortBy )
        , ( "torrentTable", Model.Table.encode config.torrentTable )
        , ( "filter", Model.TorrentFilter.encode config.filter )
        , ( "fileTable", Model.Table.encode config.fileTable )
        , ( "peerTable", Model.Table.encode config.peerTable )
        , ( "humanise", encodeHumanise config.humanise )
        , ( "preferences", Model.Window.encode config.preferences )
        , ( "logs", Model.Window.encode config.logs )
        ]


encodeHumanise : Humanise -> E.Value
encodeHumanise humanise =
    E.object
        [ ( "size", Utils.Filesize.encode humanise.size )
        , ( "speed", Utils.Filesize.encode humanise.speed )
        ]



--- JSON DECODERS


decodeOrDefault : D.Value -> ConfigWithResult
decodeOrDefault flags =
    case D.decodeValue decoder flags of
        Ok config ->
            DecodeOk config

        -- reached if anything below calls .fail
        Err err ->
            DecodeError (D.errorToString err) default


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "refreshDelay" D.int default.refreshDelay
        |> optional "sortBy" Model.Torrent.sortByDecoder default.sortBy
        |> optional "torrentTable" Model.Table.decoder default.torrentTable
        |> optional "filter" Model.TorrentFilter.decoder default.filter
        |> optional "fileTable" Model.Table.decoder default.fileTable
        |> optional "peerTable" Model.Table.decoder default.peerTable
        |> optional "humanise" humaniseDecoder default.humanise
        |> optional "preferences" Model.Window.decoder default.preferences
        |> optional "logs" Model.Window.decoder default.logs


humaniseDecoder : D.Decoder Humanise
humaniseDecoder =
    D.succeed Humanise
        |> optional "size" Utils.Filesize.decoder default.humanise.size
        |> optional "speed" Utils.Filesize.decoder default.humanise.speed
