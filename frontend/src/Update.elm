module Update exposing (update)

import Json.Decode as JD
import Model exposing (..)
import Model.ConfigCoder as ConfigCoder
import Ports
import Subscriptions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        RefreshClicked ->
            ( model, Subscriptions.getTorrents )

        SaveConfigClicked ->
            ( model, saveConfig model.config )

        WebsocketData response ->
            processWebsocketResponse model response


processWebsocketResponse : Model -> Result JD.Error DecodedData -> ( Model, Cmd Msg )
processWebsocketResponse model response =
    case response of
        Ok data ->
            ( processWebsocketData model data, Cmd.none )

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessages =
                    List.append model.messages
                        [ { message = JD.errorToString errStr, severity = ErrorSeverity }
                        ]
            in
            ( { model | messages = newMessages }, Cmd.none )


processWebsocketData : Model -> DecodedData -> Model
processWebsocketData model data =
    case data of
        Torrents newTorrents ->
            { model | torrents = newTorrents }

        Error errStr ->
            let
                newMessages =
                    List.append model.messages
                        [ { message = errStr, severity = ErrorSeverity }
                        ]
            in
            { model | messages = newMessages }


saveConfig : Config -> Cmd msg
saveConfig config =
    ConfigCoder.encode config |> Ports.storeConfig
