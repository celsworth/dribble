module Update.ColumnWidthReceived exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)



{- This fires when we get the results of setting a table column's
   width to auto.

   We get back the Element with its new width, which we
   store while setting auto = False again
-}


update : Model.Table.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model -> ( Model, Cmd Msg )
update attribute result model =
    let
        tableType =
            Model.Table.typeFromAttribute attribute

        newTableConfig =
            \px ->
                Model.Table.setColumnWidth
                    attribute
                    { px = px, auto = False }
                    (getTableConfig model.config tableType)

        newConfig =
            \px -> tableConfigSetter tableType (newTableConfig px) model.config
    in
    case result of
        Ok r ->
            model
                |> setConfig (newConfig r.element.width)
                |> addCmd Cmd.none

        Err _ ->
            -- XXX: could display error message
            model |> addCmd Cmd.none
