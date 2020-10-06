module Update exposing (update)

import Html.Events.Extra.Mouse as Mouse
import Json.Decode as JD
import Model exposing (..)
import Model.Message
import Model.Table
import Model.WebsocketData
import Model.Window
import Update.ColumnWidthReceived
import Update.EndResizeOp
import Update.ProcessTorrents
import Update.ProcessTraffic
import Update.ProcessWebsocketStatusUpdated
import Update.ResizeOpMoved
import Update.SaveConfig
import Update.SetColumnAutoWidth
import Update.SetCurrentTime
import Update.SetPreference
import Update.SetSortBy
import Update.StartResizeOp
import Update.ToggleTorrentAttributeVisibility
import Update.ToggleWindowVisible
import Update.TorrentNameFilterChanged
import Update.WindowResized


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        r =
            ( model, Cmd.none )

        {- shortcut;
           instead of: andThen (\_ -> ( setTimeZone zone model, Cmd.none ))
           do: andThen (call setTimeZone zone)
        -}
        noCmd =
            -- _ is passed in model
            \meth args _ -> ( meth args model, Cmd.none )
    in
    case msg of
        SetTimeZone zone ->
            r |> andThen (noCmd setTimeZone zone)

        MouseDown attribute pos button keys ->
            r |> andThen (handleMouseDown attribute pos button keys)

        TorrentAttributeResized resizeOp pos ->
            r |> andThen (Update.ResizeOpMoved.update resizeOp pos)

        TorrentAttributeResizeEnded resizeOp pos ->
            r
                |> andThen (Update.EndResizeOp.update resizeOp pos)
                |> andThen Update.SaveConfig.update

        GotColumnWidth attribute result ->
            r
                |> andThen (Update.ColumnWidthReceived.update attribute result)
                |> andThen Update.SaveConfig.update

        SetPreference preferenceUpdate ->
            r
                |> andThen (Update.SetPreference.update preferenceUpdate)
                |> andThen Update.SaveConfig.update

        SaveConfigClicked ->
            r |> andThen Update.SaveConfig.update

        SetHamburgerMenuVisible bool ->
            r |> andThen (noCmd setHamburgerMenuVisible bool)

        TogglePreferencesVisible ->
            r |> andThen (Update.ToggleWindowVisible.update Model.Window.Preferences)

        ToggleLogsVisible ->
            r |> andThen (Update.ToggleWindowVisible.update Model.Window.Logs)

        TorrentNameFilterChanged value ->
            r |> andThen (Update.TorrentNameFilterChanged.update value)

        ToggleTorrentAttributeVisibility attribute ->
            r
                |> andThen (Update.ToggleTorrentAttributeVisibility.update attribute)
                |> andThen Update.SaveConfig.update

        SetSortBy attribute ->
            r
                |> andThen (Update.SetSortBy.update attribute)
                |> andThen Update.SaveConfig.update

        SpeedChartHover data ->
            r |> andThen (noCmd setSpeedChartHover data)

        Tick time ->
            r |> andThen (Update.SetCurrentTime.update time)

        WebsocketData result ->
            r |> andThen (processWebsocketResponse result)

        WebsocketStatusUpdated result ->
            r |> andThen (Update.ProcessWebsocketStatusUpdated.update result)

        WindowResized result ->
            r |> andThen (Update.WindowResized.update result)



-- TODO: move to Update/


handleMouseDown : Model.Table.Attribute -> Model.Table.MousePosition -> Mouse.Button -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
handleMouseDown attribute mousePosition mouseButton mouseKeys model =
    if mouseKeys.alt then
        -- should be in right click menu
        Update.SetColumnAutoWidth.update attribute model

    else
        case mouseButton of
            Mouse.MainButton ->
                Update.StartResizeOp.update attribute mousePosition model

            _ ->
                ( model, Cmd.none )


processWebsocketResponse : Result JD.Error Model.WebsocketData.Data -> Model -> ( Model, Cmd Msg )
processWebsocketResponse result model =
    case result of
        Ok data ->
            processWebsocketData model data

        Result.Err errStr ->
            -- meh it'll do for now. this is used when we get invalid JSON
            let
                newMessage =
                    { summary = Just "Invalid JSON received from Websocket"
                    , detail = Just <| JD.errorToString errStr
                    , severity = Model.Message.Error
                    , time = model.currentTime
                    }
            in
            model
                |> addMessage newMessage
                |> addCmd Cmd.none


processWebsocketData : Model -> Model.WebsocketData.Data -> ( Model, Cmd Msg )
processWebsocketData model data =
    case data of
        Model.WebsocketData.TorrentsReceived torrents ->
            model
                |> Update.ProcessTorrents.update torrents
                |> addCmd Cmd.none

        Model.WebsocketData.TrafficReceived traffic ->
            model
                |> Update.ProcessTraffic.update traffic
                |> addCmd Cmd.none

        Model.WebsocketData.Error errStr ->
            let
                newMessage =
                    { summary = Just "Unexpected Websocket Data"
                    , detail = Just errStr
                    , severity = Model.Message.Error
                    , time = model.currentTime
                    }
            in
            model
                |> addMessage newMessage
                |> addCmd Cmd.none
