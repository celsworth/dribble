module Update exposing (update)

import Browser.Dom
import Coders.Base
import Coders.Config
import Dict exposing (Dict)
import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import List
import List.Extra
import Model exposing (..)
import Model.Shared
import Model.TorrentSorter
import Model.Utils.Config
import Model.Utils.TorrentAttribute
import Ports
import Subscriptions
import Task


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MouseDownMsg attribute pos keys ->
            processMouseDown model attribute pos keys

        MouseMoveMsg dragging pos ->
            case model.dragging of
                -- ignore surplus MouseMoveMsg if we're not dragging
                Nothing ->
                    ( model, Cmd.none )

                _ ->
                    ( processMouseMove model dragging pos, Cmd.none )

        MouseUpMsg dragging pos ->
            ( processMouseUp model dragging pos, Cmd.none )

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

        RequestFullTorrents ->
            ( model, getFullTorrents )

        RequestUpdatedTorrents _ ->
            ( model, getUpdatedTorrents )

        WebsocketData result ->
            processWebsocketResponse model result

        WebsocketStatusUpdated result ->
            processWebsocketStatusUpdated model result

        GotColumnWidth attribute result ->
            ( setColumnWidth model attribute result, Cmd.none )


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



-- TODO: move mouse stuff to Update.Shared.MouseProcessing or something?


processMouseDown : Model -> TorrentAttribute -> MousePosition -> Mouse.Keys -> ( Model, Cmd Msg )
processMouseDown model attribute pos keys =
    let
        ( x, y ) =
            pos

        id =
            Model.Utils.TorrentAttribute.attributeToTableHeaderId attribute

        {- move to a context menu -}
        cmd =
            Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement id
    in
    if keys.alt then
        {- move to a context menu -}
        ( Model.Shared.setColumnWidthAuto model attribute, cmd )

    else
        ( { model | mousePosition = pos, dragging = Just ( attribute, x ) }
        , Cmd.none
        )


processMouseMove : Model -> Dragging -> MousePosition -> Model
processMouseMove model dragging pos =
    {- when dragging, if releasing the mouse button now would result in
       a column width below minimumColumnPx, ignore the new mousePosition
    -}
    let
        ( attribute, mouseStartX ) =
            dragging

        newColumnWidth =
            Model.Shared.calculateNewColumnWidth model attribute mouseStartX pos

        -- stop the dragbar moving any further if the column would be too narrow
        valid =
            newColumnWidth.px > Model.Shared.minimumColumnPx
    in
    if valid then
        { model | mousePosition = pos }

    else
        model


processMouseUp : Model -> Dragging -> MousePosition -> Model
processMouseUp model dragging pos =
    let
        ( attribute, mouseStartX ) =
            dragging

        newWidth =
            Model.Shared.calculateNewColumnWidth model attribute mouseStartX pos

        newModel =
            Model.Shared.setColumnWidth model attribute newWidth
    in
    { newModel | dragging = Nothing }


saveConfig : Config -> Cmd msg
saveConfig config =
    Coders.Config.encode config |> Ports.storeConfig


getFullTorrents : Cmd Msg
getFullTorrents =
    Ports.sendMessage Coders.Base.getFullTorrents


getUpdatedTorrents : Cmd Msg
getUpdatedTorrents =
    Ports.sendMessage Coders.Base.getUpdatedTorrents


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
                        getFullTorrents

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
