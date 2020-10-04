module Update.EndResizeOp exposing (update)

import Model exposing (..)
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


update : Model.Table.ResizeOp -> Model.Table.MousePosition -> Model -> ( Model, Cmd Msg )
update resizeOp mousePosition model =
    let
        {- use the updated mouse coords if valid, otherwise use
           the most recently stored valid resizeOp (passed in)
        -}
        newResizeOp =
            Model.Table.updateResizeOpIfValid resizeOp mousePosition
                |> Maybe.withDefault resizeOp

        tableType =
            Model.Table.typeFromAttribute resizeOp.attribute

        newTableConfig =
            getTableConfig model.config tableType
                |> Model.Table.setColumnWidth
                    newResizeOp.attribute
                    newResizeOp.currentWidth

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    model
        |> Model.setResizeOp Nothing
        |> Model.setConfig newConfig
        |> Model.addCmd Cmd.none
