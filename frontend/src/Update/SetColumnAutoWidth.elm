module Update.SetColumnAutoWidth exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.File
import Model.FileTable
import Model.Peer
import Model.Table
import Model.Torrent
import Model.TorrentTable
import Task


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        ( id, newConfig ) =
            case attribute of
                Model.Attribute.TorrentAttribute a ->
                    ( Model.Torrent.attributeToTableHeaderId a
                    , torrentTable model a
                    )

                Model.Attribute.FileAttribute a ->
                    ( Model.File.attributeToTableHeaderId a
                    , fileTable model a
                    )

                _ ->
                    Debug.todo "todo"
    in
    model
        |> setConfig newConfig
        |> addCmd
            (Task.attempt
                (GotColumnWidth attribute)
                (Browser.Dom.getElement id)
            )


torrentTable : Model -> Model.Torrent.Attribute -> Config
torrentTable model attribute =
    let
        tableConfig =
            model.config.torrentTable

        tableColumn =
            Model.TorrentTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | auto = True }
    in
    model.config |> Model.Config.setTorrentTable newTableConfig


fileTable : Model -> Model.File.Attribute -> Config
fileTable model attribute =
    let
        tableConfig =
            model.config.fileTable

        tableColumn =
            Model.FileTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | auto = True }
    in
    model.config |> Model.Config.setFileTable newTableConfig
