module Update.ToggleTorrentAttributeVisibility exposing (update)

import Model exposing (..)
import Model.Attribute
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        -- TODO support for other tables
        tableType =
            Model.Table.Torrents

        tableConfig =
            getTableConfig model.config tableType

        tableColumn =
            Model.Table.getColumn tableConfig attribute

        newTableConfig =
            tableConfig
                |> Model.Table.setColumn
                    { tableColumn | visible = not tableColumn.visible }

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    model
        |> setConfig newConfig
        |> noCmd
