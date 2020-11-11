module Update.ResizeOpMoved exposing (update)

import Model exposing (..)
import Utils.Mouse as Mouse
import Model.Table


update : Model.Table.ResizeOp -> Mouse.Position -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        {- sometimes we get another AttributeResized just after AttributeResizeEnded.
           Ignore them (model.resizeOp will be Nothing)
        -}
        resizing =
            model.resizeOp /= Nothing

        maybeResizeOp =
            Model.Table.updateResizeOpIfValid resizeOp mousePosition
    in
    case ( resizing, maybeResizeOp ) of
        ( True, Just newResizeOp ) ->
            model
                |> setResizeOp (Just newResizeOp)
                |> noCmd

        ( _, _ ) ->
            model |> noCmd
