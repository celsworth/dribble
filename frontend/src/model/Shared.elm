module Model.Shared exposing (..)

import Dict
import Model exposing (..)
import Model.Utils.TorrentAttribute


minimumColumnPx : Float
minimumColumnPx =
    30


getColumnWidth : ColumnWidths -> TorrentAttribute -> ColumnWidth
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


calculateNewColumnWidth : Model -> TorrentAttributeResizeOp -> ColumnWidth
calculateNewColumnWidth model resizeOp =
    let
        oldWidth =
            getColumnWidth model.config.columnWidths resizeOp.attribute

        newPx =
            oldWidth.px + resizeOp.currentPosition.x - resizeOp.startPosition.x
    in
    -- prevent columns going below 20px
    case List.maximum [ minimumColumnPx, newPx ] of
        Just max ->
            { oldWidth | px = max }

        Nothing ->
            -- notreachable, minimumColumnPx is never unset
            { px = minimumColumnPx, auto = False }
