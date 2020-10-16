module Model exposing (..)

import Browser.Dom
import Dict
import DnDList
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model.Attribute exposing (Attribute)
import Model.Config exposing (Config)
import Model.File exposing (File, FilesByKey)
import Model.Message exposing (Message)
import Model.Preferences
import Model.Rtorrent
import Model.SpeedChart
import Model.Table
import Model.Torrent exposing (Torrent, TorrentsByHash)
import Model.TorrentFilter exposing (TorrentFilter)
import Model.Traffic exposing (Traffic)
import Model.WebsocketData
import Model.Window
import Time


type Msg
    = SetTimeZone Time.Zone
    | MouseDown Attribute Model.Table.MousePosition Mouse.Button Mouse.Keys
    | TorrentAttributeResized Model.Table.ResizeOp Model.Table.MousePosition
    | TorrentAttributeResizeEnded Model.Table.ResizeOp Model.Table.MousePosition
    | GotColumnWidth Attribute (Result Browser.Dom.Error Browser.Dom.Element)
    | SetPreference Model.Preferences.PreferenceUpdate
    | ResetConfigClicked
    | SaveConfigClicked
    | TogglePreferencesVisible
    | ToggleLogsVisible
    | SetHamburgerMenuVisible Bool
    | TorrentFilterChanged String
    | ToggleTorrentAttributeVisibility Model.Torrent.Attribute
    | SetSortBy Model.Attribute.Attribute
    | TorrentRowSelected String
    | SpeedChartHover (List Model.SpeedChart.DataSeries)
    | Tick Time.Posix
    | WebsocketData (Result JD.Error Model.WebsocketData.Data)
    | WebsocketStatusUpdated (Result JD.Error Bool)
    | WindowResized (Result JD.Error Model.Window.ResizeDetails)
    | DnDMsg Model.Table.Type DnDList.Msg


dndConfig : DnDList.Config Model.Table.Column
dndConfig =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Vertical
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


dndSystem : Model.Table.Type -> DnDList.System Model.Table.Column Msg
dndSystem tableType =
    DnDList.create dndConfig (DnDMsg tableType)


type alias Model =
    { config : Config
    , rtorrentSystemInfo : Maybe Model.Rtorrent.Info
    , dnd : DnDList.Model
    , websocketConnected : Bool
    , selectedTorrentHash : Maybe String
    , sortedTorrents : List String
    , torrentsByHash : TorrentsByHash
    , torrentFilter : TorrentFilter
    , sortedFiles : List String
    , keyedFiles : FilesByKey
    , traffic : List Traffic
    , prevTraffic : Maybe Traffic
    , speedChartHover : List Model.SpeedChart.DataSeries
    , messages : List Message
    , hamburgerMenuVisible : Bool
    , resizeOp : Maybe Model.Table.ResizeOp
    , currentTime : Time.Posix
    , timezone : Time.Zone
    }


setConfig : Config -> Model -> Model
setConfig new model =
    { model | config = new }


setRtorrentSystemInfo : Model.Rtorrent.Info -> Model -> Model
setRtorrentSystemInfo new model =
    { model | rtorrentSystemInfo = Just new }


setWebsocketConnected : Bool -> Model -> Model
setWebsocketConnected new model =
    { model | websocketConnected = new }


setSortedTorrents : List String -> Model -> Model
setSortedTorrents new model =
    { model | sortedTorrents = new }


setSelectedTorrentHash : String -> Model -> Model
setSelectedTorrentHash new model =
    { model | selectedTorrentHash = Just new }


selectedTorrent : Model -> Maybe Torrent
selectedTorrent model =
    Maybe.withDefault Nothing <|
        Maybe.map (\h -> Dict.get h model.torrentsByHash) model.selectedTorrentHash


setTorrentsByHash : TorrentsByHash -> Model -> Model
setTorrentsByHash new model =
    { model | torrentsByHash = new }


setTorrentFilter : TorrentFilter -> Model -> Model
setTorrentFilter new model =
    { model | torrentFilter = new }


clearFiles : Model -> Model
clearFiles model =
    { model | sortedFiles = [], keyedFiles = Dict.empty }


setSortedFiles : List String -> Model -> Model
setSortedFiles new model =
    { model | sortedFiles = new }


setKeyedFiles : FilesByKey -> Model -> Model
setKeyedFiles new model =
    { model | keyedFiles = new }


setMessages : List Message -> Model -> Model
setMessages new model =
    { model | messages = new }


addMessage : Message -> Model -> Model
addMessage new model =
    { model | messages = Model.Message.addMessage new model.messages }


addMessages : List Message -> Model -> Model
addMessages new model =
    { model | messages = Model.Message.addMessages new model.messages }


setSpeedChartHover : List Model.SpeedChart.DataSeries -> Model -> Model
setSpeedChartHover new model =
    { model | speedChartHover = new }


setHamburgerMenuVisible : Bool -> Model -> Model
setHamburgerMenuVisible new model =
    { model | hamburgerMenuVisible = new }


setResizeOp : Maybe Model.Table.ResizeOp -> Model -> Model
setResizeOp new model =
    { model | resizeOp = new }


setTimeZone : Time.Zone -> Model -> Model
setTimeZone new model =
    { model | timezone = new }


setCurrentTime : Time.Posix -> Model -> Model
setCurrentTime new model =
    { model | currentTime = new }



-- CMD HELPERS


addCmd : Cmd Msg -> Model -> ( Model, Cmd Msg )
addCmd cmd model =
    ( model, cmd )


noCmd : Model -> ( Model, Cmd Msg )
noCmd model =
    ( model, Cmd.none )


andThen : (Model -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
andThen fn ( model, cmd ) =
    let
        ( nextModel, nextCmd ) =
            fn model
    in
    ( nextModel, Cmd.batch [ cmd, nextCmd ] )
