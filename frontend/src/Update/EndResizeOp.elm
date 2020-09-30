module Update.EndResizeOp exposing (update)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table


type alias Action =
    {- to store details of how to end a resizeOp for different attribute types -}
    { setter : Model.Table.Config -> Config -> Config
    , tableConfig : Model.Table.Config
    }


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        {- use the updated mouse coords if valid, otherwise use
           the most recently stored valid resizeOp (passed in)
        -}
        newResizeOp =
            Model.Table.updateResizeOpIfValid resizeOp mousePosition
                |> Maybe.withDefault resizeOp
    in
    model
        |> Model.setResizeOp Nothing
        |> Model.setConfig (newConfig newResizeOp model)
        |> Model.addCmd Cmd.none


newConfig : Model.Table.ResizeOp -> Model -> Config
newConfig resizeOp model =
    let
        action =
            actionForAttribute resizeOp.attribute model

        newTableConfig =
            action.tableConfig
                |> Model.Table.setColumnWidth resizeOp.attribute resizeOp.currentWidth
    in
    model.config |> action.setter newTableConfig


actionForAttribute : Model.Table.Attribute -> Model -> Action
actionForAttribute attribute model =
    case attribute of
        Model.Table.TorrentAttribute _ ->
            { setter = Model.Config.setTorrentTable
            , tableConfig = model.config.torrentTable
            }
