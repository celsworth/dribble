module Update.ColumnWidthReceived exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Config exposing (Config)
import Model.Table



{- This fires when we get the results of setting a table column's
   width to auto.

   We get back the Element with its new width, which we
   store while setting auto = False again
-}


type alias Action =
    {- store details of how to set width for different attribute types -}
    { setter : Model.Table.Config -> Config -> Config
    , tableConfig : Model.Table.Config
    }


update : Model.Table.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model -> ( Model, Cmd Msg )
update attribute result model =
    let
        action =
            actionForAttribute attribute model

        newTableConfig =
            \px ->
                Model.Table.setColumnWidth
                    attribute
                    { px = px, auto = False }
                    action.tableConfig

        newConfig =
            \px -> action.setter (newTableConfig px) model.config
    in
    case result of
        Ok r ->
            model
                |> Model.setConfig (newConfig r.element.width)
                |> Model.addCmd Cmd.none

        Err _ ->
            -- XXX: could display error message
            model |> Model.addCmd Cmd.none


actionForAttribute : Model.Table.Attribute -> Model -> Action
actionForAttribute attribute model =
    case attribute of
        Model.Table.TorrentAttribute _ ->
            { setter = Model.Config.setTorrentTable
            , tableConfig = model.config.torrentTable
            }
