module Model.Table exposing (..)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Model.Torrent


type Attribute
    = TorrentAttribute Model.Torrent.Attribute


type alias MousePosition =
    { x : Float
    , y : Float
    }


type alias ResizeOp =
    { attribute : Attribute
    , startWidth : ColumnWidth
    , startPosition : MousePosition
    , currentWidth : ColumnWidth
    , currentPosition : MousePosition
    }


type Layout
    = Fixed
    | Fluid


type alias ColumnWidths =
    Dict String ColumnWidth


type alias ColumnWidth =
    { px : Float
    , auto : Bool
    }


type alias Config =
    { layout : Layout
    , columnWidths : ColumnWidths
    }


type Type
    = Torrents



-- SETTERS


setLayout : Layout -> Config -> Config
setLayout new config =
    { config | layout = new }


setColumnWidths : ColumnWidths -> Config -> Config
setColumnWidths new config =
    { config | columnWidths = new }



-- DEFAULTS


defaultConfig : Config
defaultConfig =
    { layout = Fixed
    , columnWidths = defaultColumnWidths
    }


defaultColumnWidths : ColumnWidths
defaultColumnWidths =
    Dict.fromList <|
        List.map defaultColumnWidth Model.Torrent.defaultAttributes


defaultColumnWidth : Model.Torrent.Attribute -> ( String, ColumnWidth )
defaultColumnWidth attribute =
    -- and cope with other table types
    ( Model.Torrent.attributeToKey
        attribute
    , { px = Model.Torrent.attributeToDefaultWidth attribute, auto = False }
    )



-- HELPERS


typeFromAttribute : Attribute -> Type
typeFromAttribute attribute =
    case attribute of
        TorrentAttribute _ ->
            Torrents



-- COLUMN WIDTHS / RESIZING


minimumColumnPx : Float
minimumColumnPx =
    30


getColumnWidth : ColumnWidths -> Attribute -> ColumnWidth
getColumnWidth columnWidths attribute =
    let
        key =
            case attribute of
                TorrentAttribute a ->
                    Model.Torrent.attributeToKey a
    in
    case Dict.get key columnWidths of
        Just width ->
            width

        Nothing ->
            -- default
            { px = minimumColumnPx, auto = False }


setColumnWidth : Attribute -> ColumnWidth -> Config -> Config
setColumnWidth attribute newWidth config =
    let
        key =
            case attribute of
                TorrentAttribute a ->
                    Model.Torrent.attributeToKey a

        newDict =
            Dict.insert key newWidth config.columnWidths
    in
    config |> setColumnWidths newDict


setColumnWidthAuto : Attribute -> Config -> Config
setColumnWidthAuto attribute config =
    let
        key =
            case attribute of
                TorrentAttribute a ->
                    Model.Torrent.attributeToKey a

        oldWidth =
            getColumnWidth config.columnWidths attribute

        newWidth =
            { oldWidth | auto = True }

        newDict =
            Dict.insert key newWidth config.columnWidths
    in
    config |> setColumnWidths newDict


calculateNewColumnWidth : ResizeOp -> ColumnWidth
calculateNewColumnWidth { startWidth, currentPosition, startPosition } =
    let
        newPx =
            startWidth.px + currentPosition.x - startPosition.x
    in
    -- prevent columns going below 20px
    case List.maximum [ minimumColumnPx, newPx ] of
        Just max ->
            { startWidth | px = max }

        Nothing ->
            -- notreachable, minimumColumnPx is never unset
            { px = minimumColumnPx, auto = False }


updateResizeOpIfValid : ResizeOp -> MousePosition -> Maybe ResizeOp
updateResizeOpIfValid resizeOp mousePosition =
    let
        newResizeOp =
            { resizeOp | currentPosition = mousePosition }

        newWidth =
            calculateNewColumnWidth newResizeOp

        -- stop the dragbar moving any further if the column would be too narrow
        valid =
            newWidth.px > minimumColumnPx
    in
    if valid then
        Just { newResizeOp | currentWidth = newWidth }

    else
        Nothing



-- JSON ENCODING


encode : Config -> E.Value
encode config =
    E.object
        [ ( "layout", encodeLayout config.layout )
        , ( "columnWidths", encodeColumnWidths config.columnWidths )
        ]


encodeLayout : Layout -> E.Value
encodeLayout val =
    case val of
        Fixed ->
            E.string "fixed"

        Fluid ->
            E.string "fluid"


encodeColumnWidths : ColumnWidths -> E.Value
encodeColumnWidths columnWidths =
    Dict.toList columnWidths
        |> List.map (\( k, v ) -> ( k, encodeColumnWidth v ))
        |> E.object


encodeColumnWidth : ColumnWidth -> E.Value
encodeColumnWidth columnWidth =
    E.object
        [ ( "px", E.float columnWidth.px )
        , ( "auto", E.bool columnWidth.auto )
        ]



-- JSON DECODING


decoder : D.Decoder Config
decoder =
    D.succeed Config
        |> optional "layout" layoutDecoder defaultConfig.layout
        |> optional "columnWidths" columnWidthsDecoder defaultConfig.columnWidths


layoutDecoder : D.Decoder Layout
layoutDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "fixed" ->
                        D.succeed Fixed

                    "fluid" ->
                        D.succeed Fluid

                    _ ->
                        D.fail <| "unknown table.layout" ++ input
            )


columnWidthsDecoder : D.Decoder ColumnWidths
columnWidthsDecoder =
    D.dict columnWidthDecoder


columnWidthDecoder : D.Decoder ColumnWidth
columnWidthDecoder =
    D.succeed ColumnWidth
        |> required "px" D.float
        |> required "auto" D.bool
