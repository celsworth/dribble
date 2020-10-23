module Update.ToggleAttributeVisibility exposing (update)

import Model exposing (..)
import Model.Attribute
import Model.Config
import Model.Table
import Model.Torrent
import Model.TorrentTable


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    case attribute of
        Model.Attribute.TorrentAttribute a ->
            torrentTable a model

        _ ->
            Debug.todo "ToggleAttributeVisibility todo"


torrentTable : Model.Torrent.Attribute -> Model -> ( Model, Cmd Msg )
torrentTable attribute model =
    let
        tableConfig =
            model.config.torrentTable

        tableColumn =
            Model.TorrentTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig
                |> Model.Table.setColumn
                    { tableColumn | visible = not tableColumn.visible }

        newConfig =
            model.config |> Model.Config.setTorrentTable newTableConfig
    in
    model
        |> setConfig newConfig
        |> noCmd
