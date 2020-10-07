module Model.Table exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (hardcoded, required)
import Json.Encode as E
import List.Extra
import Model.Torrent


type Attribute
    = TorrentAttribute Model.Torrent.Attribute


type alias MousePosition =
    { x : Float
    , y : Float
    }


type alias ResizeOp =
    { attribute : Attribute
    , startWidth : Float
    , startPosition : MousePosition
    , currentWidth : Float
    , currentPosition : MousePosition
    }


type Type
    = Torrents


type Layout
    = Fixed
    | Fluid


type alias Column =
    { attribute : Attribute
    , width : Float
    , auto : Bool
    , visible : Bool
    }


type alias Config =
    -- can we split into config that affects individual row content,
    -- and config that affects row order?
    { tableType : Type
    , layout : Layout
    , columns : List Column

    -- sortBy?
    -- filter?
    }



-- SETTERS


setLayout : Layout -> Config -> Config
setLayout new config =
    { config | layout = new }


setColumns : List Column -> Config -> Config
setColumns new config =
    if config.columns /= new then
        { config | columns = new }

    else
        config



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


defaultColumn : Attribute -> Column
defaultColumn attribute =
    { attribute = attribute
    , width = minimumColumnPx
    , auto = False
    , visible = True
    }


getColumn : Config -> Attribute -> Column
getColumn tableConfig attribute =
    List.Extra.find (\c -> c.attribute == attribute) tableConfig.columns
        |> Maybe.withDefault (defaultColumn attribute)


setColumn : Column -> Config -> Config
setColumn column tableConfig =
    {- TODO: this should really cope if the column isn't in the List,
       by adding it to the end?
    -}
    let
        columns =
            tableConfig.columns

        newColumns =
            List.Extra.setIf (\c -> c.attribute == column.attribute) column columns
    in
    { tableConfig | columns = newColumns }


calculateNewColumnWidth : ResizeOp -> Float
calculateNewColumnWidth { startWidth, currentPosition, startPosition } =
    let
        newPx =
            startWidth + currentPosition.x - startPosition.x
    in
    -- prevent columns going below 20px
    case List.maximum [ minimumColumnPx, newPx ] of
        Just max ->
            max

        Nothing ->
            -- notreachable, minimumColumnPx is never unset
            minimumColumnPx


updateResizeOpIfValid : ResizeOp -> MousePosition -> Maybe ResizeOp
updateResizeOpIfValid resizeOp mousePosition =
    let
        newResizeOp =
            { resizeOp | currentPosition = mousePosition }

        newWidth =
            calculateNewColumnWidth newResizeOp

        -- stop the dragbar moving any further if the column would be too narrow
        valid =
            newWidth > minimumColumnPx
    in
    if valid then
        Just { newResizeOp | currentWidth = newWidth }

    else
        Nothing



-- JSON ENCODING


encode : Config -> E.Value
encode config =
    E.object
        [ ( "tableType", encodeTableType config.tableType )
        , ( "layout", encodeLayout config.layout )
        , ( "columns", encodeColumns config.columns )
        ]


encodeTableType : Type -> E.Value
encodeTableType val =
    case val of
        Torrents ->
            E.string "torrents"


encodeLayout : Layout -> E.Value
encodeLayout val =
    case val of
        Fixed ->
            E.string "fixed"

        Fluid ->
            E.string "fluid"


encodeColumns : List Column -> E.Value
encodeColumns columns =
    E.list encodeColumn columns


encodeColumn : Column -> E.Value
encodeColumn column =
    E.object
        [ ( "attribute", encodeAttribute column.attribute )
        , ( "width", E.float column.width )
        , ( "auto", E.bool column.auto )
        , ( "visible", E.bool column.visible )
        ]


encodeAttribute : Attribute -> E.Value
encodeAttribute attribute =
    case attribute of
        TorrentAttribute a ->
            E.string <| Model.Torrent.attributeToKey a



-- JSON DECODING


decoder : D.Decoder Config
decoder =
    D.field "tableType" tableTypeDecoder |> D.andThen decoder2


decoder2 : Type -> D.Decoder Config
decoder2 tableType =
    D.succeed Config
        |> hardcoded tableType
        |> required "layout" layoutDecoder
        |> required "columns" (columnsDecoder tableType)


tableTypeDecoder : D.Decoder Type
tableTypeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "torrents" ->
                        D.succeed Torrents

                    _ ->
                        D.fail <| "unknown tableType" ++ input
            )


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


columnsDecoder : Type -> D.Decoder (List Column)
columnsDecoder tableType =
    D.list (columnDecoder tableType)


columnDecoder : Type -> D.Decoder Column
columnDecoder tableType =
    D.succeed Column
        |> required "attribute" (attributeDecoder tableType)
        |> required "width" D.float
        |> required "auto" D.bool
        |> required "visible" D.bool


attributeDecoder : Type -> D.Decoder Attribute
attributeDecoder tableType =
    D.string
        |> D.andThen
            (\input ->
                case tableType of
                    Torrents ->
                        case Model.Torrent.keyToAttribute input of
                            Just a ->
                                D.succeed <| TorrentAttribute a

                            Nothing ->
                                D.fail <| "unknown torrent key " ++ input
            )
