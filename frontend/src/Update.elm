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
            ( processWebsocketData model response, Cmd.none )


processWebsocketData : Model -> Result JD.Error DecodedData -> Model
processWebsocketData model response =
    case response of
        Ok data ->
            case data of
                Torrents newTorrents ->
                    { model | torrents = newTorrents }

                Error errStr ->
                    { model | error = Just errStr }

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            { model | error = Just (JD.errorToString errStr) }


saveConfig : Config -> Cmd msg
saveConfig config =
    ConfigCoder.encode config |> Ports.storeConfig
