module Update exposing (update)

import Dict exposing (Dict)
import Json.Decode as JD
import List
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
        TorrentsReceived torrentList ->
            -- entire new list of torrents received
            -- TODO: incremental updates
            let
                torrentsByHash =
                    Dict.fromList <| List.map (\t -> ( t.hash, t )) torrentList

                -- could also sort Dict.values torrentsByHash
                -- when we do incremental updates
                sortedTorrents =
                    sortTorrents model.config.sortBy torrentList

                newTorrents =
                    { sorted = sortedTorrents, byHash = torrentsByHash }
            in
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


sortTorrents : Sort -> List Torrent -> List Torrent
sortTorrents sortBy torrents =
    List.sortWith (sortComparator <| sortBy) torrents


sortComparator : Sort -> Torrent -> Torrent -> Order
sortComparator sortBy a b =
    case sortBy of
        SortBy Name direction ->
            maybeReverse direction <| torrentCmp a b .name

        SortBy Size direction ->
            maybeReverse direction <| torrentCmp a b .size

        SortBy CreationTime direction ->
            maybeReverse direction <| torrentCmp a b .creationTime

        SortBy StartedTime direction ->
            maybeReverse direction <| torrentCmp a b .startedTime

        SortBy FinishedTime direction ->
            maybeReverse direction <| torrentCmp a b .finishedTime

        SortBy UploadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .uploadedBytes

        SortBy UploadRate direction ->
            maybeReverse direction <| torrentCmp a b .uploadRate

        SortBy DownloadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .downloadedBytes

        SortBy DownloadRate direction ->
            maybeReverse direction <| torrentCmp a b .downloadRate

        SortBy Label direction ->
            maybeReverse direction <| torrentCmp a b .label


torrentCmp : Torrent -> Torrent -> (Torrent -> comparable) -> Order
torrentCmp a b method =
    let
        a1 =
            method a

        b1 =
            method b
    in
    if a1 == b1 then
        EQ

    else if a1 > b1 then
        GT

    else
        LT


maybeReverse : SortDirection -> Order -> Order
maybeReverse direction order =
    case direction of
        Asc ->
            order

        Desc ->
            case order of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT
