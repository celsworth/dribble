module Update exposing (update)

import Dict exposing (Dict)
import Json.Decode as JD
import List
import List.Extra
import Model exposing (..)
import Model.ConfigCoder
import Model.TorrentSorter
import Model.Utils.Config
import Model.Utils.TorrentAttribute
import Ports
import Subscriptions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseUp ->
            ( { model | dragging = Nothing }, Cmd.none )

        MouseDown attribute edge ->
            ( { model | dragging = Just ( attribute, edge ) }, Cmd.none )

        MouseMove x y ->
            let
                newMousePosition =
                    { x = x, y = y }
            in
            case model.dragging of
                Just ( attribute, edge ) ->
                    ( parseMouseMove model attribute edge x y, Cmd.none )

                Nothing ->
                    ( { model | mousePosition = newMousePosition }, Cmd.none )

        RefreshClicked ->
            ( model, Subscriptions.getFullTorrents )

        SaveConfigClicked ->
            ( model, saveConfig model.config )

        ToggleTorrentAttributeVisibility attribute ->
            let
                newConfig =
                    Model.Utils.Config.toggleTorrentAttributeVisibility
                        attribute
                        model.config
            in
            ( { model | config = newConfig }, Cmd.none )

        SetSortBy attribute ->
            ( setSortBy model attribute, Cmd.none )

        RequestFullTorrents ->
            ( model, Subscriptions.getFullTorrents )

        RequestUpdatedTorrents _ ->
            ( model, Subscriptions.getUpdatedTorrents )

        WebsocketData result ->
            processWebsocketResponse model result

        WebsocketStatusUpdated result ->
            processWebsocketStatusUpdated model result


parseMouseMove : Model -> TorrentAttribute -> Edge -> Float -> Float -> Model
parseMouseMove model attribute edge x y =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute

        oldWidth =
            case Dict.get key model.columnWidths of
                Just w ->
                    w

                Nothing ->
                    50

        newMousePosition =
            { x = x, y = y }

        newWidth =
            oldWidth + (x - model.mousePosition.x)

        newDict =
            Dict.insert key newWidth model.columnWidths
    in
    { model | mousePosition = newMousePosition, columnWidths = newDict }


processMouseUp : Model -> Model
processMouseUp model =
    model


saveConfig : Config -> Cmd msg
saveConfig config =
    Model.ConfigCoder.encode config |> Ports.storeConfig


setSortBy : Model -> TorrentAttribute -> Model
setSortBy model attribute =
    let
        newConfig =
            Model.Utils.Config.setSortBy
                attribute
                model.config

        sortedTorrents =
            Model.TorrentSorter.sort newConfig.sortBy
                (Dict.values model.torrentsByHash)
    in
    { model | config = newConfig, sortedTorrents = sortedTorrents }


processWebsocketStatusUpdated : Model -> Result JD.Error Bool -> ( Model, Cmd Msg )
processWebsocketStatusUpdated model result =
    case result of
        Ok connected ->
            let
                cmd =
                    if connected then
                        Subscriptions.getFullTorrents

                    else
                        Cmd.none
            in
            ( { model | websocketConnected = connected }, cmd )

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessages =
                    List.append model.messages
                        [ { message = JD.errorToString errStr, severity = ErrorSeverity }
                        ]
            in
            ( { model | messages = newMessages }, Cmd.none )


processWebsocketResponse : Model -> Result JD.Error DecodedData -> ( Model, Cmd Msg )
processWebsocketResponse model result =
    case result of
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
        TorrentsReceived torrentList ->
            let
                byHash =
                    torrentsByHash model torrentList

                sortedTorrents =
                    Model.TorrentSorter.sort model.config.sortBy
                        (Dict.values byHash)
            in
            { model | sortedTorrents = sortedTorrents, torrentsByHash = byHash }

        Error errStr ->
            let
                newMessages =
                    List.append model.messages
                        [ { message = errStr, severity = ErrorSeverity }
                        ]
            in
            { model | messages = newMessages }


torrentsByHash : Model -> List Torrent -> Dict String Torrent
torrentsByHash model torrentList =
    let
        newDict =
            Dict.fromList <| List.map (\t -> ( t.hash, t )) torrentList
    in
    if Dict.isEmpty model.torrentsByHash then
        newDict

    else
        Dict.union newDict model.torrentsByHash
