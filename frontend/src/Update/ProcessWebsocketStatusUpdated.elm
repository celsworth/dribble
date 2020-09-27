module Update.ProcessWebsocketStatusUpdated exposing (update)

import Json.Decode as JD
import Model exposing (..)
import Model.Message
import Ports


update : Result JD.Error Bool -> Model -> ( Model, Cmd Msg )
update result model =
    case result of
        Ok connected ->
            let
                cmd =
                    if connected then
                        Cmd.batch
                            [ Ports.getFullTorrents
                            , Ports.getTraffic
                            ]

                    else
                        Cmd.none
            in
            model
                |> setWebsocketConnected connected
                |> addCmd cmd

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessages =
                    List.append model.messages
                        [ { message = JD.errorToString errStr
                          , severity = Model.Message.Error
                          }
                        ]
            in
            model
                |> setMessages newMessages
                |> addCmd Cmd.none
