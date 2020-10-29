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
        config =
            model.config

        newConfig =
            case tableType of
                Model.Table.Torrents ->
                    Model.Config.setTorrentTable
                        (Model.Table.setLayout layout config.torrentTable)
                        config

                Model.Table.Files ->
                    Model.Config.setFileTable
                        (Model.Table.setLayout layout config.fileTable)
                        config

                Model.Table.Peers ->
                    Model.Config.setPeerTable
                        (Model.Table.setLayout layout config.peerTable)
                        config
    in
    model |> setConfig newConfig



-- ENABLE CONTEXT MENUS


setEnableContextMenus : Bool -> Model -> Model
setEnableContextMenus enabled model =
    let
        newConfig =
            model.config |> Model.Config.setEnableContextMenus enabled
    in
    model |> setConfig newConfig
