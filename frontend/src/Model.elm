module Model exposing (..)

import Browser.Dom
import Dict exposing (Dict)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model.Config exposing (Config)
import Model.Message exposing (Message)
import Model.SpeedChart
import Model.Table
import Model.Torrent exposing (Torrent)
import Model.Traffic exposing (Traffic)
import Model.WebsocketData
import Time


type Msg
    = MouseDown Model.Table.Attribute Model.Table.MousePosition Mouse.Button Mouse.Keys
    | TorrentAttributeResized Model.Table.ResizeOp Model.Table.MousePosition
    | TorrentAttributeResizeEnded Model.Table.ResizeOp Model.Table.MousePosition
    | GotColumnWidth Model.Table.Attribute (Result Browser.Dom.Error Browser.Dom.Element)
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
    , resizeOp : Maybe Model.Table.ResizeOp
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


setResizeOp : Maybe Model.Table.ResizeOp -> Model -> Model
setResizeOp new model =
    { model | resizeOp = new }


addCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
addCmd cmd model =
    ( model, cmd )
