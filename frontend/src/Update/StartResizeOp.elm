module Update.StartResizeOp exposing (update)

import Model exposing (..)
import Model.Table


update : Model.Table.Attribute -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update attribute mousePos model =
    let
        -- XXX don't assume torrentTable
        startWidth =
            Model.Table.getColumnWidth
                model.config.torrentTable.columnWidths
                attribute

        resizeOp =
            { attribute = attribute
            , startWidth = startWidth
            , startPosition = mousePos
            , currentWidth = startWidth
            , currentPosition = mousePos
            }
    in
    model
        |> Model.setResizeOp (Just resizeOp)
        |> Model.addCmd Cmd.none
