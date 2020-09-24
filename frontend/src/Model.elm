module Model exposing (..)

import Browser.Dom
import Dict exposing (Dict)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Time
import Utils.Filesize


type Msg
    = TorrentAttributeResizeStarted TorrentAttribute MousePosition Mouse.Button Mouse.Keys
    | TorrentAttributeResized TorrentAttributeResizeOp MousePosition
    | TorrentAttributeResizeEnded TorrentAttributeResizeOp MousePosition
    | GotColumnWidth TorrentAttribute (Result Browser.Dom.Error Browser.Dom.Element)
    | RefreshClicked
    | SaveConfigClicked
    | ShowPreferencesClicked
    | ToggleTorrentAttributeVisibility TorrentAttribute
    | SetSortBy TorrentAttribute
    | SpeedChartHover (List DataSeries)
    | RequestFullTorrents
    | RequestUpdatedTorrents Time.Posix
    | RequestUpdatedTraffic Time.Posix
    | WebsocketData (Result JD.Error DecodedData)
    | WebsocketStatusUpdated (Result JD.Error Bool)



-- TODO: add lists of trackers, peers, etc?


type DecodedData
    = TorrentsReceived (List Torrent)
    | TrafficReceived Traffic
    | Error String


type alias Traffic =
    { time : Int
    , upDiff : Int
    , downDiff : Int
    , upTotal : Int
    , downTotal : Int
    }


type MessageSeverity
    = InfoSeverity
    | WarningSeverity
    | ErrorSeverity


type alias Message =
    { message : String
    , severity : MessageSeverity
    }


type alias TorrentAttributeResizeOp =
    {- Dragging a TorrentAttribute resize bar
       Could possibly extend to other table types in future
    -}
    { attribute : TorrentAttribute
    , startPosition : MousePosition
    , currentPosition : MousePosition
    }


type alias MousePosition =
    { x : Float
    , y : Float
    }


type alias ColumnWidths =
    Dict String ColumnWidth


type alias ColumnWidth =
    { px : Float
    , auto : Bool
    }


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy TorrentAttribute SortDirection


type alias DataSeries =
    { time : Int
    , speed : Int
    }


type alias Model =
    { config : Config
    , websocketConnected : Bool
    , sortedTorrents : List String
    , torrentsByHash : Dict String Torrent
    , traffic : List Traffic
    , firstTraffic : Maybe Traffic
    , speedChartHover : List DataSeries
    , messages : List Message
    , preferencesVisible : Bool
    , torrentAttributeResizeOp : Maybe TorrentAttributeResizeOp
    , timezone : Time.Zone
    }


type alias Config =
    { refreshDelay : Int
    , sortBy : Sort -- Name Asc, Size Desc, etc
    , visibleTorrentAttributes : List TorrentAttribute
    , torrentAttributeOrder : List TorrentAttribute
    , columnWidths : ColumnWidths
    , filesizeSettings : Utils.Filesize.Settings
    , timezone : String
    }


type TorrentAttribute
    = TorrentStatus
    | Name
    | Size
    | CreationTime
    | StartedTime
    | FinishedTime
    | DownloadedBytes
    | DownloadRate
    | UploadedBytes
    | UploadRate
    | SeedersConnected
    | SeedersTotal
    | PeersConnected
    | Label
    | DonePercent


type TorrentStatus
    = Seeding
    | Downloading
    | Paused
    | Stopped
    | Hashing


type HashingStatus
    = NotHashing
    | InitialHash
    | FinishHash
    | Rehash


type alias Torrent =
    { status : TorrentStatus
    , hash : String
    , name : String
    , size : Int
    , creationTime : Int
    , startedTime : Int
    , finishedTime : Int
    , downloadedBytes : Int
    , downloadRate : Int
    , uploadedBytes : Int
    , uploadRate : Int
    , isOpen : Bool
    , isActive : Bool
    , hashing : HashingStatus
    , seedersConnected : Int
    , seedersTotal : Int
    , peersConnected : Int
    , label : String

    -- custom local vars, not from JSON
    , donePercent : Float
    }
