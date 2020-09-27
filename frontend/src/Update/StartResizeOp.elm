module Update.StartResizeOp exposing (update)

import Model exposing (..)
import Model.Table


update : Model.Table.Attribute -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update attribute mousePos model =
    let
        resizeOp =
            { attribute = attribute
            , startPosition = mousePos
            , currentPosition = mousePos
            }
    in
    model
        |> Model.setTorrentAttributeResizeOp (Just resizeOp)
        |> Model.addCmd Cmd.none
