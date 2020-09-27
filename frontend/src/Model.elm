module Model exposing (..)

import Browser.Dom
import Dict exposing (Dict)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model.Config exposing (Config)
import Model.Message exposing (Message)
import Model.SpeedChart
import Model.Torrent exposing (Torrent)
import Model.Traffic exposing (Traffic)
import Model.WebsocketData
import Time


type Msg
    = TorrentAttributeResizeStarted Model.Torrent.Attribute MousePosition Mouse.Button Mouse.Keys
    | TorrentAttributeResized TorrentAttributeResizeOp MousePosition
    | TorrentAttributeResizeEnded TorrentAttributeResizeOp MousePosition
    | GotColumnWidth Model.Torrent.Attribute (Result Browser.Dom.Error Browser.Dom.Element)
    | RefreshClicked
    | SaveConfigClicked
    | ShowPreferencesClicked
    | ToggleTorrentAttributeVisibility Model.Torrent.Attribute
    | SetSortBy Model.Torrent.Attribute
    | SpeedChartHover (List Model.SpeedChart.DataSeries)
    | RequestFullTorrents
    | RequestUpdatedTorrents Time.Posix
    | RequestUpdatedTraffic Time.Posix
    | WebsocketData (Result JD.Error Model.WebsocketData.Data)
    | WebsocketStatusUpdated (Result JD.Error Bool)



-- TODO: add lists of trackers, peers, etc?


type alias TorrentAttributeResizeOp =
    {- Dragging a TorrentAttribute resize bar
       Could possibly extend to other table types in future
    -}
    { attribute : Model.Torrent.Attribute
    , startPosition : MousePosition
    , currentPosition : MousePosition
    }


type alias MousePosition =
    { x : Float
    , y : Float
    }


type alias Model =
    { config : Config
    , websocketConnected : Bool
    , sortedTorrents : List String
    , torrentsByHash : Dict String Torrent
    , traffic : List Traffic
    , firstTraffic : Maybe Traffic
    , speedChartHover : List Model.SpeedChart.DataSeries
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


setSpeedChartHover : List Model.SpeedChart.DataSeries -> Model -> Model
setSpeedChartHover new model =
    { model | speedChartHover = new }


setPreferencesVisible : Bool -> Model -> Model
setPreferencesVisible new model =
    { model | preferencesVisible = new }


addCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
addCmd cmd model =
    ( model, cmd )
