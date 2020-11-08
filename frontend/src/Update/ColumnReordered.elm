module Update.ColumnReordered exposing (update)

import DnDList
import Model exposing (..)
import Model.Config
import Model.FileTable
import Model.Table
import Model.TorrentTable


update : Model.Table.Type -> DnDList.Msg -> Model -> ( Model, Cmd Msg )
update tableType dndmsg model =
    case tableType of
        Model.Table.Torrents ->
            torrentTable dndmsg model

        Model.Table.Files ->
            fileTable dndmsg model

        _ ->
            Debug.todo "support peer tables"


torrentTable : DnDList.Msg -> Model -> ( Model, Cmd Msg )
torrentTable dndmsg model =
    let
        dndSystem =
            Model.TorrentTable.dndSystem ColumnReordered

        tableConfig =
            model.config.torrentTable

        ( dnd, items ) =
            dndSystem.update dndmsg model.dnd tableConfig.columns

        newTableConfig =
            tableConfig |> Model.Table.setColumns items

        newConfig =
            model.config |> Model.Config.setTorrentTable newTableConfig

        newModel =
            model |> setConfig newConfig |> setDnd dnd
    in
    ( newModel, dndSystem.commands dnd )


fileTable : DnDList.Msg -> Model -> ( Model, Cmd Msg )
fileTable dndmsg model =
    let
        dndSystem =
            Model.FileTable.dndSystem ColumnReordered

        tableConfig =
            model.config.fileTable

        ( dnd, items ) =
            dndSystem.update dndmsg model.dnd tableConfig.columns

        newTableConfig =
            tableConfig |> Model.Table.setColumns items

        newConfig =
            model.config |> Model.Config.setFileTable newTableConfig

        newModel =
            model |> setConfig newConfig |> setDnd dnd
    in
    ( newModel, dndSystem.commands dnd )
