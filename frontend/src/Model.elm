module Model exposing (..)

import Dict exposing (Dict)
import Filesize
import Json.Decode as JD
import Time


type Msg
    = RefreshClicked
    | SaveConfigClicked
    | ToggleTorrentAttributeVisibility TorrentAttribute
    | RequestFullTorrents
    | RequestUpdatedTorrents Time.Posix
    | WebsocketData (Result JD.Error DecodedData)


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


type alias Model =
    { config : Config
    , sortedTorrents : List String
    , torrentsByHash : Dict String Torrent
    , messages : List Message
    , filesizeSettings : Filesize.Settings
    }


type alias Config =
    { refreshDelay : Int
    , sortBy : Sort -- Name Asc, Size Desc, etc
    , visibleTorrentAttributes : List TorrentAttribute
    , torrentAttributeOrder : List TorrentAttribute
    }


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
    }


type alias TorrentAttributeStuff =
    { tableAlign : String
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


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy TorrentAttribute SortDirection
