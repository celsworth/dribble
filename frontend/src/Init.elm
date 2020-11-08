module Init exposing (Flags, init)

import Dict
import Json.Decode as JD
import Model exposing (Model, Msg(..))
import Model.Config exposing (Config)
import Model.Message exposing (Message)
import Model.TorrentFilter
import Model.TorrentGroups
import Model.TorrentTable
import Ports
import Task
import Time


type alias Flags =
    { config : JD.Value
    , time : Int
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        ( config, messages ) =
            decodeConfig flags

        torrentFilter =
            Model.TorrentFilter.filterFromConfig config.filter
    in
    ( { config = config
      , rtorrentSystemInfo = Nothing
      , dnd = (Model.TorrentTable.dndSystem <| ColumnReordered).model
      , websocketConnected = False
      , contextMenu = Nothing
      , selectedTorrentHash = Nothing
      , torrentGroups = Model.TorrentGroups.empty
      , sortedTorrents = []
      , filteredTorrents = []
      , torrentsByHash = Dict.empty
      , torrentFilter = torrentFilter
      , sortedFiles = []
      , keyedFiles = Dict.empty
      , traffic = []
      , prevTraffic = Nothing
      , speedChartHover = []
      , messages = messages
      , hamburgerMenuVisible = False
      , resizeOp = Nothing
      , timezone = Time.utc
      , currentTime = Time.millisToPosix flags.time
      }
    , Cmd.batch
        [ Task.perform SetTimeZone Time.here
        , Ports.addWindowResizeObserver "preferences"
        , Ports.addWindowResizeObserver "logs"
        ]
    )


decodeConfig : Flags -> ( Config, List Message )
decodeConfig flags =
    case Model.Config.decodeOrDefault flags.config of
        Model.Config.DecodeOk config ->
            ( config, [] )

        Model.Config.DecodeError error config ->
            ( config
            , [ { summary = Just "Failed to load config, reverting to default"
                , detail = Just error
                , severity = Model.Message.Error
                , time = Time.millisToPosix flags.time
                }
              ]
            )
