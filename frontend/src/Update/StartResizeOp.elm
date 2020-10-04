module Update.StartResizeOp exposing (update)

import Model exposing (..)
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig)


update : Model.Table.Attribute -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update attribute mousePos model =
    let
        tableType =
            Model.Table.typeFromAttribute attribute

        tableConfig =
            getTableConfig model.config tableType

        startWidth =
            Model.Table.getColumnWidth tableConfig.columnWidths attribute

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
