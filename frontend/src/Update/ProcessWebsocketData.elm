module Update.ProcessWebsocketData exposing (update)

import Dict
import Json.Decode as JD
import Model exposing (..)
import Model.Message
import Model.WebsocketData
import Update.ProcessFiles
import Update.ProcessSystemInfo
import Update.ProcessTorrents
import Update.ProcessTraffic


update : Result JD.Error Model.WebsocketData.Data -> Model -> ( Model, Cmd Msg )
update result model =
    case result of
        Ok data ->
            model |> processWebsocketData data

        Result.Err errStr ->
            model |> handleWebsocketError (JD.errorToString errStr)


handleWebsocketError : String -> Model -> ( Model, Cmd Msg )
handleWebsocketError errStr model =
    -- this is used when we get invalid JSON, rather than unexpected data
    let
        newMessage =
            { summary = Just "Invalid JSON received from Websocket"
            , detail = Just <| errStr
            , severity = Model.Message.Error
            , time = model.currentTime
            }
    in
    model |> addMessage newMessage |> noCmd


processWebsocketData : Model.WebsocketData.Data -> Model -> ( Model, Cmd Msg )
processWebsocketData data model =
    case data of
        Model.WebsocketData.SystemInfoReceived systemInfo ->
            model |> Update.ProcessSystemInfo.update systemInfo

        Model.WebsocketData.TorrentsReceived torrents ->
            model |> Update.ProcessTorrents.update torrents

        Model.WebsocketData.FilesReceived torrents ->
            model |> Update.ProcessFiles.update torrents

        Model.WebsocketData.TrafficReceived traffic ->
            model |> Update.ProcessTraffic.update traffic

        Model.WebsocketData.Error errStr ->
            model |> handleWebsocketDataError errStr


handleWebsocketDataError : String -> Model -> ( Model, Cmd Msg )
handleWebsocketDataError errStr model =
    let
        newMessage =
            { summary = Just "Unexpected Websocket Data"
            , detail = Just errStr
            , severity = Model.Message.Error
            , time = model.currentTime
            }
    in
    model |> addMessage newMessage |> noCmd
