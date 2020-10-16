module Model.File exposing (..)

import Dict exposing (Dict)
import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom)
import Model.Sort exposing (SortDirection(..))


type Sort
    = SortBy Attribute SortDirection


type Attribute
    = Path
    | Size
    | DonePercent


type alias File =
    { path : String
    , size : Int

    -- custom local vars, not from JSON
    , donePercent : Float
    }


type alias FilesByKey =
    Dict String File



-- JSON DECODER


listDecoder : D.Decoder (List File)
listDecoder =
    D.list decoder


decoder : D.Decoder File
decoder =
    -- this order MUST match Model/Rtorrent.elm #getFileFields
    --
    -- this gets fed to internalDecoder (below) which populates a File
    D.succeed internalDecoder
        -- path
        |> custom (D.index 0 D.string)
        -- size
        |> custom (D.index 1 D.int)
        -- sizeChunks
        |> custom (D.index 2 D.int)
        -- completedChunks
        |> custom (D.index 3 D.int)
        -- priority
        |> custom (D.index 4 D.int)
        |> Pipeline.resolve


internalDecoder : String -> Int -> Int -> Int -> Int -> D.Decoder File
internalDecoder path size sizeChunks completedChunks priority =
    let
        donePercent =
            (toFloat completedChunks / toFloat sizeChunks) * 100.0
    in
    D.succeed <|
        File
            path
            size
            donePercent



-- ATTRIBUTE ACCCESSORS ETC


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        Path ->
            "path"

        Size ->
            "size"

        DonePercent ->
            "donePercent"


keyToAttribute : String -> Maybe Attribute
keyToAttribute str =
    case str of
        "path" ->
            Just Path

        "size" ->
            Just Size

        "donePercent" ->
            Just DonePercent

        _ ->
            Nothing


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    "th-fileAttribute-" ++ attributeToKey attribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        _ ->
            attributeToString attribute


attributeToString : Attribute -> String
attributeToString attribute =
    case attribute of
        Path ->
            "Path"

        Size ->
            "Size"

        DonePercent ->
            "Done"
