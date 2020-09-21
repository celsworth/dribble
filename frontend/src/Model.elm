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
    | RequestFullTorrents
    | RequestUpdatedTorrents Time.Posix
    | WebsocketData (Result JD.Error DecodedData)
    | WebsocketStatusUpdated (Result JD.Error Bool)



-- TODO: add lists of trackers, peers, etc?


type DecodedData
    = TorrentsReceived (List Torrent)
    | Error String


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
    { x : Float, y : Float }


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


type alias Model =
    { config : Config
    , websocketConnected : Bool
    , sortedTorrents : List String
    , torrentsByHash : Dict String Torrent
    , messages : List Message
    , preferencesVisible : Bool
    , torrentAttributeResizeOp : Maybe TorrentAttributeResizeOp
    }


type alias Config =
    { refreshDelay : Int
    , sortBy : Sort -- Name Asc, Size Desc, etc
    , visibleTorrentAttributes : List TorrentAttribute
    , torrentAttributeOrder : List TorrentAttribute
    , columnWidths : ColumnWidths
    , filesizeSettings : Utils.Filesize.Settings
    }


type TorrentAttribute
    = Name
    | Size
    | CreationTime
    | StartedTime
    | FinishedTime
    | DownloadedBytes
    | DownloadRate
    | UploadedBytes
    | UploadRate
    | PeersConnected
    | Label
    | DonePercent


type alias Torrent =
    { hash : String
    , name : String
    , size : Int
    , creationTime : Int
    , startedTime : Int
    , finishedTime : Int
    , downloadedBytes : Int
    , downloadRate : Int
    , uploadedBytes : Int
    , uploadRate : Int
    , peersConnected : Int
    , label : String

    -- custom local vars, not from JSON
    , donePercent : Float
    }
