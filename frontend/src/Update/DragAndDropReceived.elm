module Update.DragAndDropReceived exposing (update)

import DnDList
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)


update : Model.Table.Type -> DnDList.Msg -> Model -> ( Model, Cmd Msg )
update tableType dndmsg model =
    let
        tableDndSystem =
            dndSystem tableType

        tableConfig =
            getTableConfig model.config tableType

        ( dnd, items ) =
            tableDndSystem.update dndmsg model.dnd tableConfig.columns

        newTableConfig =
            tableConfig |> Model.Table.setColumns items

        newConfig =
            model.config |> tableConfigSetter tableType newTableConfig
    in
    ( { model | dnd = dnd, config = newConfig }
    , tableDndSystem.commands dnd
    )
