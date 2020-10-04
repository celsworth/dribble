module Update.SetColumnAutoWidth exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Table
import Task
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)
import View.Torrent


update : Model.Table.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        ( id, tableType ) =
            case attribute of
                Model.Table.TorrentAttribute a ->
                    ( View.Torrent.attributeToTableHeaderId a, Model.Table.Torrents )

        newTableConfig =
            getTableConfig model.config tableType
                |> Model.Table.setColumnWidthAuto attribute

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    ( model |> Model.setConfig newConfig
    , Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement id
    )
