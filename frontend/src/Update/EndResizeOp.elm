module Update.EndResizeOp exposing (update)

import Model exposing (..)
import Model.Config
import Model.Table


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        newResizeOp =
            { resizeOp | currentPosition = mousePosition }

        newWidth =
            Model.Table.calculateNewColumnWidth newResizeOp model.config.torrentTable

        -- don't use newResizeOp if the column would be too narrow
        valid =
            newWidth.px > Model.Table.minimumColumnPx

        validResizeOp =
            if valid then
                newResizeOp

            else
                resizeOp

        newConfig =
            model.config
                |> Model.Config.setTorrentTable
                    (Model.Table.setColumnWidth
                        validResizeOp.attribute
                        newWidth
                        model.config.torrentTable
                    )
    in
    model
        |> Model.setTorrentAttributeResizeOp Nothing
        |> Model.setConfig newConfig
        |> Model.addCmd Cmd.none
