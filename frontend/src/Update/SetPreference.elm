module Update.SetPreference exposing (update)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Preferences as MP
import Model.Table


update : MP.PreferenceUpdate -> Model -> ( Model, Cmd Msg )
update preferenceUpdate model =
    case preferenceUpdate of
        MP.Table tableType MP.Layout layout ->
            model
                |> setTableLayout tableType layout
                |> noCmd


setTableLayout : Model.Table.Type -> Model.Table.Layout -> Model -> Model
setTableLayout tableType layout model =
    let
        newConfig =
            case tableType of
                Model.Table.Torrents ->
                    torrentTableLayout model layout

                _ ->
                    Debug.todo "todo other table layouts"
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
