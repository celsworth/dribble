module Model exposing (..)

import Dict exposing (Dict)
import Json.Decode as JD
import Time
import Utils.Filesize


type Msg
    = MouseDownMsg TorrentAttribute ( Float, Float )
    | MouseMoveMsg ( Float, Float )
    | MouseUpMsg ( Float, Float )
    | RefreshClicked
    | SaveConfigClicked
    | ShowPreferencesClicked
    | ToggleTorrentAttributeVisibility TorrentAttribute
    | SetSortBy TorrentAttribute
    | RequestFullTorrents
    | RequestUpdatedTorrents Time.Posix
    | WebsocketData (Result JD.Error DecodedData)
    | WebsocketStatusUpdated (Result JD.Error Bool)


type
    DecodedData
    -- TODO: add lists of labels, trackers, peers, etc?
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


type alias Dragging =
    Maybe ( TorrentAttribute, Float )


type alias MousePosition =
    ( Float, Float )


type alias ColumnWidths =
    Dict String Float


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
    , dragging : Dragging
    , mousePosition : MousePosition
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
