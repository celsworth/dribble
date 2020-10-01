module Update exposing (update)

import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model exposing (..)
import Model.Message
import Model.Table
import Model.WebsocketData
import Ports
import Update.ColumnWidthReceived
import Update.EndResizeOp
import Update.ProcessTorrents
import Update.ProcessTraffic
import Update.ProcessWebsocketStatusUpdated
import Update.ResizeOpMoved
import Update.SaveConfig
import Update.SetColumnAutoWidth
import Update.SetCurrentTime
import Update.SetSortBy
import Update.StartResizeOp
import Update.ToggleTorrentAttributeVisibility
import Update.TorrentNameFilterChanged


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseDown attribute pos button keys ->
            model |> handleMouseDown attribute pos button keys

        TorrentAttributeResized resizeOp pos ->
            model |> Update.ResizeOpMoved.update resizeOp pos

        TorrentAttributeResizeEnded resizeOp pos ->
            model |> Update.EndResizeOp.update resizeOp pos

        GotColumnWidth attribute result ->
            model |> Update.ColumnWidthReceived.update attribute result

        SaveConfigClicked ->
            model |> Update.SaveConfig.update

        ShowPreferencesClicked ->
            model |> setPreferencesVisible True |> addCmd Cmd.none

        TorrentNameFilterChanged value ->
            model |> Update.TorrentNameFilterChanged.update value

        ToggleLogsVisible ->
            model |> toggleLogsVisible |> addCmd Cmd.none

        ToggleTorrentAttributeVisibility attribute ->
            model |> Update.ToggleTorrentAttributeVisibility.update attribute

        SetSortBy attribute ->
            model |> Update.SetSortBy.update attribute

        SpeedChartHover data ->
            model |> setSpeedChartHover data |> addCmd Cmd.none

        Tick time ->
            model |> Update.SetCurrentTime.update time

        RequestUpdatedTraffic _ ->
            model |> addCmd Ports.getTraffic

        WebsocketData result ->
            model |> processWebsocketResponse result

        WebsocketStatusUpdated result ->
            model |> Update.ProcessWebsocketStatusUpdated.update result


handleMouseDown : Model.Table.Attribute -> Model.Table.MousePosition -> Mouse.Button -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
handleMouseDown attribute mousePosition mouseButton mouseKeys model =
    if mouseKeys.alt then
        -- should be in right click menu
        Update.SetColumnAutoWidth.update attribute model

    else
        case mouseButton of
            Mouse.MainButton ->
                Update.StartResizeOp.update attribute mousePosition model

            _ ->
                ( model, Cmd.none )


processWebsocketResponse : Result JD.Error Model.WebsocketData.Data -> Model -> ( Model, Cmd Msg )
processWebsocketResponse result model =
    case result of
        Ok data ->
            processWebsocketData model data

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessage =
                    { summary = Just "Invalid JSON received from Websocket"
                    , detail = Just <| JD.errorToString errStr
                    , severity = Model.Message.Error
                    , time = model.currentTime
                    }
            in
            model
                |> addMessage newMessage
                |> addCmd Cmd.none


processWebsocketData : Model -> Model.WebsocketData.Data -> ( Model, Cmd Msg )
processWebsocketData model data =
    case data of
        Model.WebsocketData.TorrentsReceived torrents ->
            model
                |> Update.ProcessTorrents.update torrents
                |> addCmd Cmd.none

        Model.WebsocketData.TrafficReceived traffic ->
            model
                |> Update.ProcessTraffic.update traffic
                |> addCmd Cmd.none

        Model.WebsocketData.Error errStr ->
            let
                newMessage =
                    { summary = Just "WebsocketData Error"
                    , detail = Just errStr
                    , severity = Model.Message.Error
                    , time = model.currentTime
                    }
            in
            model
                |> addMessage newMessage
                |> addCmd Cmd.none
