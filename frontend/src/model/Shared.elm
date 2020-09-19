module Model.Shared exposing (..)

import Dict
import Model exposing (..)
import Model.Utils.TorrentAttribute


minimumColumnWidth : Float
minimumColumnWidth =
    50


getColumnWidth : ColumnWidths -> TorrentAttribute -> Float
getColumnWidth columnWidths attribute =
    let
        key =
            Model.Utils.TorrentAttribute.attributeToKey attribute
    in
    case Dict.get key columnWidths of
        Just width ->
            width

        Nothing ->
            minimumColumnWidth


setColumnWidth : Model -> TorrentAttribute -> Float -> Model
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


calculateNewColumnWidth : Model -> MousePosition -> Float
calculateNewColumnWidth model pos =
    let
        ( x, y ) =
            pos

        ( attribute, mouseStartX ) =
            case model.dragging of
                Just dragging ->
                    dragging

                -- XXX this should never happen
                Nothing ->
                    ( Name, minimumColumnWidth )

        oldWidth =
            getColumnWidth model.config.columnWidths attribute

        newWidth =
            oldWidth + x - mouseStartX
    in
    -- prevent columns going below 20px
    case List.maximum [ minimumColumnWidth, newWidth ] of
        Just max ->
            max

        Nothing ->
            minimumColumnWidth
