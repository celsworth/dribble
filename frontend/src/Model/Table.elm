module Model.Table exposing (..)

import Json.Decode as D
import Json.Encode as E
import List.Extra
import Model.Attribute exposing (Attribute)
import Model.MousePosition exposing (MousePosition)


type alias ResizeOp =
    { attribute : Attribute
    , startWidth : Float
    , startPosition : MousePosition
    , currentWidth : Float
    , currentPosition : MousePosition
    }


type Type
    = Torrents
    | Files
    | Peers


type Layout
    = Fixed
    | Fluid



-- SETTERS


{-| this looks awful, but its basically Column -> Config -> Config
-}
setColumn :
    { a | attribute : b }
    -> { c | columns : List { a | attribute : b } }
    -> { c | columns : List { a | attribute : b } }
setColumn column tableConfig =
    let
        newColumns =
            List.Extra.setIf (\c -> c.attribute == column.attribute)
                column
                tableConfig.columns
    in
    { tableConfig | columns = newColumns }


setLayout : b -> { a | layout : b } -> { a | layout : b }
setLayout new config =
    { config | layout = new }


setSortBy : b -> { a | sortBy : b } -> { a | sortBy : b }
setSortBy new tableConfig =
    { tableConfig | sortBy = new }


setColumns : b -> { a | columns : b } -> { a | columns : b }
setColumns new config =
    -- avoid excessive setting in Update/DragAndDropReceived
    if config.columns /= new then
        { config | columns = new }

    else
        config



-- COLUMN WIDTHS / RESIZING


minimumColumnPx : Float
minimumColumnPx =
    30


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


encodeTableType : Type -> E.Value
encodeTableType val =
    case val of
        Torrents ->
            E.string "torrents"

        Files ->
            E.string "files"

        Peers ->
            E.string "peers"


encodeLayout : Layout -> E.Value
encodeLayout val =
    case val of
        Fixed ->
            E.string "fixed"

        Fluid ->
            E.string "fluid"



-- JSON DECODING


tableTypeDecoder : D.Decoder Type
tableTypeDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "torrents" ->
                        D.succeed Torrents

                    "files" ->
                        D.succeed Files

                    "peers" ->
                        D.succeed Peers

                    _ ->
                        D.fail <| "unknown tableType " ++ input
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
