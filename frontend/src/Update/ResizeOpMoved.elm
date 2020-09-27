module Update.ResizeOpMoved exposing (update)

import Model exposing (..)
import Model.Table


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        newResizeOp =
            { resizeOp | currentPosition = mousePosition }

        newWidth =
            -- XXX don't assume torrentTable
            Model.Table.calculateNewColumnWidth
                newResizeOp
                model.config.torrentTable

        -- stop the dragbar moving any further if the column would be too narrow
        valid =
            newWidth.px > Model.Table.minimumColumnPx
    in
    {- sometimes we get another TorrentAttributeResized just after
       TorrentAttributeResizeEnded.
       Ignore them (model.torrentAttributeResizeOp will be Nothing)
    -}
    if model.torrentAttributeResizeOp /= Nothing && valid then
        model
            |> Model.setTorrentAttributeResizeOp (Just newResizeOp)
            |> Model.addCmd Cmd.none

    else
        model |> Model.addCmd Cmd.none
