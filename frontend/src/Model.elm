module Model exposing (..)

import Json.Decode as JD


type Msg
    = RefreshClicked
    | SaveConfigClicked
    | WebsocketData (Result JD.Error DecodedData)


type
    DecodedData
    -- TODO: add lists of labels, trackers, peers, etc?
    = Torrents (List Torrent)
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
    , torrents : List Torrent
    , messages : List Message
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
    }


type TorrentAttribute
    = Name
    | Size


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy TorrentAttribute SortDirection
