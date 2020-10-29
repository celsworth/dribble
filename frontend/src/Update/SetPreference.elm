module Update.SetPreference exposing (update)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Preferences as MP
import Model.Table


update : MP.PreferenceUpdate -> Model -> ( Model, Cmd Msg )
update preferenceUpdate model =
    case preferenceUpdate of
        MP.Table tableType (MP.Layout layout) ->
            model
                |> setTableLayout tableType layout
                |> noCmd

        MP.EnableContextMenus enabled ->
            model
                |> setEnableContextMenus enabled
                |> noCmd



-- TABLE LAYOUT


setTableLayout : Model.Table.Type -> Model.Table.Layout -> Model -> Model
setTableLayout tableType layout model =
    let
        newConfig =
            case tableType of
                Model.Table.Torrents ->
                    torrentTableLayout model layout

                Model.Table.Files ->
                    fileTableLayout model layout

                Model.Table.Peers ->
                    peerTableLayout model layout
    in
    model |> setConfig newConfig


torrentTableLayout : Model -> Model.Table.Layout -> Config
torrentTableLayout model layout =
    let
        tableConfig =
            model.config.torrentTable

        newTableConfig =
            tableConfig |> Model.Table.setLayout layout
    in
    model.config |> Model.Config.setTorrentTable newTableConfig


fileTableLayout : Model -> Model.Table.Layout -> Config
fileTableLayout model layout =
    let
        tableConfig =
            model.config.fileTable

        newTableConfig =
            tableConfig |> Model.Table.setLayout layout
    in
    model.config |> Model.Config.setFileTable newTableConfig


peerTableLayout : Model -> Model.Table.Layout -> Config
peerTableLayout model layout =
    let
        tableConfig =
            model.config.peerTable

        newTableConfig =
            tableConfig |> Model.Table.setLayout layout
    in
    model.config |> Model.Config.setPeerTable newTableConfig



-- ENABLE CONTEXT MENUS


setEnableContextMenus : Bool -> Model -> Model
setEnableContextMenus enabled model =
    let
        newConfig =
            model.config |> Model.Config.setEnableContextMenus enabled
    in
    model |> setConfig newConfig
