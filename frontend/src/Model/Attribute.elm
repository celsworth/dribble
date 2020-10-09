module Model.Attribute exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Model.Torrent



{- attribute abstraction. Map an Attribute into TorrentAttribute or PeerAttribute etc -}
{- XXX: Sort and SortDirection probably don't belong here -}


type SortDirection
    = Asc
    | Desc


type Sort
    = SortBy Attribute SortDirection


type Attribute
    = TorrentAttribute Model.Torrent.Attribute



--- JSON ENCODER


encodeList : List Attribute -> E.Value
encodeList attributes =
    E.list encode attributes


encode : Attribute -> E.Value
encode attribute =
    E.string <|
        case attribute of
            TorrentAttribute _ ->
                String.concat [ "torrent.", attributeToKey attribute ]


encodeSortBy : Maybe Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        Just (SortBy column direction) ->
            E.object
                [ ( "column", encode column )
                , ( "direction", encodeSortDirection direction )
                ]

        Nothing ->
            E.null


encodeSortDirection : SortDirection -> E.Value
encodeSortDirection direction =
    case direction of
        Asc ->
            E.string "asc"

        Desc ->
            E.string "desc"



--- JSON DECODERS


listDecoder : D.Decoder (List Attribute)
listDecoder =
    D.list decoder


decoder : D.Decoder Attribute
decoder =
    D.string |> D.andThen attributeSplitterDecoder


attributeSplitterDecoder : String -> D.Decoder Attribute
attributeSplitterDecoder input =
    case String.split "." input of
        [ t, attribute ] ->
            case t of
                "torrent" ->
                    Model.Torrent.keyToAttribute attribute
                        |> Maybe.map (D.succeed << TorrentAttribute)
                        |> Maybe.withDefault (D.fail <| "unknown torrent key " ++ attribute)

                _ ->
                    D.fail <| "unknown attribute type " ++ t

        _ ->
            D.fail <| "attributes must be in format type.attribute"


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" decoder
        |> required "direction" sortDirectionDecoder


sortDirectionDecoder : D.Decoder SortDirection
sortDirectionDecoder =
    D.string
        |> D.andThen
            (\input ->
                case input of
                    "asc" ->
                        D.succeed Asc

                    "desc" ->
                        D.succeed Desc

                    _ ->
                        D.fail <| "unknown direction " ++ input
            )



-- Abstraction Wrappers


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToKey torrentAttribute


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderId torrentAttribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderString torrentAttribute


textAlignment : Attribute -> Maybe String
textAlignment attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeTextAlignment torrentAttribute
