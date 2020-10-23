module Update.EndResizeOp exposing (update)

import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.File
import Model.FileTable
import Model.Table
import Model.Torrent
import Model.TorrentTable


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        {- use the updated mouse coords if valid, otherwise use
           the most recently stored valid resizeOp (passed in)
        -}
        newResizeOp =
            Model.Table.updateResizeOpIfValid resizeOp mousePosition
                |> Maybe.withDefault resizeOp

        newConfig =
            case resizeOp.attribute of
                Model.Attribute.TorrentAttribute attribute ->
                    torrentTable model attribute newResizeOp

                Model.Attribute.FileAttribute attribute ->
                    fileTable model attribute newResizeOp

                _ ->
                    Debug.todo "todo"
    in
    model
        |> setResizeOp Nothing
        |> setConfig newConfig
        |> noCmd


torrentTable : Model -> Model.Torrent.Attribute -> Model.Table.ResizeOp -> Config
torrentTable model attribute newResizeOp =
    let
        tableConfig =
            model.config.torrentTable

        tableColumn =
            Model.TorrentTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | width = newResizeOp.currentWidth }
    in
    model.config |> Model.Config.setTorrentTable newTableConfig


fileTable : Model -> Model.File.Attribute -> Model.Table.ResizeOp -> Config
fileTable model attribute newResizeOp =
    let
        tableConfig =
            model.config.fileTable

        tableColumn =
            Model.FileTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | width = newResizeOp.currentWidth }
    in
    model.config |> Model.Config.setFileTable newTableConfig
