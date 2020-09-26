module Update.MouseHandlers exposing (..)

import Browser.Dom
import Html.Events.Extra.Mouse as Mouse
import Model exposing (..)
import Model.Shared
import Model.Utils.TorrentAttribute
import Task



{- maybe these are TorrentResizeHandlers really? the mouse is irrelevant -}


processTorrentAttributeResizeStarted : Model -> TorrentAttribute -> MousePosition -> Mouse.Button -> Mouse.Keys -> ( Model, Cmd Msg )
processTorrentAttributeResizeStarted model attribute pos button keys =
    case button of
        Mouse.MainButton ->
            processMouseDownMainButton model attribute pos keys

        _ ->
            ( model, Cmd.none )


processMouseDownMainButton : Model -> TorrentAttribute -> MousePosition -> Mouse.Keys -> ( Model, Cmd Msg )
processMouseDownMainButton model attribute pos keys =
    let
        id =
            Model.Utils.TorrentAttribute.attributeToTableHeaderId attribute

        resizeOp =
            { attribute = attribute, startPosition = pos, currentPosition = pos }

        {- move to a context menu -}
        cmd =
            Task.attempt (GotColumnWidth attribute) <| Browser.Dom.getElement id
    in
    if keys.alt then
        {- move to a context menu -}
        ( Model.Shared.setColumnWidthAuto model attribute, cmd )

    else
        ( { model | torrentAttributeResizeOp = Just resizeOp }
        , Cmd.none
        )


processTorrentAttributeResized : Model -> TorrentAttributeResizeOp -> MousePosition -> ( Model, Cmd Msg )
processTorrentAttributeResized model resizeOp pos =
    {- when dragging, if releasing the mouse button now would result in
       a column width below minimumColumnPx, ignore the new mousePosition
    -}
    let
        newResizeOp =
            { resizeOp | currentPosition = pos }

        newWidth =
            Model.Shared.calculateNewColumnWidth model newResizeOp

        -- stop the dragbar moving any further if the column would be too narrow
        valid =
            newWidth.px > Model.Shared.minimumColumnPx
    in
    {- sometimes we get another TorrentAttributeResized just after
       TorrentAttributeResizeEnded.
       Ignore them (model.torrentAttributeResizeOp will be Nothing)
    -}
    if model.torrentAttributeResizeOp /= Nothing && valid then
        ( { model | torrentAttributeResizeOp = Just newResizeOp }, Cmd.none )

    else
        ( model, Cmd.none )


processTorrentAttributeResizeEnded : Model -> TorrentAttributeResizeOp -> MousePosition -> ( Model, Cmd Msg )
processTorrentAttributeResizeEnded model resizeOp pos =
    {- on mouseup, we get a final MousePosition reading. If this is valid,
       using similar logic to processMouseMove, we save it and use it.

       If it's not valid, use the existing resizeOp without changing it.
    -}
    let
        newResizeOp =
            { resizeOp | currentPosition = pos }

        newWidth =
            Model.Shared.calculateNewColumnWidth model newResizeOp

        -- don't use newResizeOp if the column would be too narrow
        valid =
            newWidth.px > Model.Shared.minimumColumnPx

        validResizeOp =
            if valid then
                newResizeOp

            else
                resizeOp

        newModel =
            Model.Shared.setColumnWidth model validResizeOp.attribute newWidth
    in
    ( { newModel | torrentAttributeResizeOp = Nothing }, Cmd.none )
