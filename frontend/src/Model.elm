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
    | SpeedChartHover (List SpeedChartDataSeries)
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


type alias SpeedChartDataSeries =
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
    , speedChartHover : List SpeedChartDataSeries
    , messages : List Message
    , preferencesVisible : Bool
    , torrentAttributeResizeOp : Maybe TorrentAttributeResizeOp
    , timezone : Time.Zone
    }


setConfig : Config -> Model -> Model
setConfig new model =
    { model | config = new }


setWebsocketConnected : Bool -> Model -> Model
setWebsocketConnected new model =
    { model | websocketConnected = new }


setSortedTorrents : List String -> Model -> Model
setSortedTorrents new model =
    { model | sortedTorrents = new }


setMessages : List Message -> Model -> Model
setMessages new model =
    { model | messages = new }


setSpeedChartHover : List SpeedChartDataSeries -> Model -> Model
setSpeedChartHover new model =
    { model | speedChartHover = new }


setPreferencesVisible : Bool -> Model -> Model
setPreferencesVisible new model =
    { model | preferencesVisible = new }


type alias Config =
    { refreshDelay : Int
    , sortBy : Sort
    , visibleTorrentAttributes : List TorrentAttribute
    , torrentAttributeOrder : List TorrentAttribute
    , columnWidths : ColumnWidths
    , hSizeSettings : Utils.Filesize.Settings
    , hSpeedSettings : Utils.Filesize.Settings
    , timezone : String
    }


setSortBy : Sort -> Config -> Config
setSortBy new config =
    { config | sortBy = new }


setVisibleTorrentAttributes : List TorrentAttribute -> Config -> Config
setVisibleTorrentAttributes new config =
    { config | visibleTorrentAttributes = new }


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
    | Seeders
    | SeedersConnected
    | SeedersTotal
    | Peers
    | PeersConnected
    | PeersTotal
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
    , peersTotal : Int
    , label : String

    -- custom local vars, not from JSON
    , donePercent : Float
    }


addCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
addCmd cmd model =
    ( model, cmd )
