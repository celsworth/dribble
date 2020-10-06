module Update.SetPreference exposing (update)

import Model exposing (..)
import Model.Preferences as MP
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


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
        tableConfig =
            getTableConfig model.config tableType

        newTableConfig =
            tableConfig |> Model.Table.setLayout layout

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    model |> setConfig newConfig
