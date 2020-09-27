module Update.SetColumnAutoWidth exposing (..)

import Browser.Dom
import Model exposing (..)
import Model.Config
import Model.Table
import Task
import View.Torrent


update : Model.Table.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        attr =
            case attribute of
                Model.Table.TorrentAttribute a ->
                    a

        id =
            View.Torrent.attributeToTableHeaderId attr

        cmd =
            Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement id
    in
    ( Model.setConfig
        (Model.Config.setTorrentTable
            (Model.Table.setColumnWidthAuto attribute model.config.torrentTable)
            model.config
        )
        model
    , cmd
    )
