module Model.Shared exposing (..)

import Dict
import Model exposing (..)
import Model.Utils.TorrentAttribute


minimumColumnPx : Float
minimumColumnPx =
    50


getColumnWidth columnWidths attribute =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute
    in
    case Dict.get key columnWidths of
        Just width ->
            width

        Nothing ->
            -- default
            { px = minimumColumnPx, auto = False }


setColumnWidth : Model -> TorrentAttribute -> ColumnWidth -> Model
setColumnWidth model attribute newWidth =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute

        newDict =
            Dict.insert key newWidth model.config.columnWidths

        config =
            model.config

        newConfig =
            { config | columnWidths = newDict }
    in
    { model | config = newConfig }


setColumnWidthAuto : Model -> TorrentAttribute -> Model
setColumnWidthAuto model attribute =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute

        oldWidth =
            getColumnWidth model.config.columnWidths attribute

        newWidth =
            { oldWidth | auto = True }

        newDict =
            Dict.insert key newWidth model.config.columnWidths

        config =
            model.config

        newConfig =
            { config | columnWidths = newDict }
    in
    { model | config = newConfig }


calculateNewColumnWidth : Model -> TorrentAttribute -> Float -> MousePosition -> ColumnWidth
calculateNewColumnWidth model attribute mouseStartX pos =
    let
        ( x, y ) =
            pos

        oldWidth =
            getColumnWidth model.config.columnWidths attribute

        newPx =
            oldWidth.px + x - mouseStartX
    in
    -- prevent columns going below 50px
    case List.maximum [ minimumColumnPx, newPx ] of
        Just max ->
            { oldWidth | px = max }

        Nothing ->
            -- notreachable, minimumColumnPx is never unset
            { px = minimumColumnPx, auto = False }
