module Update.ColumnWidthReceived exposing (update)

import Browser.Dom
import Model exposing (..)
import Model.Attribute
import Model.Config exposing (Config)
import Model.File
import Model.FileTable
import Model.Table
import Model.Torrent
import Model.TorrentTable



{- This fires when we get the results of setting a table column's
   width to auto.

   We get back the Element with its new width, which we
   store while setting auto = False again
-}


update : Model.Attribute.Attribute -> Result Browser.Dom.Error Browser.Dom.Element -> Model -> ( Model, Cmd Msg )
update attribute result model =
    case result of
        Ok r ->
            processWidth r.element.width model attribute
                |> noCmd

        Err _ ->
            -- XXX: could display error message
            model
                |> noCmd


processWidth : Float -> Model -> Model.Attribute.Attribute -> Model
processWidth width model attribute =
    case attribute of
        Model.Attribute.TorrentAttribute a ->
            model |> setConfig (torrentTable width model a)

        Model.Attribute.FileAttribute a ->
            model |> setConfig (fileTable width model a)

        _ ->
            Debug.todo "todo"


torrentTable : Float -> Model -> Model.Torrent.Attribute -> Config
torrentTable px model attribute =
    let
        tableConfig =
            model.config.torrentTable

        tableColumn =
            Model.TorrentTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | width = px, auto = False }
    in
    model.config |> Model.Config.setTorrentTable newTableConfig


fileTable : Float -> Model -> Model.File.Attribute -> Config
fileTable px model attribute =
    let
        tableConfig =
            model.config.fileTable

        tableColumn =
            Model.FileTable.getColumn tableConfig attribute

        newTableConfig =
            tableConfig |> Model.Table.setColumn { tableColumn | width = px, auto = False }
    in
    model.config |> Model.Config.setFileTable newTableConfig
