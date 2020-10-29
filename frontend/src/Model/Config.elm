module Model.Config exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (optional)
import Json.Encode as E
import Model.FileTable
import Model.PeerTable
import Model.Sort exposing (SortDirection(..))
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
    , torrentTable : Model.TorrentTable.Config
    , filter : Model.TorrentFilter.Config
    , fileTable : Model.FileTable.Config
    , peerTable : Model.PeerTable.Config
    , humanise : Humanise
    , preferences : Model.Window.Config
    , logs : Model.Window.Config
    , enableContextMenus : Bool
    }


setSortBy : Model.Torrent.Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setTorrentTable : Model.TorrentTable.Config -> Config -> Config
setTorrentTable new config =
    -- avoid excessive setting in Update/DragAndDropReceived
    if config.torrentTable /= new then
        { config | torrentTable = new }

    else
        config


setFilter : Model.TorrentFilter.Config -> Config -> Config
setFilter new config =
    { config | filter = new }


setFileTable : Model.FileTable.Config -> Config -> Config
setFileTable new config =
    -- avoid excessive setting in Update/DragAndDropReceived
    if config.fileTable /= new then
        { config | fileTable = new }

    else
        config


setPeerTable : Model.PeerTable.Config -> Config -> Config
setPeerTable new config =
    -- avoid excessive setting in Update/DragAndDropReceived
    if config.peerTable /= new then
        { config | peerTable = new }

    else
        config


setPreferences : Model.Window.Config -> Config -> Config
setPreferences new config =
    { config | preferences = new }


setLogs : Model.Window.Config -> Config -> Config
setLogs new config =
    { config | logs = new }


setEnableContextMenus : Bool -> Config -> Config
setEnableContextMenus new config =
    { config | enableContextMenus = new }



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
    , enableContextMenus = True
    }



--- JSON ENCODER


encode : Config -> E.Value
encode config =
    E.object
        [ ( "refreshDelay", E.int config.refreshDelay )
        , ( "sortBy", Model.Torrent.encodeSortBy config.sortBy )
        , ( "torrentTable", Model.TorrentTable.encode config.torrentTable )
        , ( "filter", Model.TorrentFilter.encode config.filter )
        , ( "fileTable", Model.FileTable.encode config.fileTable )
        , ( "peerTable", Model.PeerTable.encode config.peerTable )
        , ( "humanise", encodeHumanise config.humanise )
        , ( "preferences", Model.Window.encode config.preferences )
        , ( "logs", Model.Window.encode config.logs )
        , ( "enableContextMenus", E.bool config.enableContextMenus )
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
        |> optional "torrentTable" Model.TorrentTable.decoder default.torrentTable
        |> optional "filter" Model.TorrentFilter.decoder default.filter
        |> optional "fileTable" Model.FileTable.decoder default.fileTable
        |> optional "peerTable" Model.PeerTable.decoder default.peerTable
        |> optional "humanise" humaniseDecoder default.humanise
        |> optional "preferences" Model.Window.decoder default.preferences
        |> optional "logs" Model.Window.decoder default.logs
        |> optional "enableContextMenus" D.bool default.enableContextMenus


humaniseDecoder : D.Decoder Humanise
humaniseDecoder =
    D.succeed Humanise
        |> optional "size" Utils.Filesize.decoder default.humanise.size
        |> optional "speed" Utils.Filesize.decoder default.humanise.speed
