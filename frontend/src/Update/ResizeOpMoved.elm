module Update.ResizeOpMoved exposing (update)

import Model exposing (..)
import Model.Table


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        {- sometimes we get another TorrentAttributeResized just after
           TorrentAttributeResizeEnded.
           Ignore them (model.torrentAttributeResizeOp will be Nothing)
        -}
        resizing =
            model.resizeOp /= Nothing

        maybeResizeOp =
            Model.Table.updateResizeOpIfValid resizeOp mousePosition
    in
    case ( resizing, maybeResizeOp ) of
        ( True, Just newResizeOp ) ->
            model
                |> Model.setResizeOp (Just newResizeOp)
                |> Model.addCmd Cmd.none

        ( _, _ ) ->
            model |> Model.addCmd Cmd.none
