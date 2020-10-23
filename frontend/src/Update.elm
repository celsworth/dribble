module Update exposing (update)

import Html.Events.Extra.Mouse as Mouse
import Model exposing (..)
import Model.Attribute
import Model.Table
import Model.Window
import Update.ColumnWidthReceived
import Update.DragAndDropReceived
import Update.EndResizeOp
import Update.ProcessWebsocketData
import Update.ProcessWebsocketStatusUpdated
import Update.ResetConfig
import Update.ResizeOpMoved
import Update.SaveConfig
import Update.SetColumnAutoWidth
import Update.SetPreference
import Update.SetSelectedTorrent
import Update.SetSortBy
import Update.StartResizeOp
import Update.SubscribeToTorrent
import Update.ToggleAttributeVisibility
import Update.ToggleWindowVisible
import Update.TorrentFilterChanged
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
        call =
            -- _ is passed in model
            \meth args _ -> model |> meth args |> noCmd
    in
    case msg of
        SetTimeZone zone ->
            r |> andThen (call setTimeZone zone)

        MouseDown attribute pos button keys ->
            r |> andThen (handleMouseDown attribute pos button keys)

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

        SetPreference preferenceUpdate ->
            r
                |> andThen (Update.SetPreference.update preferenceUpdate)
                |> andThen Update.SaveConfig.update

        ShowGroupLists ->
            r |> andThen (call setGroupListsVisible True)

        ResetConfigClicked ->
            r |> andThen Update.ResetConfig.update

        SaveConfigClicked ->
            r |> andThen Update.SaveConfig.update

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

        TorrentFilterChanged value ->
            r |> andThen (Update.TorrentFilterChanged.update value)

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

        SpeedChartHover data ->
            r |> andThen (call setSpeedChartHover data)

        Tick time ->
            r |> andThen (call setCurrentTime time)

        WebsocketData result ->
            r |> andThen (Update.ProcessWebsocketData.update result)

        WebsocketStatusUpdated result ->
            r |> andThen (Update.ProcessWebsocketStatusUpdated.update result)

        WindowResized result ->
            r |> andThen (Update.WindowResized.update result)

        DnDMsg tableType dndmsg ->
            r |> andThen (Update.DragAndDropReceived.update tableType dndmsg)



-- TODO: move to Update/


handleMouseDown : Model.Attribute.Attribute -> Model.Table.MousePosition -> Mouse.Button -> Mouse.Keys -> Model -> ( Model, Cmd Msg )
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
