module Update exposing (update)

import Model exposing (..)
import Model.Attribute
import Model.Window
import Update.ClearContextMenu
import Update.ColumnReordered
import Update.ColumnWidthReceived
import Update.EndResizeOp
import Update.FilterTorrents
import Update.ProcessWebsocketData
import Update.ProcessWebsocketStatusUpdated
import Update.ResetConfig
import Update.ResetTorrentFilter
import Update.ResetTorrentGroupSelection
import Update.ResizeOpMoved
import Update.SaveConfig
import Update.SetColumnAutoWidth
import Update.SetContextMenu
import Update.SetPreference
import Update.SetSelectedTorrent
import Update.SetSortBy
import Update.StartResizeOp
import Update.SubscribeToTorrent
import Update.ToggleAttributeVisibility
import Update.ToggleWindowVisible
import Update.TorrentFilterChanged
import Update.TorrentGroupSelected
import Update.WindowResized
import Utils.Mouse as Mouse


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        r =
            ( model, Cmd.none )

        {- shortcut;
           instead of: andThen (\_ -> ( setTimeZone zone model, Cmd.none ))
           do: andThen (call setTimeZone zone)
        -}
        call =
            -- _ is passed in model
            \meth args _ -> model |> meth args |> noCmd
    in
    case msg of
        NoOp ->
            r

        SetTimeZone zone ->
            r |> andThen (call setTimeZone zone)

        Scroll scrollEvent ->
            r |> andThen (call setTop scrollEvent.scrollTop)

        MouseDown attribute mouseEvent ->
            r |> andThen (handleMouseDown attribute mouseEvent)

        AttributeResized resizeOp pos ->
            r |> andThen (Update.ResizeOpMoved.update resizeOp pos)

        AttributeResizeEnded resizeOp pos ->
            r
                |> andThen (Update.EndResizeOp.update resizeOp pos)
                |> andThen Update.SaveConfig.update

        GotColumnWidth attribute result ->
            r
                |> andThen (Update.ColumnWidthReceived.update attribute result)
                |> andThen Update.SaveConfig.update

        ColumnReordered tableType dndmsg ->
            r |> andThen (Update.ColumnReordered.update tableType dndmsg)

        DisplayContextMenu contextMenuFor mouseEvent ->
            r |> andThen (Update.SetContextMenu.update contextMenuFor mouseEvent)

        ClearContextMenu ->
            r |> andThen Update.ClearContextMenu.update

        SetPreference preferenceUpdate ->
            r
                |> andThen (Update.SetPreference.update preferenceUpdate)
                |> andThen Update.SaveConfig.update

        ResetConfigClicked ->
            r |> andThen Update.ResetConfig.update

        SaveConfigClicked ->
            r |> andThen Update.SaveConfig.update

        ResetFilterClicked ->
            r
                |> andThen Update.ResetTorrentFilter.update
                |> andThen Update.FilterTorrents.update

        TorrentFilterChanged value ->
            r
                |> andThen (Update.TorrentFilterChanged.update value)
                |> andThen Update.FilterTorrents.update

        SetHamburgerMenuVisible bool ->
            r |> andThen (call setHamburgerMenuVisible bool)

        TogglePreferencesVisible ->
            r
                |> andThen (Update.ToggleWindowVisible.update Model.Window.Preferences)
                |> andThen Update.SaveConfig.update

        ToggleLogsVisible ->
            r
                |> andThen (Update.ToggleWindowVisible.update Model.Window.Logs)
                |> andThen Update.SaveConfig.update

        ResetTorrentGroupSelection ->
            r
                |> andThen Update.ResetTorrentGroupSelection.update
                |> andThen Update.FilterTorrents.update

        TorrentGroupSelected groupType keys ->
            r
                |> andThen (Update.TorrentGroupSelected.update groupType keys)
                |> andThen Update.FilterTorrents.update

        SetColumnAutoWidth attribute ->
            r
                |> andThen (Update.SetColumnAutoWidth.update attribute)
                |> andThen Update.ClearContextMenu.update

        ToggleAttributeVisibility attribute ->
            r
                |> andThen (Update.ToggleAttributeVisibility.update attribute)
                |> andThen Update.SaveConfig.update

        SetSortBy attribute ->
            r
                |> andThen (Update.SetSortBy.update attribute)
                |> andThen Update.SaveConfig.update

        TorrentRowSelected hash ->
            r
                |> andThen (Update.SetSelectedTorrent.update hash)
                |> andThen Update.SubscribeToTorrent.update

        SetSpeedChartTimeRange new ->
            r |> andThen (call setSpeedChartTimeRange new)

        SpeedChartHover data ->
            r |> andThen (call setSpeedChartHover data)

        Tick time ->
            -- this needs FilterTorrents because of relative time filtering
            r
                |> andThen (call setCurrentTime time)
                |> andThen Update.FilterTorrents.update

        WebsocketData result ->
            r |> andThen (Update.ProcessWebsocketData.update result)

        WebsocketStatusUpdated result ->
            r |> andThen (Update.ProcessWebsocketStatusUpdated.update result)

        WindowResized result ->
            r |> andThen (Update.WindowResized.update result)



-- TODO: move to Update/


handleMouseDown : Model.Attribute.Attribute -> Mouse.Event -> Model -> ( Model, Cmd Msg )
handleMouseDown attribute { button, keys, clientPos } model =
    case button of
        Mouse.MainButton ->
            if keys.alt then
                -- also in right click menu
                Update.SetColumnAutoWidth.update attribute model

            else
                Update.StartResizeOp.update attribute clientPos model

        _ ->
            ( model, Cmd.none )
