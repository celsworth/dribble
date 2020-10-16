module Update.ProcessWebsocketStatusUpdated exposing (update)

import Json.Decode as JD
import Model exposing (..)
import Model.Message exposing (Message)
import Ports


update : Result JD.Error Bool -> Model -> ( Model, Cmd Msg )
update result model =
    case result of
        Ok connected ->
            let
                changed =
                    model.websocketConnected /= connected

                cmd =
                    if connected then
                        Cmd.batch
                            [ Ports.getRtorrentSystemInfo
                            , Ports.getTorrents model
                            , Ports.getFiles model
                            , Ports.getTraffic
                            ]

                    else
                        Cmd.none
            in
            model
                |> maybeAddMessage changed connected
                |> setWebsocketConnected connected
                |> addCmd cmd

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessage =
                    { summary = Just "Invalid Websocket JSON"
                    , detail = Just <| JD.errorToString errStr
                    , severity = Model.Message.Error
                    , time = model.currentTime
                    }
            in
            model
                |> addMessage newMessage
                |> noCmd


maybeAddMessage : Bool -> Bool -> Model -> Model
maybeAddMessage changed connected model =
    if changed then
        model |> Model.addMessage (message connected model)

    else
        model


message : Bool -> Model -> Message
message connected model =
    if connected then
        { summary = Just "Websocket Connection Established"
        , detail = Nothing
        , severity = Model.Message.Info
        , time = model.currentTime
        }

    else
        { summary = Just "Websocket Connection Lost"
        , detail = Nothing
        , severity = Model.Message.Error
        , time = model.currentTime
        }
