module Update exposing (update)

import Browser.Dom
import Coders.Config
import Json.Decode as JD
import Model exposing (..)
import Model.Shared
import Ports
import Update.MouseHandlers
import Update.ProcessTorrents
import Update.ProcessTraffic
import Update.ProcessWebsocketStatusUpdated
import Update.SaveConfig
import Update.SetSortBy
import Update.ToggleTorrentAttributeVisibility


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        TorrentAttributeResizeStarted attribute pos button keys ->
            Update.MouseHandlers.processTorrentAttributeResizeStarted
                model
                attribute
                pos
                button
                keys

        TorrentAttributeResized resizeOp pos ->
            Update.MouseHandlers.processTorrentAttributeResized
                model
                resizeOp
                pos

        TorrentAttributeResizeEnded resizeOp pos ->
            Update.MouseHandlers.processTorrentAttributeResizeEnded
                model
                resizeOp
                pos

        GotColumnWidth attribute result ->
            ( setColumnWidth model attribute result, Cmd.none )

        RefreshClicked ->
            ( model, Ports.getFullTorrents )

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


setColumnWidth : Model -> TorrentAttribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model
setColumnWidth model attribute result =
    case result of
        Ok r ->
            Model.Shared.setColumnWidth
                model
                attribute
                { px = r.element.width, auto = False }

        Err r ->
            let
                _ =
                    Debug.log "ERR: " r
            in
            model


processWebsocketResponse : Result JD.Error DecodedData -> Model -> ( Model, Cmd Msg )
processWebsocketResponse result model =
    case result of
        Ok data ->
            processWebsocketData model data

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessages =
                    List.append model.messages
                        [ { message = JD.errorToString errStr, severity = ErrorSeverity }
                        ]
            in
            model
                |> setMessages newMessages
                |> addCmd Cmd.none


processWebsocketData : Model -> DecodedData -> ( Model, Cmd Msg )
processWebsocketData model data =
    case data of
        TorrentsReceived torrents ->
            model
                |> Update.ProcessTorrents.update torrents
                |> addCmd Cmd.none

        TrafficReceived traffic ->
            model
                |> Update.ProcessTraffic.update traffic
                |> addCmd Cmd.none

        Error errStr ->
            let
                newMessages =
                    List.append model.messages
                        [ { message = errStr, severity = ErrorSeverity }
                        ]
            in
            model
                |> setMessages newMessages
                |> addCmd Cmd.none
