module Update.EndResizeOp exposing (update)

import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table


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
        |> Model.setConfig (newConfig newResizeOp model.config)
        |> Model.addCmd Cmd.none


newConfig : Model.Table.ResizeOp -> Config -> Config
newConfig resizeOp config =
    -- TODO: remove torrentTable assumption
    config
        |> Model.Config.setTorrentTable
            (Model.Table.setColumnWidth
                resizeOp.attribute
                resizeOp.currentWidth
                config.torrentTable
            )
