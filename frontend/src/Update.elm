module Update exposing (update)

import Browser.Dom
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model exposing (..)
import Model.Config
import Model.Message exposing (addMessage)
import Model.Table
import Model.WebsocketData
import Ports
import Update.EndResizeOp
import Update.ProcessTorrents
import Update.ProcessTraffic
import Update.ProcessWebsocketStatusUpdated
import Update.ResizeOpMoved
import Update.SaveConfig
import Update.SetColumnAutoWidth
import Update.SetSortBy
import Update.StartResizeOp
import Update.ToggleTorrentAttributeVisibility


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- rename this to MouseDown and handle the button in a method here
        MouseDown attribute pos button keys ->
            model |> handleMouseDown attribute pos button keys

        TorrentAttributeResized resizeOp pos ->
            model |> Update.ResizeOpMoved.update resizeOp pos

        TorrentAttributeResizeEnded resizeOp pos ->
            model |> Update.EndResizeOp.update resizeOp pos

        GotColumnWidth attribute result ->
            ( setColumnWidth model attribute result, Cmd.none )

        RefreshClicked ->
            model |> addCmd Ports.getFullTorrents

        SaveConfigClicked ->
            model |> Update.SaveConfig.update

        ShowPreferencesClicked ->
            model |> setPreferencesVisible True |> addCmd Cmd.none

        ToggleTorrentAttributeVisibility attribute ->
            model |> Update.ToggleTorrentAttributeVisibility.update attribute

        SetSortBy attribute ->
            model |> Update.SetSortBy.update attribute

        SpeedChartHover data ->
            model |> setSpeedChartHover data |> addCmd Cmd.none

        RequestFullTorrents ->
            model |> addCmd Ports.getFullTorrents

        RequestUpdatedTorrents _ ->
            model |> addCmd Ports.getUpdatedTorrents

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


setColumnWidth : Model -> Model.Table.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model
setColumnWidth model attribute result =
    --- rename this to something better
    case result of
        Ok r ->
            Model.setConfig
                (Model.Config.setTorrentTable
                    (Model.Table.setColumnWidth
                        attribute
                        { px = r.element.width, auto = False }
                        model.config.torrentTable
                    )
                    model.config
                )
                model

        Err r ->
            let
                _ =
                    Debug.log "ERR: " r
            in
            model


processWebsocketResponse : Result JD.Error Model.WebsocketData.Data -> Model -> ( Model, Cmd Msg )
processWebsocketResponse result model =
    case result of
        Ok data ->
            processWebsocketData model data

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessages =
                    model.messages
                        |> addMessage
                            { message = JD.errorToString errStr
                            , severity = Model.Message.Error
                            }
            in
            model
                |> setMessages newMessages
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
                newMessages =
                    model.messages
                        |> addMessage
                            { message = errStr, severity = Model.Message.Error }
            in
            model
                |> setMessages newMessages
                |> addCmd Cmd.none
