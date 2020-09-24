module Update exposing (update)

import Browser.Dom
import Coders.Base
import Coders.Config
import Dict exposing (Dict)
import Json.Decode as JD
import List.Extra
import Model exposing (..)
import Model.Shared
import Model.TorrentSorter
import Model.Utils.Config
import Ports
import Update.MouseHandlers


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
            ( model, getFullTorrents )

        SaveConfigClicked ->
            ( model, saveConfig model.config )

        ShowPreferencesClicked ->
            ( { model | preferencesVisible = True }, Cmd.none )

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

        SpeedChartHover data ->
            ( { model | speedChartHover = data }, Cmd.none )

        RequestFullTorrents ->
            ( model, getFullTorrents )

        RequestUpdatedTorrents _ ->
            ( model, getUpdatedTorrents )

        RequestUpdatedTraffic _ ->
            ( model, getTraffic )

        WebsocketData result ->
            processWebsocketResponse model result

        WebsocketStatusUpdated result ->
            processWebsocketStatusUpdated model result


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


saveConfig : Config -> Cmd msg
saveConfig config =
    Coders.Config.encode config |> Ports.storeConfig


getFullTorrents : Cmd Msg
getFullTorrents =
    Ports.sendMessage Coders.Base.getFullTorrents


getUpdatedTorrents : Cmd Msg
getUpdatedTorrents =
    Ports.sendMessage Coders.Base.getUpdatedTorrents


getTraffic : Cmd Msg
getTraffic =
    Ports.sendMessage Coders.Base.getTraffic


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
                        Cmd.batch
                            [ getFullTorrents
                            , getTraffic
                            ]

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

        TrafficReceived traffic ->
            processTraffic model traffic

        Error errStr ->
            let
                newMessages =
                    List.append model.messages
                        [ { message = errStr, severity = ErrorSeverity }
                        ]
            in
            { model | messages = newMessages }


processTraffic : Model -> Traffic -> Model
processTraffic model traffic =
    let
        {- get diffs from firstTraffic if it exists. If it doesn't, store this as firstTraffic only -}
        ( firstTraffic, newTraffic ) =
            case model.firstTraffic of
                Nothing ->
                    ( traffic, [] )

                Just ft ->
                    ( ft, List.append model.traffic [ trafficDiff model traffic ] )
    in
    { model | firstTraffic = Just firstTraffic, traffic = newTraffic }


trafficDiff : Model -> Traffic -> Traffic
trafficDiff model traffic =
    let
        firstTraffic =
            Maybe.withDefault { time = 0, upDiff = 0, downDiff = 0, upTotal = 0, downTotal = 0 }
                model.firstTraffic

        prevTraffic =
            Maybe.withDefault firstTraffic (List.Extra.last model.traffic)

        timeDiff =
            traffic.time - prevTraffic.time
    in
    { traffic
        | upDiff = (traffic.upTotal - prevTraffic.upTotal) // timeDiff
        , downDiff = (traffic.downTotal - prevTraffic.downTotal) // timeDiff
    }


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
