module Update.ToggleTorrentAttributeVisibility exposing (update)

import Model exposing (..)
import Model.Table
import Model.Torrent
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


update : Model.Torrent.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        -- TODO support for other tables
        tableType =
            Model.Table.Torrents

        tableConfig =
            getTableConfig model.config tableType

        tableColumn =
            Model.Table.getColumn tableConfig (Model.Table.TorrentAttribute attribute)

        newTableConfig =
            tableConfig
                |> Model.Table.setColumn
                    { tableColumn | visible = not tableColumn.visible }

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    model
        |> setConfig newConfig
        |> addCmd Cmd.none
