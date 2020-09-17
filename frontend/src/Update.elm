module Update exposing (update)

import Dict exposing (Dict)
import Json.Decode as JD
import List
import List.Extra
import Model exposing (..)
import Model.ConfigCoder as ConfigCoder
import Model.Utils.Config
import Ports
import Subscriptions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        RequestFullTorrents ->
            ( model, Subscriptions.getFullTorrents )

        RequestUpdatedTorrents _ ->
            ( model, Subscriptions.getUpdatedTorrents )

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
                byHash =
                    torrentsByHash model torrentList

                sortedTorrents =
                    sortTorrents model.config.sortBy (Dict.values byHash)
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


saveConfig : Config -> Cmd msg
saveConfig config =
    ConfigCoder.encode config |> Ports.storeConfig


sortTorrents : Sort -> List Torrent -> List String
sortTorrents sortBy torrents =
    List.map .hash <|
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

        SortBy DownloadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .downloadedBytes

        SortBy DownloadRate direction ->
            maybeReverse direction <| torrentCmp a b .downloadRate

        SortBy UploadedBytes direction ->
            maybeReverse direction <| torrentCmp a b .uploadedBytes

        SortBy UploadRate direction ->
            maybeReverse direction <| torrentCmp a b .uploadRate

        SortBy PeersConnected direction ->
            maybeReverse direction <| torrentCmp a b .peersConnected

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
