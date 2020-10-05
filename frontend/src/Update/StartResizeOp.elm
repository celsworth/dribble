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

        tableColumn =
            Model.Table.getColumn tableConfig attribute

        resizeOp =
            { attribute = attribute
            , startWidth = tableColumn.width
            , startPosition = mousePos
            , currentWidth = tableColumn.width
            , currentPosition = mousePos
            }
    in
    model
        |> Model.setResizeOp (Just resizeOp)
        |> Model.addCmd Cmd.none
