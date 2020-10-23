module Model.Peer exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline as Pipeline exposing (custom, required)
import Json.Encode as E
import Model.Sort exposing (SortDirection(..))


type Sort
    = SortBy Attribute SortDirection


type Attribute
    = Address
    | ClientVersion
    | CompletedPercent


type alias Peer =
    { host : String
    , clientVersion : String
    , completedPercent : Int
    }



-- JSON ENCODING


encodeAttribute : Attribute -> E.Value
encodeAttribute attribute =
    E.string <| attributeToKey attribute


encodeSortBy : Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        SortBy column direction ->
            E.object
                [ ( "column", encodeAttribute column )
                , ( "direction", Model.Sort.encodeSortDirection direction )
                ]



-- JSON DECODER


listDecoder : D.Decoder (List Peer)
listDecoder =
    D.list decoder


decoder : D.Decoder Peer
decoder =
    -- this order MUST match Model/Rtorrent.elm #getPeerFields
    --
    -- this gets fed to internalDecoder (below) which populates a Peer
    D.succeed internalDecoder
        -- host
        |> custom (D.index 0 D.string)
        -- clientVersion
        |> custom (D.index 1 D.string)
        -- completedPercent
        |> custom (D.index 2 D.int)
        |> Pipeline.resolve


internalDecoder : String -> String -> Int -> D.Decoder Peer
internalDecoder ip clientVersion completedPercent =
    D.succeed <|
        Peer
            ip
            clientVersion
            completedPercent


attributeDecoder : D.Decoder Attribute
attributeDecoder =
    D.string
        |> D.andThen
            (\input ->
                keyToAttribute input
                    |> Maybe.map D.succeed
                    |> Maybe.withDefault (D.fail <| "unknown key ")
            )


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" attributeDecoder
        |> required "direction" Model.Sort.sortDirectionDecoder



-- ATTRIBUTE ACCCESSORS ETC


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        Address ->
            "address"

        ClientVersion ->
            "clientVersion"

        CompletedPercent ->
            "completedPercent"


keyToAttribute : String -> Maybe Attribute
keyToAttribute str =
    case str of
        "address" ->
            Just Address

        "clientVersion" ->
            Just ClientVersion

        "completedPercent" ->
            Just CompletedPercent

        _ ->
            Nothing


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    "th-peerAttribute-" ++ attributeToKey attribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        _ ->
            attributeToString attribute


attributeToString : Attribute -> String
attributeToString attribute =
    case attribute of
        Address ->
            "Address"

        ClientVersion ->
            "Client"

        CompletedPercent ->
            "Completed"
