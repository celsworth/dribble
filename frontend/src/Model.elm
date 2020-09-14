module Model exposing (..)

import Json.Decode as JD


type Msg
    = RefreshClicked
    | SaveConfigClicked
    | WebsocketData (Result JD.Error DecodedData)


type DecodedData
    = Torrents (List Torrent)
    | Error String


type alias Model =
    { config : Config
    , torrents : List Torrent
    , error : Maybe String
    , sort : SortBy
    }


type alias Config =
    { refreshDelay : Int
    }


type alias Torrent =
    { hash : String
    , name : String
    , size : Int
    }


type SortBy
    = Name SortDirection
    | Size SortDirection


type SortDirection
    = Asc
    | Desc
