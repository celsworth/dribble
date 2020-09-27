module Update.ColumnWidthReceived exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Config
import Model.Table



{- This fires when we get the results of setting a table column's
   width to auto.

   We get back the Element with its new width, which we
   store while setting auto = False again
-}


update : Model.Table.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model -> ( Model, Cmd Msg )
update attribute result model =
    let
        newTorrentTable =
            \r ->
                -- TODO: remove torrentTable assumption
                Model.Table.setColumnWidth
                    attribute
                    { px = r.element.width, auto = False }
                    model.config.torrentTable

        newConfig =
            \r -> Model.Config.setTorrentTable (newTorrentTable r) model.config
    in
    case result of
        Ok r ->
            model
                |> Model.setConfig (newConfig r)
                |> Model.addCmd Cmd.none

        Err _ ->
            -- XXX: could display error message
            model |> Model.addCmd Cmd.none
