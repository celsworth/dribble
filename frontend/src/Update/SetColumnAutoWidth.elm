module Update.SetColumnAutoWidth exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Attribute
import Model.File
import Model.Peer
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

                Model.Attribute.FileAttribute a ->
                    ( Model.File.attributeToTableHeaderId a
                    , Model.Table.Files
                    )

                Model.Attribute.PeerAttribute a ->
                    ( Model.Peer.attributeToTableHeaderId a
                    , Model.Table.Peers
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
    model
        |> setConfig newConfig
        |> addCmd
            (Task.attempt
                (GotColumnWidth attribute)
                (Browser.Dom.getElement id)
            )
