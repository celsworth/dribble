module Update.SetColumnAutoWidth exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table
import Task
import View.Torrent


type alias Action =
    {- store details of how to set auto for different attribute types -}
    { id : String
    , setter : Model.Table.Config -> Config -> Config
    , tableConfig : Model.Table.Config
    }


update : Model.Table.Attribute -> Model -> ( Model, Cmd Msg )
update attribute model =
    let
        action =
            actionForAttribute attribute model

        newTableConfig =
            action.tableConfig |> Model.Table.setColumnWidthAuto attribute

        newConfig =
            model.config |> action.setter newTableConfig

        newModel =
            model |> Model.setConfig newConfig

        cmd =
            Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement action.id
    in
    ( newModel, cmd )


actionForAttribute : Model.Table.Attribute -> Model -> Action
actionForAttribute attribute model =
    case attribute of
        Model.Table.TorrentAttribute a ->
            { id = View.Torrent.attributeToTableHeaderId a
            , setter = Model.Config.setTorrentTable
            , tableConfig = model.config.torrentTable
            }
