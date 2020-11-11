module Update.StartResizeOp exposing (update)

import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.FileTable
import Utils.Mouse as Mouse
import Model.TorrentTable


update : Model.Attribute.Attribute -> Mouse.Position -> Model -> ( Model, Cmd Msg )
update attribute mousePos model =
    let
        width =
            currentWidth model.config attribute

        resizeOp =
            { attribute = attribute
            , startWidth = width
            , startPosition = mousePos
            , currentWidth = width
            , currentPosition = mousePos
            }
    in
    model
        |> setResizeOp (Just resizeOp)
        |> noCmd


currentWidth : Config -> Model.Attribute.Attribute -> Float
currentWidth config attribute =
    case attribute of
        Model.Attribute.TorrentAttribute a ->
            (Model.TorrentTable.getColumn config.torrentTable a).width

        Model.Attribute.FileAttribute a ->
            (Model.FileTable.getColumn config.fileTable a).width

        _ ->
            Debug.todo "todo"
