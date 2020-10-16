module Model.Attribute exposing (..)

import Json.Decode as D
import Json.Decode.Pipeline exposing (required)
import Json.Encode as E
import Model.File
import Model.Peer
import Model.Sort exposing (SortDirection(..))
import Model.Torrent



{- attribute abstraction. Map an Attribute into TorrentAttribute or PeerAttribute etc -}
{- XXX: Sort and SortDirection probably don't belong here -}


type Sort
    = SortBy Attribute SortDirection



-- Instead of splitting attributes up between torrent/file/peer
-- maybe this should just be one large definitive list.
-- Then we wouldn't have three DonePercent..


type Attribute
    = TorrentAttribute Model.Torrent.Attribute
    | FileAttribute Model.File.Attribute
    | PeerAttribute Model.Peer.Attribute



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

            FileAttribute _ ->
                String.concat [ "file.", attributeToKey attribute ]

            PeerAttribute _ ->
                String.concat [ "peer.", attributeToKey attribute ]


encodeSortBy : Sort -> E.Value
encodeSortBy sortBy =
    case sortBy of
        SortBy column direction ->
            E.object
                [ ( "column", encode column )
                , ( "direction", Model.Sort.encodeSortDirection direction )
                ]



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
            keyToAttribute t attribute
                |> Maybe.map D.succeed
                |> Maybe.withDefault (D.fail <| "unknown key " ++ input)

        _ ->
            D.fail <| "attributes must be in format type.attribute"


sortByDecoder : D.Decoder Sort
sortByDecoder =
    D.succeed SortBy
        |> required "column" decoder
        |> required "direction" Model.Sort.sortDirectionDecoder



-- Abstraction Wrappers


keyToAttribute : String -> String -> Maybe Attribute
keyToAttribute type_ attribute =
    case type_ of
        "torrent" ->
            Model.Torrent.keyToAttribute attribute |> Maybe.map TorrentAttribute

        "file" ->
            Model.File.keyToAttribute attribute |> Maybe.map FileAttribute

        "peer" ->
            Model.Peer.keyToAttribute attribute |> Maybe.map PeerAttribute

        _ ->
            Nothing


attributeToKey : Attribute -> String
attributeToKey attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToKey torrentAttribute

        FileAttribute fileAttribute ->
            Model.File.attributeToKey fileAttribute

        PeerAttribute peerAttribute ->
            Model.Peer.attributeToKey peerAttribute


attributeToTableHeaderId : Attribute -> String
attributeToTableHeaderId attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderId torrentAttribute

        FileAttribute fileAttribute ->
            Model.File.attributeToTableHeaderId fileAttribute

        PeerAttribute peerAttribute ->
            Model.Peer.attributeToTableHeaderId peerAttribute


attributeToTableHeaderString : Attribute -> String
attributeToTableHeaderString attribute =
    case attribute of
        TorrentAttribute torrentAttribute ->
            Model.Torrent.attributeToTableHeaderString torrentAttribute

        FileAttribute fileAttribute ->
            Model.File.attributeToTableHeaderString fileAttribute

        PeerAttribute peerAttribute ->
            Model.Peer.attributeToTableHeaderString peerAttribute
