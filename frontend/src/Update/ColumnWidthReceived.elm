module Update.ColumnWidthReceived exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Attribute
import Model.Table
import Update.Shared.ConfigHelpers exposing (getTableConfig, tableConfigSetter)



{- This fires when we get the results of setting a table column's
   width to auto.

   We get back the Element with its new width, which we
   store while setting auto = False again
-}


update : Model.Attribute.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model -> ( Model, Cmd Msg )
update attribute result model =
    let
        tableType =
            Model.Table.typeFromAttribute attribute

        tableConfig =
            getTableConfig model.config tableType

        tableColumn =
            Model.Table.getColumn tableConfig attribute

        newTableConfig =
            \px ->
                tableConfig
                    |> Model.Table.setColumn
                        { tableColumn
                            | width = px
                            , auto = False
                        }

        newConfig =
            \px -> model.config |> tableConfigSetter tableType (newTableConfig px)
    in
    case result of
        Ok r ->
            model
                |> setConfig (newConfig r.element.width)
                |> noCmd

        Err _ ->
            -- XXX: could display error message
            model
                |> noCmd
