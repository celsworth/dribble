module Update.SetColumnAutoWidth exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Attribute exposing (Attribute(..))
import Model.Table
import Model.Torrent
import Task
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


update : Model.Attribute.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        ( id, tableType ) =
            case attribute of
                Model.Attribute.TorrentAttribute a ->
                    ( Model.Torrent.attributeToTableHeaderId a
                    , Model.Table.Torrents
                    )

        tableConfig =
            getTableConfig model.config tableType

        tableColumn =
            Model.Table.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | auto = True }

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    ( model |> setConfig newConfig
    , Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement id
    )
