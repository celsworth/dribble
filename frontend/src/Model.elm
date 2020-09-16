module Model exposing (..)

import Dict exposing (Dict)
import Filesize
import Json.Decode as JD


type Msg
    = RefreshClicked
    | SaveConfigClicked
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


type alias Torrents =
    { sorted : List Torrent
    , byHash : Dict String Torrent
    }


type alias Model =
    { config : Config
    , torrents : Torrents
    , messages : List Message
    , filesizeSettings : Filesize.Settings
    }


type alias Config =
    { refreshDelay : Int
    , sortBy : Sort -- Name Asc, Size Desc, etc
    , visibleTorrentAttributes : List TorrentAttribute

    -- torrentAttributeOrder ?
    }


type alias Torrent =
    { hash : String
    , name : String
    , size : Int
    , creationTime : Int
    , startedTime : Int
    , finishedTime : Int
    , uploadedBytes : Int
    , uploadRate : Int
    , downloadedBytes : Int
    , downloadRate : Int
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
    | UploadedBytes
    | UploadRate
    | DownloadedBytes
    | DownloadRate
    | Label


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy TorrentAttribute SortDirection
